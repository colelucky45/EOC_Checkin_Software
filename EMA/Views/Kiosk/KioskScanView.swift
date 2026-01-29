//
//  KioskScanView.swift
//  EMACheckIn
//
//  Created by Cole Lucky on 12/11/25.
//

import SwiftUI

struct KioskScanView: View {

    @ObservedObject private var viewModel: KioskScanViewModel

    // MARK: - Init

    init(viewModel: KioskScanViewModel) {
        self.viewModel = viewModel
    }

    // MARK: - Body

    var body: some View {
        ZStack {

            // MARK: - QR Scanner Layer
            KioskQRScannerView(
                onScan: { token in
                    Task {
                        await viewModel.handleScan(qrToken: token)
                    }
                },
                isScanningEnabled: !viewModel.isProcessing
            )

            // MARK: - UI Overlay
            VStack(spacing: 24) {

                header

                Spacer()

                statusMessage
            }
            .padding()
        }
        .overlay {
            if viewModel.isProcessing {
                processingOverlay
            }
        }
        .brandedBackground()
    }

    // MARK: - Header

    private var header: some View {
        VStack(spacing: 8) {
            Text("EOC Check-In Kiosk")
                .font(.heading1)
                .foregroundColor(.white)

            Text("Scan QR Code")
                .font(.heading3)
                .foregroundColor(.white.opacity(0.85))
        }
        .padding(.top, 24)
    }

    // MARK: - Status Message

    @ViewBuilder
    private var statusMessage: some View {
        if let success = viewModel.successMessage {
            Text(success)
                .foregroundColor(.appSuccess)
                .font(.heading4)
                .multilineTextAlignment(.center)
                .padding()
                .background(.ultraThinMaterial)
                .cornerRadius(12)
        }

        if let error = viewModel.errorMessage {
            Text(error)
                .foregroundColor(.appError)
                .font(.heading4)
                .multilineTextAlignment(.center)
                .padding()
                .background(.ultraThinMaterial)
                .cornerRadius(12)
        }
    }

    // MARK: - Processing Overlay

    private var processingOverlay: some View {
        ProgressView("Processing…")
            .padding()
            .background(.ultraThinMaterial)
            .cornerRadius(12)
    }
}
