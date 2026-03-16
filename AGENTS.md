# ADAMANT iOS: AI Agent Operating Manual

This document defines how AI agents must work in this repository.

## Mission

ADAMANT iOS is the native iOS client for ADAMANT Messenger, available on the App Store and supporting iPhone, iPad, and Mac devices with Apple Silicon (M-series processors).

Agent output must optimize for:

1. Security and cryptographic correctness
2. User privacy and anonymity
3. Reliability and crash-free operation
4. iOS platform best practices and App Store compliance
5. User experience with minimal friction
6. Open-source maintainability and contributor clarity

If tradeoffs are required, preserve security and privacy first.

## Language Policy

- Developers may communicate with AI in any language
- All repository artifacts must be in English only
- Write all code, comments, docs, commit messages, and PR text in English

## Writing Style

- In bullet and numbered lists, do not add a trailing period when an item contains one sentence
- If an item contains two or more sentences, end every sentence with a period

## Markdown Lint Rules for AI-Generated Docs

- For every Markdown list, keep one blank line before the list and one blank line after the list
- Always keep a blank line between a heading and the list that follows it to satisfy MD032 (`blanks-around-lists`)
- Use fenced code blocks with matching opening and closing fences and include a language tag when applicable
- Follow other best practice markdown rules

## Product Context and Values

ADAMANT is a decentralized, anonymous, community-driven messenger and wallet ecosystem.

This repository is a native iOS client application, so agent decisions must:

- Keep account custody fully on user side
- Keep user tracking and data collection at zero by default
- Keep node and service choices distributed and user-configurable
- Keep the app functional under node outages, censorship pressure, and partial network failures
- Maintain App Store compliance while preserving privacy and decentralization principles

## Sources of Truth

Use these sources when implementing or reviewing changes:

- This repository: `README.md`, current code, and passing tests
- ADAMANT Node guidelines baseline: <https://github.com/Adamant-im/adamant/blob/dev/AGENTS.md>
- ADAMANT PWA guidelines: <https://github.com/Adamant-im/adamant-im/blob/dev/AGENTS.md>
- Org-wide issue/label governance: <https://github.com/Adamant-im/.github>
- Recommended issue title prefixes: <https://github.com/orgs/Adamant-im/discussions/5>
- Recommended labels for issues/discussions: <https://github.com/orgs/Adamant-im/discussions/1>
- ADAMANT docs: <https://docs.adamant.im>
- Node/API schema: <https://schema.adamant.im> and <https://github.com/Adamant-im/adamant-schema>
- AIPs: <https://aips.adamant.im> and <https://github.com/Adamant-im/AIPs>
- Wallet parameters and configuration: <https://github.com/Adamant-im/adamant-wallets>

If sources disagree:

1. Treat current repository behavior and passing tests as implementation truth
2. Do not silently ignore mismatches; document them and propose synchronized fixes

## Issue, Label, and PR Conventions

Follow the organization-wide conventions:

- Governance repository: <https://github.com/Adamant-im/.github>
- Prefix guidance: <https://github.com/orgs/Adamant-im/discussions/5>
- Label guidance: <https://github.com/orgs/Adamant-im/discussions/1>

### Issue workflow

1. Search existing issues first to avoid duplicates
2. Use org issue forms (Bug / Feature request / Task) from org defaults
3. Use a concise prefixed title
4. Apply labels from org label catalog (`labels.json`)
5. Link related issues and PRs explicitly

### Title prefixes

Use one or two prefixes maximum.

Common prefixes:

- `[Bug]` bugs, crashes, unexpected behavior
- `[Feat]` new functionality
- `[Enhancement]` improvements of existing features
- `[Refactor]` refactoring without intended behavior changes
- `[Docs]` documentation updates
- `[Test]` test additions or improvements
- `[Chore]` routine maintenance (dependencies, CI/CD, tooling)

Project-specific prefixes:

- `[Task]` general task (including non-coding tasks)
- `[Composite]` multi-part task with sub-tasks
- `[UX/UI]` interface and user experience changes

Idea-level prefixes (usually better in Discussions than Issues):

- `[Proposal]`, `[Idea]`, `[Discussion]`

### Label policy

