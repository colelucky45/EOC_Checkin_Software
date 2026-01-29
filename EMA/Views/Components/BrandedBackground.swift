//
//  BrandedBackground.swift
//  EMACheckIn
//
//  Created by Cole Lucky on 12/11/25.
//

import SwiftUI

struct BrandedBackground: View {
    var body: some View {
        GeometryReader { geometry in
            Image("AppLogo")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: geometry.size.width * 0.6)
                .opacity(0.03) // Very subtle watermark
                .position(
                    x: geometry.size.width / 2,
                    y: geometry.size.height / 2
                )
        }
        .ignoresSafeArea()
    }
}

// MARK: - View Modifier Extension

extension View {
    /// Applies the branded background watermark
    func brandedBackground() -> some View {
        self.background(BrandedBackground())
    }
}

// MARK: - Preview

#Preview {
    VStack {
        Text("EOC Check-In")
            .font(.largeTitle)
            .fontWeight(.bold)

        Text("Personnel Tracking System")
            .font(.title2)
            .foregroundStyle(.secondary)
    }
    .brandedBackground()
}
