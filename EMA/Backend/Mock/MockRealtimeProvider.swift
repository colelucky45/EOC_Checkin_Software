//
//  MockRealtimeProvider.swift
//  EMACheckIn
//
//  Created by Cole Lucky on 12/11/25.
//

import Foundation

/// Mock realtime subscription
final class MockRealtimeSubscription: RealtimeSubscription, @unchecked Sendable {
    let id: String

    init() {
        self.id = UUID().uuidString
    }

    func unsubscribe() async {}
}

/// Mock realtime provider for testing
final class MockRealtimeProvider: RealtimeProviderProtocol, @unchecked Sendable {
    func subscribe<T: Decodable>(
        to table: String,
        filter: String?,
        onEvent: @escaping @Sendable (RealtimeEvent<T>) -> Void
    ) async -> RealtimeSubscription {
        MockRealtimeSubscription()
    }

    func unsubscribe(subscription: RealtimeSubscription) async {}

    func unsubscribeAll() async {}
}
