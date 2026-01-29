//
//  RealtimeManager.swift
//  EMACheckIn
//
//  Created by Cole Lucky on 12/11/25.
//

import Foundation

@MainActor
final class RealtimeManager {
    static let shared = RealtimeManager()

    private let realtime: RealtimeProviderProtocol
    private var subscriptions: [String: RealtimeSubscription] = [:]

    private init(realtime: RealtimeProviderProtocol = BackendFactory.current.realtime) {
        self.realtime = realtime
    }

    // MARK: - Subscribe to Table Changes

    /// Subscribe to changes on a specific table
    func subscribe<T: Decodable>(
        to table: String,
        filter: String? = nil,
        onInsert: ((T) -> Void)? = nil,
        onUpdate: ((T) -> Void)? = nil,
        onDelete: ((T) -> Void)? = nil
    ) async -> String {
        let channelId = "\(table)-\(UUID().uuidString)"

        let subscription = await realtime.subscribe(to: table, filter: filter) { (event: RealtimeEvent<T>) in
            Task { @MainActor in
                switch event {
                case .insert(let record):
                    onInsert?(record)
                case .update(let record):
                    onUpdate?(record)
                case .delete(let record):
                    onDelete?(record)
                }
            }
        }

        subscriptions[channelId] = subscription

        Logger.log(
            "Realtime subscription started",
            level: .info,
            category: "RealtimeManager",
            metadata: ["table": table, "channelId": channelId]
        )

        return channelId
    }

    // MARK: - Unsubscribe

    func unsubscribe(channelId: String) async {
        if let subscription = subscriptions[channelId] {
            await realtime.unsubscribe(subscription: subscription)
            subscriptions.removeValue(forKey: channelId)

            Logger.log(
                "Realtime subscription stopped",
                level: .info,
                category: "RealtimeManager",
                metadata: ["channelId": channelId]
            )
        }
    }

    func unsubscribeAll() async {
        await realtime.unsubscribeAll()
        subscriptions.removeAll()
    }
}
