//
//  CacheService.swift
//  EMACheckIn
//
//  Created by Cole Lucky on 12/11/25.
//

import Foundation

/// Thread-safe JSON file cache for offline support.
/// Stores Local models in app's documents directory.
actor CacheService {

    // MARK: - Singleton

    static let shared = CacheService()

    private init() {}

    // MARK: - File Management

    private var cacheDirectory: URL {
        get throws {
            let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
            guard let documentsDirectory = paths.first else {
                throw AppError.unexpected("Documents directory not available")
            }
            let cacheDir = documentsDirectory.appendingPathComponent("Cache", isDirectory: true)

            // Create directory if it doesn't exist
            if !FileManager.default.fileExists(atPath: cacheDir.path) {
                try FileManager.default.createDirectory(at: cacheDir, withIntermediateDirectories: true)
            }

            return cacheDir
        }
    }

    private func fileURL(forKey key: String) throws -> URL {
        try cacheDirectory.appendingPathComponent("\(key).json")
    }

    // MARK: - Public API

    /// Saves an array of Codable items to cache.
    func save<T: Codable>(_ items: [T], forKey key: String) async throws {
        let url = try fileURL(forKey: key)
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601

        let data = try encoder.encode(items)
        try data.write(to: url, options: .atomic)

        Logger.log(
            "Cache saved",
            level: .debug,
            category: "CacheService",
            metadata: ["key": key, "count": items.count]
        )
    }

    /// Loads an array of Codable items from cache.
    /// Returns empty array if cache doesn't exist or is corrupt.
    func load<T: Codable>(forKey key: String) async throws -> [T] {
        let url = try fileURL(forKey: key)

        guard FileManager.default.fileExists(atPath: url.path) else {
            Logger.log(
                "Cache miss",
                level: .debug,
                category: "CacheService",
                metadata: ["key": key, "reason": "File not found"]
            )
            return []
        }

        do {
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601

            let items = try decoder.decode([T].self, from: data)

            Logger.log(
                "Cache hit",
                level: .debug,
                category: "CacheService",
                metadata: ["key": key, "count": items.count]
            )

            return items
        } catch {
            Logger.log(
                error: .unexpected("Cache decode failed: \(error.localizedDescription)"),
                level: .warning,
                category: "CacheService",
                context: "load(forKey: \(key))"
            )
            return []
        }
    }

    /// Clears a specific cache file.
    func clear(forKey key: String) async throws {
        let url = try fileURL(forKey: key)

        if FileManager.default.fileExists(atPath: url.path) {
            try FileManager.default.removeItem(at: url)
            Logger.log(
                "Cache cleared",
                level: .info,
                category: "CacheService",
                metadata: ["key": key]
            )
        }
    }

    /// Clears all cache files.
    func clearAll() async throws {
        let cacheDir = try cacheDirectory

        if FileManager.default.fileExists(atPath: cacheDir.path) {
            let contents = try FileManager.default.contentsOfDirectory(at: cacheDir, includingPropertiesForKeys: nil)
            for fileURL in contents {
                try FileManager.default.removeItem(at: fileURL)
            }
            Logger.log(
                "All caches cleared",
                level: .info,
                category: "CacheService",
                metadata: ["count": contents.count]
            )
        }
    }

    /// Returns cache statistics for debugging.
    func stats() async throws -> [String: Any] {
        let cacheDir = try cacheDirectory
        var stats: [String: Any] = [:]

        if FileManager.default.fileExists(atPath: cacheDir.path) {
            let contents = try FileManager.default.contentsOfDirectory(at: cacheDir, includingPropertiesForKeys: [.fileSizeKey])

            var totalSize: Int64 = 0
            var files: [String] = []

            for fileURL in contents {
                files.append(fileURL.lastPathComponent)
                if let resourceValues = try? fileURL.resourceValues(forKeys: [.fileSizeKey]),
                   let fileSize = resourceValues.fileSize {
                    totalSize += Int64(fileSize)
                }
            }

            stats["files"] = files
            stats["totalSizeBytes"] = totalSize
            stats["totalSizeKB"] = totalSize / 1024
        }

        return stats
    }
}

// MARK: - Cache Keys

extension CacheService {
    enum CacheKey {
        static let users = "cache_users"
        static let operations = "cache_operations"
        static let checkIns = "cache_checkins"
        static let mealLogs = "cache_meals"
        static let systemSettings = "cache_system_settings"
    }
}
