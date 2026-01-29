//
//  QRService.swift
//  EMA
//
//  Created by Cole Lucky on 12/11/25.
//

import Foundation
@preconcurrency import AVFoundation

/// Camera-backed QR scanning service.
@MainActor
final class QRService: NSObject, Sendable {

    // MARK: - Types

    enum QRServiceError: Error, LocalizedError, Sendable {
        case cameraUnavailable
        case permissionDenied
        case configurationFailed(String)

        var errorDescription: String? {
            switch self {
            case .cameraUnavailable:
                return "Camera is unavailable on this device."
            case .permissionDenied:
                return "Camera permission denied. Enable it in Settings to scan QR codes."
            case .configurationFailed(let reason):
                return "Failed to configure scanner: \(reason)"
            }
        }
    }

    // MARK: - Public Properties

    let session: AVCaptureSession = AVCaptureSession()
    var onScan: ((String) -> Void)?
    var preventDuplicateScans: Bool = true
    var duplicateScanCooldown: TimeInterval = 1.25

    // MARK: - Private State

    private let database: DatabaseProviderProtocol
    private var isConfigured: Bool = false
    private var isRunning: Bool = false
    private var lastScannedValue: String?
    private var lastScannedAt: Date?
    private let metadataQueue = DispatchQueue(label: "com.eoccheckin.qrservice.metadata")

    // MARK: - Init

    init(database: DatabaseProviderProtocol = BackendFactory.current.database) {
        self.database = database
        super.init()
    }

    // MARK: - QR Token Resolution

    func resolveToken(from rawScan: String) async -> Result<QrToken, AppError> {
        let trimmed = rawScan.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            return .failure(.validation("Invalid QR code format."))
        }

        do {
            let tokens: [QrToken] = try await database.fetchMany(
                from: "qr_tokens",
                filters: [.equals("token", trimmed)],
                order: nil,
                limit: 1
            )

            guard let token = tokens.first else {
                return .failure(.notFound("QR token not found."))
            }

            if token.isExpired {
                return .failure(.validation("QR code has expired. Please generate a new one."))
            }

            return .success(token)
        } catch {
            return .failure(mapToAppError(error))
        }
    }

    // MARK: - Responder QR Tokens

    func fetchOrCreateToken(
        for user: User,
        operationId: UUID?,
        forceRefresh: Bool = false
    ) async -> Result<QrToken, AppError> {
        guard user.isActive else {
            return .failure(.validation("User is inactive."))
        }

        do {
            if !forceRefresh,
               let existing = try await fetchLatestToken(for: user.id),
               !existing.isExpired,
               existing.operationId == operationId {
                return .success(existing)
            }

            let newToken = QrToken(
                id: UUID(),
                userId: user.id,
                token: UUID().uuidString,
                expiresAt: nil,
                createdAt: Date(),
                operationId: operationId
            )

            let created: QrToken = try await database.insert(newToken, into: "qr_tokens")
            return .success(created)
        } catch {
            return .failure(mapToAppError(error))
        }
    }

    // MARK: - Permission

    func requestCameraPermissionIfNeeded() async -> Bool {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            return true
        case .notDetermined:
            return await withCheckedContinuation { continuation in
                AVCaptureDevice.requestAccess(for: .video) { granted in
                    continuation.resume(returning: granted)
                }
            }
        default:
            return false
        }
    }

    // MARK: - Lifecycle

    func configureIfNeeded() async throws {
        guard !isConfigured else { return }

        let granted = await requestCameraPermissionIfNeeded()
        guard granted else { throw QRServiceError.permissionDenied }

        guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front) else {
            throw QRServiceError.cameraUnavailable
        }

        do {
            session.beginConfiguration()
            session.sessionPreset = .high

            let input = try AVCaptureDeviceInput(device: device)
            if session.canAddInput(input) {
                session.addInput(input)
            } else {
                throw QRServiceError.configurationFailed("Unable to add camera input.")
            }

            let metadataOutput = AVCaptureMetadataOutput()
            if session.canAddOutput(metadataOutput) {
                session.addOutput(metadataOutput)
            } else {
                throw QRServiceError.configurationFailed("Unable to add metadata output.")
            }

            metadataOutput.setMetadataObjectsDelegate(self, queue: metadataQueue)
            metadataOutput.metadataObjectTypes = [.qr]

            session.commitConfiguration()
            isConfigured = true
        } catch let error as QRServiceError {
            session.commitConfiguration()
            throw error
        } catch {
            session.commitConfiguration()
            throw QRServiceError.configurationFailed(error.localizedDescription)
        }
    }

    func start() async throws {
        if !isConfigured {
            try await configureIfNeeded()
        }

        guard !isRunning else { return }

        let session = self.session
        try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                session.startRunning()
                continuation.resume()
            }
        }

        isRunning = true
    }

    func stop() {
        guard isRunning else { return }

        let session = self.session
        DispatchQueue.global(qos: .userInitiated).async {
            session.stopRunning()
        }

        isRunning = false
    }

    func resetScanThrottle() {
        lastScannedValue = nil
        lastScannedAt = nil
    }

    // MARK: - Throttling

    private func shouldAcceptScan(value: String, now: Date) -> Bool {
        guard preventDuplicateScans else { return true }

        if let last = lastScannedValue, let lastAt = lastScannedAt {
            if last == value, now.timeIntervalSince(lastAt) < duplicateScanCooldown {
                return false
            }
        }
        return true
    }

    private func fetchLatestToken(for userId: UUID) async throws -> QrToken? {
        let tokens: [QrToken] = try await database.fetchMany(
            from: "qr_tokens",
            filters: [.equals("user_id", userId.uuidString)],
            order: .desc("created_at"),
            limit: 1
        )
        return tokens.first
    }

    // MARK: - Error Mapping

    private func mapToAppError(_ error: Error) -> AppError {
        if let appError = error as? AppError { return appError }

        if let networkError = error as? NetworkError {
            return networkError.toAppError()
        }

        if error is DecodingError {
            return .decoding("Failed to decode QR token response.")
        }

        let nsError = error as NSError
        if nsError.domain == NSURLErrorDomain {
            return NetworkError.from(error).toAppError()
        }

        return .unexpected(error.localizedDescription)
    }
}

// MARK: - AVCaptureMetadataOutputObjectsDelegate

extension QRService: AVCaptureMetadataOutputObjectsDelegate {

    nonisolated func metadataOutput(
        _ output: AVCaptureMetadataOutput,
        didOutput metadataObjects: [AVMetadataObject],
        from connection: AVCaptureConnection
    ) {
        guard let object = metadataObjects.first as? AVMetadataMachineReadableCodeObject,
              object.type == .qr,
              let value = object.stringValue,
              !value.isEmpty else {
            return
        }

        Task { @MainActor in
            let now = Date()
            guard shouldAcceptScan(value: value, now: now) else { return }

            lastScannedValue = value
            lastScannedAt = now

            onScan?(value)
        }
    }
}
