//
//  RealtimeProviderProtocol.swift
//  EMACheckIn
//
//  Created by Cole Lucky on 12/11/25.
//

import Foundation

/// Events emitted by realtime subscriptions
public enum RealtimeEvent<T: Decodable> {
    case insert(T)
    case update(T)
    case delete(T)

    public var record: T {
        switch self {
        case .insert(let r), .update(let r), .delete(let r):
            return r
        }
    }
}

/// Handle for managing a realtime subscription
public protocol RealtimeSubscription: Sendable {
    var id: String { get }
    func unsubscribe() async
}

/// Protocol for realtime subscriptions (WebSockets, Firebase listeners, AppSync, SignalR, etc.)
public protocol RealtimeProviderProtocol: Sendable {
    func subscribe<T: Decodable>(
        to table: String,
        filter: String?,
        onEvent: @escaping @Sendable (RealtimeEvent<T>) -> Void
    ) async -> RealtimeSubscription

    func unsubscribe(subscription: RealtimeSubscription) async
    func unsubscribeAll() async
}
