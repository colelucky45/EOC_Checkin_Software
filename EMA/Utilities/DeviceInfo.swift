//
//  DeviceInfo.swift
//  EMACheckIn
//
//  Created by Cole Lucky on 12/11/25.
//

import UIKit

/// Device information and capabilities.
enum DeviceInfo {

    // MARK: - Device Properties

    static var modelName: String {
        UIDevice.current.model
    }

    static var systemVersion: String {
        UIDevice.current.systemVersion
    }

    static var deviceName: String {
        UIDevice.current.name
    }

    static var deviceIdentifier: String {
        UIDevice.current.identifierForVendor?.uuidString ?? "unknown"
    }

    // MARK: - Capabilities

    static var hasCamera: Bool {
        UIImagePickerController.isSourceTypeAvailable(.camera)
    }

    @MainActor
    static var screenSize: CGSize {
        // Note: This should be called from a view context with access to a UIScreen instance
        // For now, we're using a deprecated API with MainActor isolation
        UIScreen.main.bounds.size
    }

    static var isIPad: Bool {
        UIDevice.current.userInterfaceIdiom == .pad
    }

    static var isIPhone: Bool {
        UIDevice.current.userInterfaceIdiom == .phone
    }
}
