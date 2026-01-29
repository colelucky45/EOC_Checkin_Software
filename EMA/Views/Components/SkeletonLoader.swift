//
//  SkeletonLoader.swift
//  EMACheckIn
//
//  Created by Cole Lucky on 12/11/25.
//

import SwiftUI

struct SkeletonLoader: View {
    @State private var isAnimating = false

    var body: some View {
        RoundedRectangle(cornerRadius: 8)
            .fill(Color.gray.opacity(0.3))
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .fill(
                        LinearGradient(
                            colors: [.clear, .white.opacity(0.4), .clear],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .offset(x: isAnimating ? 400 : -400)
            )
            .onAppear {
                withAnimation(.linear(duration: 1.5).repeatForever(autoreverses: false)) {
                    isAnimating = true
                }
            }
    }
}

/// Pre-built skeleton row for list items
struct SkeletonRow: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            SkeletonLoader()
                .frame(height: 20)

            SkeletonLoader()
                .frame(height: 16)
                .frame(width: 200)

            SkeletonLoader()
                .frame(height: 14)
                .frame(width: 150)
        }
        .padding()
    }
}

/// Skeleton for card-style content
struct SkeletonCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                SkeletonLoader()
                    .frame(width: 120, height: 20)
                Spacer()
                SkeletonLoader()
                    .frame(width: 60, height: 16)
            }

            // Body
            SkeletonLoader()
                .frame(height: 16)
            SkeletonLoader()
                .frame(height: 16)
                .frame(width: 250)

            // Footer
            HStack {
                SkeletonLoader()
                    .frame(width: 80, height: 14)
                Spacer()
                SkeletonLoader()
                    .frame(width: 100, height: 14)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.1), radius: 4, y: 2)
    }
}

// MARK: - Preview

#Preview("Skeleton Row") {
    List {
        ForEach(0..<5) { _ in
            SkeletonRow()
        }
    }
}

#Preview("Skeleton Card") {
    ScrollView {
        VStack(spacing: 16) {
            ForEach(0..<3) { _ in
                SkeletonCard()
            }
        }
        .padding()
    }
}
