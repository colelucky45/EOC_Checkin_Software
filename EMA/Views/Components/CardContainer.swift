//
//  CardContainer.swift
//  EMACheckIn
//
//  Created by Cole Lucky on 12/11/25.
//

import SwiftUI

/// Card container with consistent padding and shadow.
struct CardContainer<Content: View>: View {

    let content: () -> Content

    var body: some View {
        content()
            .padding(AppTheme.shared.cardPadding)
            .background(Color.backgroundSecondary)
            .cornerRadius(AppTheme.shared.cardCornerRadius)
            .shadow(.md)
    }
}
