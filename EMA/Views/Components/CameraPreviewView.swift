//
//  CameraPreviewView.swift
//  EMACheckIn
//
//  Created by Cole Lucky on 12/12/25.
//

import SwiftUI
import AVFoundation

/// SwiftUI wrapper for displaying a live AVCaptureSession preview.
/// Contains NO scanning or business logic.
struct CameraPreviewView: UIViewRepresentable {

    let session: AVCaptureSession

    func makeUIView(context: Context) -> CameraPreviewUIView {
        let view = CameraPreviewUIView()
        view.session = session
        return view
    }

    func updateUIView(_ uiView: CameraPreviewUIView, context: Context) {
        uiView.session = session
    }
}

// MARK: - Custom UIView

/// Custom UIView that manages an AVCaptureVideoPreviewLayer.
/// Automatically resizes the preview layer when the view's bounds change.
final class CameraPreviewUIView: UIView {

    var session: AVCaptureSession? {
        get { previewLayer.session }
        set { previewLayer.session = newValue }
    }

    override class var layerClass: AnyClass {
        AVCaptureVideoPreviewLayer.self
    }

    private var previewLayer: AVCaptureVideoPreviewLayer {
        layer as! AVCaptureVideoPreviewLayer
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        previewLayer.videoGravity = .resizeAspectFill
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
