//
//  LoadingView.swift
//  EMACheckIn
//
//  Created by Cole Lucky on 12/11/25.
//

import SwiftUI

struct LoadingView: View {

    var body: some View {
        VStack(spacing: 16) {
            ProgressView()
                .progressViewStyle(.circular)

            Text("Loading…")
                .font(.footnote)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.backgroundPrimary.ignoresSafeArea())
        .brandedBackground()
    }
}
