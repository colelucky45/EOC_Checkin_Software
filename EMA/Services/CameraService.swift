//
//  CameraService.swift
//  EMACheckIn
//
//  Created by Cole Lucky on 12/11/25.
//

import Foundation
import AVFoundation
import SwiftUI
import Combine

@MainActor
final class CameraService: NSObject, ObservableObject {

    // MARK: - Published State

    @Published var session: AVCaptureSession = AVCaptureSession()
    @Published var authorizationStatus: AVAuthorizationStatus = .notDetermined
    @Published var isRunning: Bool = false
    @Published var lastError: Error?

    // MARK: - Private Properties

    private let sessionQueue = DispatchQueue(label: "camera.session.queue")
    private var videoDeviceInput: AVCaptureDeviceInput?

    // MARK: - Public API

    func requestCameraAccessIfNeeded() async {
        let status = AVCaptureDevice.authorizationStatus(for: .video)
        authorizationStatus = status

        switch status {
        case .authorized:
            return
        case .notDetermined:
            let granted = await AVCaptureDevice.requestAccess(for: .video)
            authorizationStatus = granted ? .authorized : .denied
        default:
            break
        }
    }

    func configureSession() {
        sessionQueue.async {
            guard self.authorizationStatus == .authorized else {
                return
            }

            self.session.beginConfiguration()
            self.session.sessionPreset = .high

            do {
                let device = AVCaptureDevice.default(.builtInWideAngleCamera,
                                                    for: .video,
                                                    position: .back)

                guard let camera = device else {
                    throw CameraError.cameraUnavailable
                }

                let input = try AVCaptureDeviceInput(device: camera)

                if self.session.canAddInput(input) {
                    self.session.addInput(input)
                    self.videoDeviceInput = input
                } else {
                    throw CameraError.cannotAddInput
                }

                self.session.commitConfiguration()
            } catch {
                self.session.commitConfiguration()
                DispatchQueue.main.async {
                    self.lastError = error
                }
            }
        }
    }

    func startSession() {
        sessionQueue.async {
            guard !self.session.isRunning else { return }
            self.session.startRunning()
            DispatchQueue.main.async {
                self.isRunning = true
            }
        }
    }

    func stopSession() {
        sessionQueue.async {
            guard self.session.isRunning else { return }
            self.session.stopRunning()
            DispatchQueue.main.async {
                self.isRunning = false
            }
        }
    }
}

// MARK: - Camera Errors

enum CameraError: LocalizedError {
    case cameraUnavailable
    case cannotAddInput

    var errorDescription: String? {
        switch self {
        case .cameraUnavailable:
            return "Camera is not available on this device."
        case .cannotAddInput:
            return "Unable to configure camera input."
        }
    }
}
