//
//  QRCodeView.swift
//  EMACheckIn
//
//  Created by Cole Lucky on 12/11/25.
//

import SwiftUI
import CoreImage
import CoreImage.CIFilterBuiltins

/// Reusable QR code display component.
struct QRCodeView: View {

    let value: String
    var size: CGFloat = 200

    private let context = CIContext()
    private let filter = CIFilter.qrCodeGenerator()

    var body: some View {
        if let image = generateQRCode() {
            image
                .interpolation(.none)
                .resizable()
                .scaledToFit()
                .frame(width: size, height: size)
        } else {
            Image(systemName: "qrcode")
                .resizable()
                .scaledToFit()
                .frame(width: size, height: size)
                .foregroundColor(.gray)
        }
    }

    private func generateQRCode() -> Image? {
        let data = Data(value.utf8)
        filter.message = data

        guard let outputImage = filter.outputImage else { return nil }
        let scaled = outputImage.transformed(by: CGAffineTransform(scaleX: 10, y: 10))

        guard let cgImage = context.createCGImage(scaled, from: scaled.extent) else { return nil }
        let uiImage = UIImage(cgImage: cgImage)
        return Image(uiImage: uiImage)
    }
}
