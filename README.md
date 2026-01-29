# EMA Check-In System

A SwiftUI iOS application for tracking personnel check-ins, visitor management, and meal service during emergency operations center (EOC) activations.

## Overview

This application was built to solve real operational needs for tracking:
- **Employee and visitor activities** on-site
- **EOC activation attendance** with check-in/check-out logging
- **Meal service tracking** for reimbursement and auditing
- **Overnight stays** during extended operations

The system supports three user roles:
- **Admin**: Full access to operations management, personnel roster, check-in logs, and meal tracking
- **Responder**: Personal QR code for check-in, history view, and profile management
- **Kiosk**: Dedicated terminal mode for check-in stations

## Features

### Check-In Management
- QR code-based check-in for fast processing
- Manual check-in option for admins
- Real-time active check-in tracking
- Automatic overnight detection

### Operations Tracking
- Create and manage operations/events
- Blue Sky (normal) and Gray Sky (activation) modes
- Visibility controls for operation availability
- Historical operation records

### Meal Service
- Track breakfast, lunch, and dinner service
- Per-operation meal logging
- Audit-ready reporting

### Personnel Management
- Role-based access control
- Active/inactive user status
- Profile self-service for responders

## Architecture

This project uses a **clean, protocol-based architecture** that separates concerns and enables easy backend swapping:

```
Views → ViewModels → Services → Repositories → BackendProtocol
```

### Key Patterns

- **MVVM**: Views are driven by observable ViewModels
- **Repository Pattern**: Data access abstracted behind repository interfaces
- **Protocol-Oriented Backend**: All backend operations defined by protocols
- **Dependency Injection**: Components receive dependencies through initializers

### Backend Abstraction

The app is **backend-agnostic**. All database, authentication, and real-time operations go through protocol abstractions:

- `AuthProviderProtocol` - Authentication (sign in, sign up, sessions)
- `DatabaseProviderProtocol` - CRUD operations
- `RealtimeProviderProtocol` - Live subscriptions
- `RemoteLoggerProtocol` - Error logging

This means you can implement your own backend using:
- **Firebase** (Firestore + Auth)
- **AWS** (DynamoDB + Cognito)
- **Azure** (Cosmos DB + AD)
- **Custom REST API**

See BACKEND_IMPLEMENTATION_GUIDE.md for implementation details.

## Project Structure

```
EMA/
├── App/                    # App entry, session management, routing
├── Backend/Mock/           # Mock backend for testing/previews
├── Config/                 # Configuration files
├── Core/                   # Logging, error handling
├── DesignSystem/           # Colors, typography, spacing tokens
├── Models/                 # Data models (API and Local)
├── Protocols/              # Protocol definitions
│   └── Backend/            # Backend abstraction protocols
├── Repositories/           # Data access layer
├── Resources/              # Assets, localization
├── Services/               # Business logic
├── Utilities/              # Helpers and extensions
├── ViewModels/             # Presentation logic
│   ├── Admin/
│   ├── Auth/
│   ├── Kiosk/
│   └── Responder/
└── Views/                  # SwiftUI views
    ├── Admin/
    ├── Auth/
    ├── Components/
    ├── Kiosk/
    └── Responder/
```

## Getting Started

### Prerequisites

- Xcode 15+
- iOS 17+
- Your own backend implementation (see guide)

### Setup

1. Clone the repository
2. Open `EMA.xcodeproj` in Xcode
3. Implement your backend (see BACKEND_IMPLEMENTATION_GUIDE.md)
4. Copy `BackendConfig.plist.example` to `BackendConfig.plist` and add your credentials
5. Update `BackendFactory.swift` to use your backend
6. Build and run

### Running with Mock Backend

The app includes a `MockBackend` for development and SwiftUI previews. By default, `BackendFactory.current` is set to `MockBackend.shared`.

## Database Schema

| Table | Purpose |
|-------|---------|
| `users` | User profiles and roles |
| `operations` | Events/activations being tracked |
| `checkin_log` | Check-in/out records |
| `meals_log` | Meal service records |
| `qr_tokens` | QR codes for check-in |
| `kiosk_settings` | Terminal configuration |
| `system_settings` | Global app settings |
| `error_logs` | Remote error logging |

## Technologies

- **SwiftUI** - Modern declarative UI
- **Swift Concurrency** - async/await, actors
- **AVFoundation** - QR code scanning
- **OSLog** - Structured logging

## Author

Cole Lucky

## License

This project is available for reference and educational purposes.
