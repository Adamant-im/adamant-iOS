---
name: ios-architecture
description: Expert knowledge of ADAMANT iOS app architecture, modules, runtime flow, and system organization. Use when exploring codebase structure, understanding dependencies, or planning architectural changes.
license: Apache-2.0
compatibility: ADAMANT iOS project, Swift 5.9+, UIKit, Swinject DI
metadata:
  project: adamant-ios
  domain: architecture
---

# iOS Architecture

Understanding ADAMANT iOS application architecture, module organization, and runtime flow.

## High-Level Architecture

The app is built with:

1. **App layer** — UIKit using MVVM and Coordinator patterns
2. **Dependency injection** — Swinject container (`Adamant/App/DI/*`)
3. **Service layer** — Domain logic through protocol-based abstractions (`Adamant/ServiceProtocols/*`, `Adamant/Services/*`)
4. **Modular features** — Feature modules in `Adamant/Modules/*` (Chat, Wallets, Settings, etc.)
5. **Local packages** — Shared functionality:
   - `CommonKit`: Core utilities, API clients, crypto, networking
   - `AdamantWalletsKit`: Multi-blockchain wallet abstractions and models
   - `BitcoinKit`: Bitcoin-family blockchain support
   - `FilesStorageKit`: File persistence and management
   - `FilesPickerKit`: File selection UI components
   - `PopupKit`: Popup and overlay UI components

## Runtime Flow and Ownership

- **App bootstrap and DI setup**: `Adamant/App/AppDelegate.swift`, `Adamant/App/DI/AppAssembly.swift`
- **Main navigation and tab bar**: `Adamant/App/AppCoordinator.swift`
- **Core data model**: `Adamant/Adamant.xcdatamodeld/`
- **Localization**: `Adamant/*.lproj/` directories for supported languages (en, ru, de, zh)

## Messaging and Transaction Pipeline

- **ADAMANT crypto and transaction signing**: `CommonKit/Sources/CommonKit/Adamant/`
- **Account lifecycle and authentication**: `Adamant/Services/AdamantAccountService.swift`
- **Chat message handling**: `Adamant/Modules/Chat/`, `Adamant/Services/DataProviders/`
- **Rich messages and attachments**: `Adamant/ServiceProtocols/ChatFileProtocol.swift`, `Adamant/Services/FilesNetworkManager/`
- **Transaction status tracking**: `Adamant/Modules/TransactionsStatusService/`

## Wallet Architecture

- **Multi-wallet service composition**: `Adamant/Modules/Wallets/WalletsService/`
- **Blockchain-specific implementations**: `Adamant/Modules/Wallets/{Adamant,Bitcoin,Ethereum,Dash,Doge,ERC20}/`
- **Wallet API services with node failover**: `*ApiService.swift` files in wallet modules
- **Wallet UI factories**: `*WalletFactory.swift` files in wallet modules
- **Shared wallet models and utilities**: `AdamantWalletsKit/Sources/AdamantWalletsKit/`
- **Wallet parameters** (nodes, fees, etc.) are shared across ADAMANT applications and sourced from: <https://github.com/Adamant-im/adamant-wallets>

## Node and Service Architecture

- **API service composition**: `Adamant/Services/ApiServiceCompose.swift`
- **Node health checks and failover**: implemented in `CommonKit/Sources/CommonKit/Services/ApiService/`
- **IPFS integration**: `Adamant/Services/FilesNetworkManager/IPFSApiService.swift`

## Persistence and Local Security

- **Core Data stack** for messages and transactions
- **Keychain storage** via `SecureStore` protocol: `CommonKit/Sources/CommonKit/Services/SecuredStore/`
- **Local file storage**: `FilesStorageKit`
- **Encrypted backup and restore flows**

## Notifications and Background

- **Push notifications**: `Adamant/Services/AdamantNotificationService.swift`, `Adamant/Services/AdamantPushNotificationsTokenService.swift`
- **Notification extensions**: `NotificationServiceExtension/`, `MessageNotificationContentExtension/`, `TransferNotificationContentExtension/`
- **Background fetch**: `Adamant/ServiceProtocols/BackgroundFetchService.swift`

## When to Use This Skill

Activate this skill when:

- Exploring codebase structure and module organization
- Understanding data flow between layers
- Planning architectural changes or refactoring
- Investigating where specific functionality lives
- Working with DI container registrations
- Understanding wallet or messaging pipeline

## See Also

- [System Map](references/SYSTEM-MAP.md) for detailed file locations
- [Module Details](references/MODULES.md) for deep dive into each module
