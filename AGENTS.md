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

## Product Context and Values

ADAMANT is a decentralized, anonymous, community-driven messenger and wallet ecosystem.

This repository is a native iOS client application, so agent decisions must:

- Keep account custody fully on user side
- Keep user tracking and data collection at zero by default
- Keep node and service choices distributed and user-configurable
- Keep the app functional under node outages, censorship pressure, and partial network failures
- Maintain App Store compliance while preserving privacy and decentralization principles

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

## Agent Skills

This repository uses [Agent Skills](https://agentskills.io) for modular expertise. Skills are located in `.ai/skills/` directory.

Available skills:

- **[ios-architecture](.ai/skills/ios-architecture/)** — App architecture, modules, runtime flow, system map
- **[github-workflow](.ai/skills/github-workflow/)** — Issue/PR conventions, labels, org governance
- **[testing-validation](.ai/skills/testing-validation/)** — Testing requirements and validation procedures
- **[code-style](.ai/skills/code-style/)** — iOS/Swift rules, DI patterns, code quality standards
- **[documentation](.ai/skills/documentation/)** — Writing style, markdown conventions, sources of truth

AI agents should activate relevant skills based on the task at hand.
