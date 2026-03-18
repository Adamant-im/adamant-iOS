# Swift Rules

Detailed Swift conventions for ADAMANT iOS.

## Optionals

- Use optional binding or guard statements instead of force unwrapping
- Prefer `if let` for single optional unwrapping
- Prefer `guard let` when early return is needed

```swift
// Good
guard let value = optionalValue else { return }

// Good
if let value = optionalValue {
    // use value
}

// Avoid
let value = optionalValue!
```

## Error Handling

- Use proper error handling; avoid generic catch-all error handlers
- Provide meaningful error messages
- Don't silently swallow errors

```swift
// Good
do {
    try riskyOperation()
} catch let error as SpecificError {
    log.error("Operation failed: \(error.localizedDescription)")
    // Handle specific error
} catch {
    log.error("Unexpected error: \(error)")
    // Handle general error
}

// Avoid
do {
    try riskyOperation()
} catch {
    // Silent failure
}
```

## Threading

- Use `@MainActor` for UI updates
- Use `DispatchQueue.main.async` when needed
- Be explicit about threading requirements

```swift
// Good
@MainActor
func updateUI() {
    label.text = "Updated"
}

// Good
DispatchQueue.main.async {
    self.updateUI()
}
```

## Memory Management

- Use `[weak self]` in closures when appropriate
- Avoid retain cycles in delegates (use `weak` references)
- Be mindful of memory warnings

```swift
// Good
service.fetchData { [weak self] result in
    guard let self = self else { return }
    // use self safely
}
```

## Naming Conventions

- Use clear, descriptive names
- Avoid unnecessary abbreviations
- Follow Swift API Design Guidelines

```swift
// Good
func fetchUserProfile(for userId: String)
var isAuthenticated: Bool

// Avoid
func fetUsrProf(for id: String)
var authd: Bool
```

## Extensions

- Use extensions to organize code by protocol conformance
- Group related functionality in extensions
- Add MARK comments for clarity

```swift
// MARK: - UITableViewDataSource
extension MyViewController: UITableViewDataSource {
    // table view data source methods
}

// MARK: - Private Methods
private extension MyViewController {
    // private helper methods
}
```
