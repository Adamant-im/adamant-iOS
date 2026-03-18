# Module Deep Dive

Detailed breakdown of key modules and their responsibilities.

## Chat Module (`Adamant/Modules/Chat/`)

Handles all messaging functionality:

- Message composition and sending
- Message rendering and display
- Rich message types (text, transfers, reactions)
- File attachments and media
- Message encryption/decryption
- Chat list and conversation views

**Key files:**

- `ChatViewController.swift` — Main chat UI
- `ChatRouter.swift` — Chat navigation
- Message cell types for different message formats

## Wallets Module (`Adamant/Modules/Wallets/`)

Multi-blockchain wallet system:

- `WalletsService/` — Wallet service orchestration
- `Adamant/` — ADAMANT token wallet
- `Bitcoin/` — Bitcoin wallet
- `Ethereum/` — Ethereum and ERC20 tokens
- `Dash/`, `Doge/` — Bitcoin-family altcoins

**Each wallet module contains:**

- `*ApiService.swift` — Blockchain API with node failover
- `*WalletService.swift` — Wallet business logic
- `*WalletFactory.swift` — UI factory for wallet screens
- `*TransactionDetailsViewController.swift` — Transaction UI

## Account Module (`Adamant/Modules/Account/`)

User account management:

- Profile information
- Security settings
- QR code display
- Account export/backup

## Login Module (`Adamant/Modules/Login/`)

Authentication flows:

- Passphrase entry
- Biometric authentication
- Account creation
- Account import

## Settings Module (`Adamant/Modules/Settings/`)

App configuration:

- General settings
- Security options
- Node management
- Language selection
- Notification preferences

## TransactionsStatusService Module

Transaction status tracking:

- Multi-blockchain transaction monitoring
- Status updates and notifications
- Transaction confirmation tracking

## Data Providers (`Adamant/Services/DataProviders/`)

Core Data integration:

- `AccountsProvider.swift` — Account/contact management
- `TransfersProvider.swift` — Transaction history
- `ChatsProvider.swift` — Chat message persistence
- Background sync and updates

## API Services (`Adamant/Services/`)

Network layer:

- `ApiServiceCompose.swift` — API service composition
- `AdamantApiService.swift` — ADAMANT node communication
- Node health checks and automatic failover
- Request/response handling