- `labels.json` in `Adamant-im/.github` is the source of truth for label names, casing, descriptions, and colors
- Keep label casing aligned with org rules:
  - default GitHub labels are lowercase (`bug`, `enhancement`, `documentation`, etc.)
  - custom labels are Capitalized (`Security`, `Privacy`, `UX/UI`, `Task`, `Composite task`, etc.)
- For most issues, apply a small but informative set:
  - one type/status label (`bug`, `enhancement`, `Task`, `Composite task`)
  - one or more domain labels (`iOS`, `Swift`, `Wallets`, `Messaging`, `Security`, `Privacy`, `Nodes`, etc.)
  - optional priority label (`High priority`) when needed
- Do not use legacy status labels for workflow tracking (`s/ ...`); project/Kanban state is managed in GitHub Projects

### PR conventions

- Use org PR template sections (`Description`, `Related issue`, `How to test`, `Checklist`, etc.)
- Reference issues with closing keywords where appropriate (`Closes #<id>`)
- Use Conventional Commits style for PR titles: `Type: Short summary` (for example: `Docs: Update AGENTS.md`)
- Do not use issue-style square-bracket prefixes in PR titles (`[Docs]`, `[Bug]`, etc. are for Issues)
- Keep PR title type aligned with issue intent (`Docs:`, `Fix:`, `Feat:`, `Refactor:`, `Test:`, `Chore:`)
- Follow <https://www.conventionalcommits.org>
- Include testing/verification steps and mention risk areas (security, privacy, protocol, storage)

## Architecture and Key Modules

High-level architecture:

1. App layer built with UIKit using MVVM and Coordinator patterns
2. Dependency injection via Swinject container (`Adamant/App/DI/*`)
3. Service layer provides domain logic through protocol-based abstractions (`Adamant/ServiceProtocols/*`, `Adamant/Services/*`)
4. Modular feature architecture in `Adamant/Modules/*` (Chat, Wallets, Settings, etc.)
5. Local packages provide shared functionality:
   - `CommonKit`: Core utilities, API clients, crypto, networking
   - `AdamantWalletsKit`: Multi-blockchain wallet abstractions and models
   - `BitcoinKit`: Bitcoin-family blockchain support
   - `FilesStorageKit`: File persistence and management
   - `FilesPickerKit`: File selection UI components
   - `PopupKit`: Popup and overlay UI components

Runtime flow and ownership:

- App bootstrap and DI setup: `Adamant/App/AppDelegate.swift`, `Adamant/App/DI/AppAssembly.swift`
- Main navigation and tab bar: `Adamant/App/AppCoordinator.swift`
- Core data model: `Adamant/Adamant.xcdatamodeld/`
- Localization: `Adamant/*.lproj/` directories for supported languages (en, ru, de, zh)

Messaging and transaction pipeline:

- ADAMANT crypto and transaction signing: `CommonKit/Sources/CommonKit/Adamant/`
- Account lifecycle and authentication: `Adamant/Services/AdamantAccountService.swift`
- Chat message handling: `Adamant/Modules/Chat/`, `Adamant/Services/DataProviders/`
- Rich messages and attachments: `Adamant/ServiceProtocols/ChatFileProtocol.swift`, `Adamant/Services/FilesNetworkManager/`
- Transaction status tracking: `Adamant/Modules/TransactionsStatusService/`

Wallet architecture:

- Multi-wallet service composition: `Adamant/Modules/Wallets/WalletsService/`
- Blockchain-specific implementations: `Adamant/Modules/Wallets/{Adamant,Bitcoin,Ethereum,Dash,Doge,ERC20}/`
- Wallet API services with node failover: `*ApiService.swift` files in wallet modules
- Wallet UI factories: `*WalletFactory.swift` files in wallet modules
- Shared wallet models and utilities: `AdamantWalletsKit/Sources/AdamantWalletsKit/`
- Wallet parameters (nodes, fees, etc.) are shared across ADAMANT applications and sourced from: <https://github.com/Adamant-im/adamant-wallets>

Node and service architecture:

- API service composition: `Adamant/Services/ApiServiceCompose.swift`
- Node health checks and failover: implemented in `CommonKit/Sources/CommonKit/Services/ApiService/`
- IPFS integration: `Adamant/Services/FilesNetworkManager/IPFSApiService.swift`

Persistence and local security:

