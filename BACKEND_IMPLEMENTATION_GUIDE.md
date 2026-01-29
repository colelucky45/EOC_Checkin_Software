# Backend Implementation Guide

This app uses a protocol-based architecture for backend services. To connect to your own backend (Firebase, AWS, Azure, custom REST API, etc.), implement the protocols in `EMA/Protocols/Backend/`.

## Architecture Overview

```
┌─────────────────────────────────────────────────────────────┐
│                      Your App                               │
├─────────────────────────────────────────────────────────────┤
│  Views → ViewModels → Services → Repositories               │
│                           ↓                                 │
│                   BackendFactory.current                    │
│                           ↓                                 │
│                   BackendProtocol                           │
│         ┌─────────────┼─────────────┐                       │
│         ↓             ↓             ↓                       │
│   AuthProvider  DatabaseProvider  RealtimeProvider          │
└─────────────────────────────────────────────────────────────┘
                          ↓
              ┌───────────────────────┐
              │   Your Backend        │
              │   - Firebase          │
              │   - AWS               │
              │   - Azure             │
              │   - Custom REST API   │
              └───────────────────────┘
```

## Required Protocols

### 1. AuthProviderProtocol

Handles user authentication.

```swift
protocol AuthProviderProtocol: Sendable {
    func signIn(email: String, password: String) async throws -> AuthSession
    func signUp(email: String, password: String) async throws -> SignUpResult
    func signOut() async throws
    func currentSession() async throws -> AuthSession?
    func refreshSession() async throws -> AuthSession
}
```

**Example: Firebase Auth**
```swift
final class FirebaseAuthProvider: AuthProviderProtocol {
    func signIn(email: String, password: String) async throws -> AuthSession {
        let result = try await Auth.auth().signIn(withEmail: email, password: password)
        let token = try await result.user.getIDToken()
        return AuthSession(
            userId: UUID(uuidString: result.user.uid) ?? UUID(),
            email: result.user.email,
            accessToken: token
        )
    }
    // ... other methods
}
```

### 2. DatabaseProviderProtocol

Handles CRUD operations on data tables.

```swift
protocol DatabaseProviderProtocol: Sendable {
    func fetchOne<T: Decodable>(from table: String, id: UUID) async throws -> T
    func fetchMany<T: Decodable>(from table: String, filters: [QueryFilter], order: QueryOrder?, limit: Int?) async throws -> [T]
    func insert<T: Encodable, R: Decodable>(_ record: T, into table: String) async throws -> R
    func update<T: Encodable, R: Decodable>(_ record: T, in table: String, id: UUID) async throws -> R
    func delete(from table: String, id: UUID) async throws
}
```

**Example: REST API**
```swift
final class RESTDatabaseProvider: DatabaseProviderProtocol {
    private let baseURL: URL

    func fetchMany<T: Decodable>(from table: String, filters: [QueryFilter], order: QueryOrder?, limit: Int?) async throws -> [T] {
        var url = baseURL.appendingPathComponent(table)
        // Add query parameters for filters, order, limit
        let (data, _) = try await URLSession.shared.data(from: url)
        return try JSONDecoder().decode([T].self, from: data)
    }
    // ... other methods
}
```

### 3. RealtimeProviderProtocol

Handles live subscriptions to data changes.

```swift
protocol RealtimeProviderProtocol: Sendable {
    func subscribe<T: Decodable>(to table: String, filter: String?, onEvent: @escaping (RealtimeEvent<T>) -> Void) async -> RealtimeSubscription
    func unsubscribe(subscription: RealtimeSubscription) async
    func unsubscribeAll() async
}
```

**Example: WebSocket**
```swift
final class WebSocketRealtimeProvider: RealtimeProviderProtocol {
    private var socket: URLSessionWebSocketTask?

    func subscribe<T: Decodable>(to table: String, filter: String?, onEvent: @escaping (RealtimeEvent<T>) -> Void) async -> RealtimeSubscription {
        // Connect to WebSocket and listen for messages
        // Parse messages and call onEvent with .insert/.update/.delete
    }
}
```

### 4. RemoteLoggerProtocol

Handles remote error logging.

```swift
protocol RemoteLoggerProtocol: Sendable {
    func logError(severity: String, message: String, details: [String: Any]?) async
}
```

## Database Schema

This app expects the following tables:

| Table | Description | Key Fields |
|-------|-------------|------------|
| `users` | User profiles | id, email, first_name, last_name, role, is_active |
| `operations` | Events being tracked | id, name, category, is_active, is_visible |
| `checkin_log` | Check-in records | id, user_id, operation_id, checkin_time, checkout_time |
| `meals_log` | Meal records | id, user_id, operation_id, meal_type, served_at |
| `qr_tokens` | QR codes for check-in | id, user_id, token, expires_at, operation_id |
| `kiosk_settings` | Terminal config | id, terminal_id, kiosk_mode |
| `system_settings` | Global settings | id, mode |
| `error_logs` | Remote error logs | id, severity, message, details |

## Steps to Connect Your Backend

1. **Create your implementation folder**: `EMA/Backend/YourBackend/`

2. **Implement each protocol**:
   - `YourAuthProvider.swift`
   - `YourDatabaseProvider.swift`
   - `YourRealtimeProvider.swift`
   - `YourRemoteLogger.swift`

3. **Create your backend container**:
```swift
final class YourBackend: BackendProtocol {
    static let shared = YourBackend()

    let auth: AuthProviderProtocol = YourAuthProvider()
    let database: DatabaseProviderProtocol = YourDatabaseProvider()
    let realtime: RealtimeProviderProtocol = YourRealtimeProvider()
    let logger: RemoteLoggerProtocol = YourRemoteLogger()
}
```

4. **Update BackendFactory**:
```swift
enum BackendFactory {
    static var current: BackendProtocol = YourBackend.shared
}
```

5. **Add your credentials** to `BackendConfig.plist` (see `BackendConfig.plist.example`)

## Testing with MockBackend

The app includes a `MockBackend` for development and testing:

```swift
// For SwiftUI Previews
BackendFactory.current = MockBackend.shared

// In tests
let mockDatabase = MockDatabaseProvider()
let repo = UsersRepository(database: mockDatabase)
```
