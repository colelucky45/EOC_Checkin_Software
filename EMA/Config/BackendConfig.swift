//
//  EMACheckIn
//
//  Created by Cole Lucky on 12/11/25.
//  Configuration loader for backend credentials.
//  Create a BackendConfig.plist with your backend's API keys.
//

import Foundation

enum BackendConfig {

    private static let plistName = "BackendConfig"

    private static let config: [String: Any]? = {
        guard let url = Bundle.main.url(forResource: plistName, withExtension: "plist"),
              let data = try? Data(contentsOf: url),
              let dict = try? PropertyListSerialization.propertyList(
                    from: data,
                    options: [],
                    format: nil
              ) as? [String: Any]
        else {
            return nil
        }
        return dict
    }()

    /// Base URL for your backend API
    static var apiURL: String? {
        config?["API_URL"] as? String
    }

    /// API key or token for authentication
    static var apiKey: String? {
        config?["API_KEY"] as? String
    }

    /// Returns true if backend configuration is available
    static var isConfigured: Bool {
        config != nil && apiURL != nil && apiKey != nil
    }
}
