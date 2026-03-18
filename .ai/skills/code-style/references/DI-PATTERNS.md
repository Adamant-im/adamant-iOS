# Dependency Injection Patterns

Swinject DI patterns used in ADAMANT iOS.

## Service Registration

Services are registered in assembly files:

```swift
// In Adamant/App/DI/SomeAssembly.swift
final class SomeAssembly: Assembly {
    func assemble(container: Container) {
        // Register service
        container.register(MyServiceProtocol.self) { r in
            MyService(
                dependency1: r.resolve(Dependency1Protocol.self)!,
                dependency2: r.resolve(Dependency2Protocol.self)!
            )
        }.inObjectScope(.container) // Singleton
    }
}
```

## Service Resolution

Services are resolved through the container:

```swift
// In view controller or coordinator
final class MyViewController: UIViewController {
    // MARK: - Dependencies
    private let myService: MyServiceProtocol
    
    // MARK: - Init
    init(myService: MyServiceProtocol) {
        self.myService = myService
        super.init(nibName: nil, bundle: nil)
    }
}

// In factory or coordinator
let myService = container.resolve(MyServiceProtocol.self)!
let viewController = MyViewController(myService: myService)
```

## Protocol-Based Abstractions

All services have protocol definitions:

```swift
// In Adamant/ServiceProtocols/MyServiceProtocol.swift
protocol MyServiceProtocol {
    func performOperation() async throws -> Result
}

// In Adamant/Services/MyService.swift
final class MyService: MyServiceProtocol {
    // Implementation
}
```

## Scope Management

Use appropriate object scopes:

- `.container` — Singleton (shared instance)
- `.transient` — New instance each time (default)
- `.weak` — Weak reference to shared instance

```swift
// Singleton service
container.register(ApiService.self) { r in
    ApiServiceImpl()
}.inObjectScope(.container)

// Transient (new instance)
container.register(ViewModel.self) { r in
    ViewModelImpl()
}
```

## Circular Dependencies

Avoid circular dependencies. If needed, use property injection:

```swift
container.register(ServiceA.self) { r in
    let service = ServiceAImpl()
    service.serviceB = r.resolve(ServiceB.self)
    return service
}.inObjectScope(.container)
```

## Assembly Organization

- `AppAssembly.swift` — Main app assembly
- Module-specific assemblies for feature modules
- Each assembly focuses on related services
