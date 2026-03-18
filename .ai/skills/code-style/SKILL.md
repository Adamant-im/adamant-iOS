---
name: code-style
description: iOS platform rules, Swift conventions, dependency injection patterns, and code quality standards for ADAMANT iOS. Use when writing or reviewing code.
license: Apache-2.0
compatibility: Swift 5.9+, iOS 15.0+, UIKit, Swinject
metadata:
  project: adamant-ios
  domain: code-quality
---

# Code Style and Quality

Code style conventions, platform rules, and quality standards for ADAMANT iOS.

## iOS Platform and Swift Rules

- **Target iOS 15.0+** as specified in `Podfile` and package manifests
- **Use Swift 5.9+** language features as appropriate
- **Follow UIKit patterns**; this is not a SwiftUI project
- **Respect iOS lifecycle events** and state restoration
- **Handle memory warnings and background transitions** properly
- **Use `@MainActor`** or `DispatchQueue.main.async` for UI updates from background threads
- **Avoid force unwrapping (`!`)** except in truly safe scenarios; prefer optional binding or guard statements
- **Use Swift's type safety and value semantics** where appropriate

## Dependency Injection Rules

- **All services must be registered** in appropriate assembly files (`Adamant/App/DI/*`, module-specific assemblies)
- **Use protocol-based abstractions** defined in `Adamant/ServiceProtocols/`
- **Follow Swinject container patterns** already established in the codebase
- **Prefer constructor injection** over property injection
- **Use `.inObjectScope(.container)`** for singleton services
- **Do not create service instances directly**; resolve them through the DI container

## Code Style and Quality Rules

- **Follow existing code style and patterns** in the repository
- **SwiftLint is configured** but many rules are disabled (see `.swiftlint.yml`); follow the enabled rules strictly
- **SwiftFormat configuration exists** (`.swiftformat`); use it for consistent formatting
- **Prefer clarity over cleverness**
- **Write self-documenting code**; add comments only when necessary to explain "why" not "what"
- **Keep functions focused and reasonably sized**
- **Avoid massive view controllers**; extract logic to services, view models, or coordinators
- **Use extensions** to organize code by protocol conformance or functionality
- **Follow Swift naming conventions**: clear, descriptive names without unnecessary abbreviations

## Protocol and Compatibility Rules

- **Keep transaction bytes, signing behavior, and verification** compatible with ADAMANT network expectations unless a coordinated protocol update is planned
- **For protocol-impacting changes**, align with AIPs and update related docs/spec references
- **Maintain backward compatibility** with existing user data and Core Data models
- **Use Core Data migrations properly** when schema changes are required
- **Test migration paths** from previous app versions

## Change Discipline

- **Prefer focused patches** with explicit rationale
- **Preserve backward compatibility** for user data and persisted state where possible
- **When touching legacy code**, improve locally without broad unrelated rewrites
- **Add or update tests** near the changed behavior
- **Update localization strings** when adding new user-facing text
- **Update all supported languages** or mark missing translations with English fallback

## UX Rules for Security-Critical Flows

- **Keep onboarding fast**, but do not hide irreversible risk
- **Preserve clear passphrase responsibility warnings**; never imply recoverability when none exists
- **Keep transaction confirmations explicit and informative**
- **Avoid introducing friction** that does not improve security or safety
- **Provide clear feedback** for all user actions
- **Handle loading states and network delays** with appropriate UI indicators
- **Maintain accessibility support** (VoiceOver, Dynamic Type, etc.)

## When to Use This Skill

Activate this skill when:

- Writing new code
- Reviewing code for style compliance
- Refactoring existing code
- Setting up DI registrations
- Working with Core Data models
- Making UI changes

## See Also

- [Swift Rules](references/SWIFT-RULES.md) for detailed Swift conventions
- [DI Patterns](references/DI-PATTERNS.md) for dependency injection examples
