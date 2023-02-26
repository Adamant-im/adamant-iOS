# PopupKit

A library for presenting popups:
- notifications (on the top)
- alerts (in the middle)
- toasts (on the bottom)

This library uses its own UIWindow above main UIWindow to present popups.

## Usage

### Import Framework

```swift
import PopupKit
```

### Setup

You need to setup popup manager after your main window setup (window.makeKeyAndVisible()). Not before.

```swift
let popupManager = PopupManager()
popupManager.setup()
```

### Show popups

```swift
popupManager.showToastMessage("Some message")
```

etc.