- Core Data stack for messages and transactions
- Keychain storage via `SecureStore` protocol: `CommonKit/Sources/CommonKit/Services/SecuredStore/`
- Local file storage: `FilesStorageKit`
- Encrypted backup and restore flows

Notifications and background:

- Push notifications: `Adamant/Services/AdamantNotificationService.swift`, `Adamant/Services/AdamantPushNotificationsTokenService.swift`
- Notification extensions: `NotificationServiceExtension/`, `MessageNotificationContentExtension/`, `TransferNotificationContentExtension/`
- Background fetch: `Adamant/ServiceProtocols/BackgroundFetchService.swift`

## System Map (What You Are Editing)

- App bootstrap and DI: `Adamant/App/AppDelegate.swift`, `Adamant/App/DI/AppAssembly.swift`, `Adamant/App/DI/AppContainer.swift`
- Navigation and coordinators: `Adamant/App/AppCoordinator.swift`, module-specific coordinators
- Service protocols: `Adamant/ServiceProtocols/*`
- Service implementations: `Adamant/Services/*`
- Feature modules: `Adamant/Modules/{Chat,Wallets,Settings,Account,Login,etc.}/`
- Shared packages: `CommonKit/`, `AdamantWalletsKit/`, `BitcoinKit/`, `FilesStorageKit/`, `FilesPickerKit/`, `PopupKit/`
- Core Data model: `Adamant/Adamant.xcdatamodeld/`
- Extensions: `NotificationServiceExtension/`, `MessageNotificationContentExtension/`, `TransferNotificationContentExtension/`, `NotificationsShared/`
- Build configuration: `Adamant.xcodeproj/`, `Podfile`, `Package.swift` files
- Utilities and helpers: `Adamant/Helpers/`, `Adamant/Utilities/`
- Shared views: `Adamant/SharedViews/`
- Assets and resources: `Adamant/Assets/`, localization `.lproj/` directories

## iOS Platform and Swift Rules

- Target iOS 15.0+ as specified in `Podfile` and package manifests
- Use Swift 5.9+ language features as appropriate
- Follow UIKit patterns; this is not a SwiftUI project
- Respect iOS lifecycle events and state restoration
- Handle memory warnings and background transitions properly
- Use `@MainActor` or `DispatchQueue.main.async` for UI updates from background threads
- Avoid force unwrapping (`!`) except in truly safe scenarios; prefer optional binding or guard statements
- Use Swift's type safety and value semantics where appropriate

## Dependency Injection Rules

- All services must be registered in appropriate assembly files (`Adamant/App/DI/*`, module-specific assemblies)
- Use protocol-based abstractions defined in `Adamant/ServiceProtocols/`
- Follow Swinject container patterns already established in the codebase
- Prefer constructor injection over property injection
- Use `.inObjectScope(.container)` for singleton services
- Do not create service instances directly; resolve them through the DI container

## Non-Negotiable Security Rules

- Never weaken cryptographic primitives, key derivation, signature validation, or message encryption
- Never log passphrases, private keys, mnemonic seeds, decrypted payloads, or sensitive tokens
- Never add dynamic code execution or unsafe deserialization
- Keep all untrusted content sanitized before display
- Do not introduce insecure fallbacks for transport or authentication flows
- Minimize dependencies, especially cryptography/networking dependencies; prefer proven libraries already used in repo
- Store sensitive data only in Keychain via `SecureStore` protocol
- Never persist unencrypted passphrases or private keys to disk or UserDefaults
- Treat device as potentially compromised; assume jailbreak/debugging scenarios

## Privacy and Anonymity Rules

- Do not introduce analytics, telemetry, fingerprinting, or hidden third-party trackers
- Do not collect phone numbers, emails, contact lists, geolocation, or device identifiers unless explicitly required and clearly user-initiated
- Keep persisted data minimal and justified
- Respect user privacy settings and system permissions
- Do not share data with third parties without explicit user consent
- Maintain App Store privacy nutrition label accuracy

## Decentralization and Censorship-Resistance Rules

- Do not hardcode single points of failure for nodes or service endpoints
- Preserve and improve node failover and health-check behavior
- Keep self-hosting and custom endpoint configuration working
- Ensure mainnet/testnet modes remain functional and isolated by configuration
- Support operation over Tor and other privacy networks where applicable

