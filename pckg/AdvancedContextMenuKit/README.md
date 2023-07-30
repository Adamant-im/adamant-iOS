# AdvancedContextMenuKit

A library for presenting context menu

## Usage

### Import Framework

```swift
import AdvancedContextMenuKit
```

### Setup

```swift
private lazy var contextMenu = AdvancedContextMenuManager(delegate: self)
contextMenu.setup(for: someView)
```

### Show programmatically menu

```swift
contextMenu.presentMenu(for: someView, with: menu)
```

etc.
