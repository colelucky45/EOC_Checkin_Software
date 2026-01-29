//
//  Alerts.swift
//  EMACheckIn
//
//  Created by Cole Lucky on 12/11/25.
//

import SwiftUI

/// Alert presentation utilities.
/// SwiftUI-compatible alert helpers.
struct AlertConfig {
    let title: String
    let message: String?
    let primaryButton: Alert.Button
    let secondaryButton: Alert.Button?

    static func error(_ error: AppError) -> AlertConfig {
        AlertConfig(
            title: "Error",
            message: error.userFacingMessage,
            primaryButton: .default(Text("OK")),
            secondaryButton: nil
        )
    }

    static func confirmation(
        title: String,
        message: String?,
        confirmTitle: String = "Confirm",
        onConfirm: @escaping () -> Void
    ) -> AlertConfig {
        AlertConfig(
            title: title,
            message: message,
            primaryButton: .destructive(Text(confirmTitle), action: onConfirm),
            secondaryButton: .cancel()
        )
    }

    static func info(title: String, message: String?) -> AlertConfig {
        AlertConfig(
            title: title,
            message: message,
            primaryButton: .default(Text("OK")),
            secondaryButton: nil
        )
    }

    var alert: Alert {
        if let secondaryButton = secondaryButton {
            return Alert(
                title: Text(title),
                message: message.map { Text($0) },
                primaryButton: primaryButton,
                secondaryButton: secondaryButton
            )
        } else {
            return Alert(
                title: Text(title),
                message: message.map { Text($0) },
                dismissButton: primaryButton
            )
        }
    }
}
