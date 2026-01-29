//
//  KioskScannerView.swift
//  EMACheckIn
//
//  Created by Cole Lucky on 12/12/25.
//

import SwiftUI

struct KioskQRScannerView: View {

    // MARK: - Dependencies

    @State private var qrService = QRService()

    /// Called when a QR code is successfully scanned.
    let onScan: (String) -> Void

    /// Whether scanning should be paused (e.g. while processing a scan).
    let isScanningEnabled: Bool

    // MARK: - Body

    var body: some View {
        ZStack {
            CameraPreviewView(session: qrService.session)
                .ignoresSafeArea()

            overlay
        }
        .onAppear {
            setupScanner()
        }
        .onDisappear {
            qrService.stop()
        }
        .onChange(of: isScanningEnabled) { enabled in
            handleScanningStateChange(enabled)
        }
    }

    // MARK: - Overlay UI

    private var overlay: some View {
        RoundedRectangle(cornerRadius: 16)
            .stroke(style: StrokeStyle(lineWidth: 3, dash: [12]))
            .foregroundColor(.white)
            .padding(32)
    }

    // MARK: - Scanner Wiring

    private func setupScanner() {
        qrService.onScan = { value in
            guard isScanningEnabled else { return }
            onScan(value)
        }

        Task {
            do {
                try await qrService.start()
            } catch {
                // Scanner failure is intentionally silent here.
                // Higher-level views decide how to handle errors.
            }
        }
    }

    private func handleScanningStateChange(_ enabled: Bool) {
        if enabled {
            Task {
                do {
                    try await qrService.start()
                } catch { }
            }
        } else {
            qrService.stop()
        }
    }
}