## Reliability Rules

- Fail safely: no crashes on malformed data, node timeouts, or partial API failures
- Prefer graceful degradation and clear user-facing errors over silent failure
- Keep retry/backoff and offline behaviors predictable
- Handle network transitions (WiFi to cellular, offline to online) gracefully
- Changes in networking, transactions, or storage must include regression tests
- Use proper error handling; avoid generic catch-all error handlers that hide issues
- Test edge cases: empty states, slow networks, large datasets, rapid user actions

## UX Rules for Security-Critical Flows

- Keep onboarding fast, but do not hide irreversible risk
- Preserve clear passphrase responsibility warnings; never imply recoverability when none exists
- Keep transaction confirmations explicit and informative
- Avoid introducing friction that does not improve security or safety
- Provide clear feedback for all user actions
- Handle loading states and network delays with appropriate UI indicators
- Maintain accessibility support (VoiceOver, Dynamic Type, etc.)

## Protocol and Compatibility Rules

- Keep transaction bytes, signing behavior, and verification compatible with ADAMANT network expectations unless a coordinated protocol update is planned
- For protocol-impacting changes, align with AIPs and update related docs/spec references
- Maintain backward compatibility with existing user data and Core Data models
- Use Core Data migrations properly when schema changes are required
- Test migration paths from previous app versions

## Code Style and Quality Rules

- Follow existing code style and patterns in the repository
- SwiftLint is configured but many rules are disabled (see `.swiftlint.yml`); follow the enabled rules strictly
- SwiftFormat configuration exists (`.swiftformat`); use it for consistent formatting
- Prefer clarity over cleverness
- Write self-documenting code; add comments only when necessary to explain "why" not "what"
- Keep functions focused and reasonably sized
- Avoid massive view controllers; extract logic to services, view models, or coordinators
- Use extensions to organize code by protocol conformance or functionality
- Follow Swift naming conventions: clear, descriptive names without unnecessary abbreviations

## Testing and Validation Policy

For any non-trivial change, report exactly what was run.

### Baseline validation

- Build the project in Xcode without errors
- Run SwiftLint: `swiftlint` (or via Xcode build phase)
- Run unit tests: `Cmd+U` in Xcode or `xcodebuild test` command
- Test on both iPhone and iPad simulators when UI changes are involved
- Test in both light and dark mode when UI changes are involved

### Test organization

- Unit tests: `AdamantTests/`
- Disabled/legacy tests: `AdamantTests/DisabledTests/`
- Test stubs and mocks: `AdamantTests/Stubs/`
- Test extensions: `AdamantTests/Extensions/`

### Test requirements

- Add unit tests for new service logic, especially security-critical paths
- Add integration tests for wallet operations when touching blockchain code
- Mock external dependencies using stubs from `AdamantTests/Stubs/`
- Test error paths and edge cases, not just happy paths
- For UI changes, perform manual testing on real devices when possible
- Test with slow network conditions and offline scenarios for network-dependent features

### Build validation

- Standard build: Build and run in Xcode
- Release build: Test with Release configuration to catch optimization-related issues
- Pod dependencies: Run `pod install` after Podfile changes
- Package dependencies: Ensure Swift Package Manager dependencies resolve correctly

## Change Discipline

- Prefer focused patches with explicit rationale
- Preserve backward compatibility for user data and persisted state where possible
- When touching legacy code, improve locally without broad unrelated rewrites
- Add or update tests near the changed behavior
- Update localization strings when adding new user-facing text
- Update all supported languages or mark missing translations with English fallback

## Documentation Drift Policy

When behavior and docs diverge:

1. Document exact mismatch with file/path references
2. Propose synchronized updates in this repo and companion ADAMANT docs/spec repos when required
3. If cross-repo changes cannot be included immediately, open linked follow-up issues

## Done Criteria for Agents

A change is not complete until all conditions hold:

1. Security/privacy/decentralization priorities remain intact or improved
2. Relevant tests and validation commands were run (or explicit blocker is reported)
3. Documentation/config updates are included for behavioral changes
4. No sensitive data exposure was introduced
5. Code builds without errors or warnings
6. All modified files follow project code style
7. Localization is updated if user-facing strings changed
8. Core Data migrations are included if model changed
9. DI container registrations are updated if new services were added
