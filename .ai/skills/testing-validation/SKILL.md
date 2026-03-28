---
name: testing-validation
description: Testing and validation requirements for ADAMANT iOS. Use when writing tests, validating changes, or ensuring code quality before commits.
license: Apache-2.0
compatibility: Xcode, Swift, xcodebuild, SwiftLint
metadata:
  project: adamant-ios
  domain: quality
---

# Testing and Validation

Testing requirements and validation procedures for ADAMANT iOS.

## Testing Philosophy

For any non-trivial change, report exactly what was run.

## Baseline Validation

Run before considering any change complete:

- **Build the project** in Xcode without errors
- **Run SwiftLint**: `swiftlint` (or via Xcode build phase)
- **Run unit tests**: `Cmd+U` in Xcode or `xcodebuild test` command
- **Test on both iPhone and iPad simulators** when UI changes are involved
- **Test in both light and dark mode** when UI changes are involved

## Test Organization

- **Unit tests**: `AdamantTests/`
- **Disabled/legacy tests**: `AdamantTests/DisabledTests/`
- **Test stubs and mocks**: `AdamantTests/Stubs/`
- **Test extensions**: `AdamantTests/Extensions/`

## Test Requirements

When adding or modifying code:

- **Add unit tests** for new service logic, especially security-critical paths
- **Add integration tests** for wallet operations when touching blockchain code
- **Mock external dependencies** using stubs from `AdamantTests/Stubs/`
- **Test error paths and edge cases**, not just happy paths
- **Perform manual testing on real devices** when possible for UI changes
- **Test with slow network conditions and offline scenarios** for network-dependent features

## Build Validation

- **Standard build**: Build and run in Xcode
- **Release build**: Test with Release configuration to catch optimization-related issues
- **Pod dependencies**: Run `pod install` after Podfile changes
- **Package dependencies**: Ensure Swift Package Manager dependencies resolve correctly

## Edge Cases to Test

- Empty states
- Slow networks
- Large datasets
- Rapid user actions
- Network transitions (WiFi to cellular, offline to online)
- Memory warnings
- Background/foreground transitions

## Security-Critical Testing

When touching security-sensitive code:

- Verify no sensitive data is logged
- Test cryptographic operations with known test vectors
- Verify Keychain storage and retrieval
- Test error handling doesn't leak sensitive information
- Verify proper cleanup on logout/account deletion

## When to Use This Skill

Activate this skill when:

- Writing new tests
- Validating changes before commit
- Setting up CI/CD pipelines
- Investigating test failures
- Planning test coverage for new features

## See Also

- [Validation Scripts](scripts/validate-build.sh) for automated validation
