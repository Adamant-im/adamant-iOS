# System Map: What You Are Editing

Detailed map of file locations and responsibilities.

## App Bootstrap and Core

- `Adamant/App/AppDelegate.swift` — App lifecycle entry point
- `Adamant/App/DI/AppAssembly.swift` — Main DI assembly
- `Adamant/App/DI/AppContainer.swift` — DI container setup
- `Adamant/App/AppCoordinator.swift` — Main navigation coordinator

## Service Layer

- `Adamant/ServiceProtocols/*` — Service protocol definitions
- `Adamant/Services/*` — Service implementations
- Module-specific assemblies — Feature DI registration

## Feature Modules

- `Adamant/Modules/Chat/` — Chat and messaging
- `Adamant/Modules/Wallets/` — Multi-wallet functionality
- `Adamant/Modules/Settings/` — App settings
- `Adamant/Modules/Account/` — Account management
- `Adamant/Modules/Login/` — Authentication flows
- Navigation coordinators — Module-specific coordinators

## Shared Packages

- `CommonKit/` — Core utilities, API clients, crypto, networking
- `AdamantWalletsKit/` — Multi-blockchain wallet abstractions
- `BitcoinKit/` — Bitcoin-family blockchain support
- `FilesStorageKit/` — File persistence
- `FilesPickerKit/` — File selection UI
- `PopupKit/` — Popup and overlay UI

## Data Layer

- `Adamant/Adamant.xcdatamodeld/` — Core Data model

## Extensions

- `NotificationServiceExtension/` — Push notification handling
- `MessageNotificationContentExtension/` — Message notification UI
- `TransferNotificationContentExtension/` — Transfer notification UI
- `NotificationsShared/` — Shared notification code

## Configuration and Build

- `Adamant.xcodeproj/` — Xcode project
- `Podfile` — CocoaPods dependencies
- `Package.swift` files — Swift Package Manager configuration

## Utilities and Helpers

- `Adamant/Helpers/` — Helper utilities
- `Adamant/Utilities/` — Common utilities
- `Adamant/SharedViews/` — Reusable UI components

## Resources

- `Adamant/Assets/` — Images, colors, assets
- `Adamant/*.lproj/` — Localization (en, ru, de, zh)
