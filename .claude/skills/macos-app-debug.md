---
name: Shade App Debug & Log Workflow
description: Autonomous workflow for debugging the Shade macOS SwiftUI app in this repository. Use when building, running, and troubleshooting Shade to verify behavior through console logs. Covers OSLog setup patterns used in ShadeApp/, xcodebuild automation via scripts/, background process management, and log streaming with subsystem "com.brishin.Shade".
allowed-tools: [Read, Write, Edit, Grep, Glob]
---

# Workflow

### 1. Add OSLog Loggers

```swift
import OSLog

// Use emoji prefixes: 🚀 lifecycle, 🔐 permissions, 🪟 windows, ⚙️ config
private let logger = Logger(subsystem: "com.brishin.Shade", category: "CategoryName")
```

### 2. Log State Transitions

```swift
logger.info("🚀 App initializing")
logger.info("🔐 Permission status: \(granted ? "✅ GRANTED" : "❌ DENIED")")
logger.error("🪟 ❌ Failed to get window list")
```

### 3. Build & Run

```bash
scripts/build-shade.sh
scripts/run-shade.sh background
```

### 4. Stream & Verify Logs

```bash
scripts/watch-logs.sh [all|permissions|windows|lifecycle]
```

# Quick Reference

**Build:**
```bash
scripts/build-shade.sh
```

**Run/Status/Kill:**
```bash
scripts/status-shade.sh
scripts/run-shade.sh [background|foreground]
scripts/kill-shade.sh
```

**Log Streaming:**
```bash
scripts/watch-logs.sh [all|permissions|windows|lifecycle]
/usr/bin/log stream --predicate 'subsystem == "com.brishin.Shade"' --style compact
/usr/bin/log show --predicate 'subsystem == "com.brishin.Shade"' --last 30s --style compact
```

**Category Filtering:**
```bash
/usr/bin/log stream --predicate 'subsystem == "com.brishin.Shade" AND category == "WindowManager"' --style compact
```

# Example

WindowManager.swift logging setup:
```swift
import OSLog

private let logger = Logger(subsystem: "com.brishin.Shade", category: "WindowManager")

func enumerateWindows() {
    logger.info("🪟 Starting window enumeration")
    // ... implementation
    logger.info("🪟 Found \(count) windows")
}
```

# Key Principles

- **High signal only**: State transitions, not operations
- **Exact subsystem match**: Case-sensitive "com.brishin.Shade"
- **Categories**: AppLifecycle, AccessibilityManager, WindowManager

# Troubleshooting

**No logs appearing:**
```bash
ps aux | grep Shade
/usr/bin/log show --predicate 'subsystem == "com.brishin.Shade"' --last 1m
```

**App exits immediately:**
```bash
# Scripts use nohup for proper backgrounding
scripts/run-shade.sh background
```

**Build path issues:**
```bash
xcodebuild -project ShadeApp/Shade.xcodeproj -showBuildSettings | grep BUILT_PRODUCTS_DIR
```

**log command conflicts:**
- Use `/usr/bin/log` (full path) to avoid zsh builtin conflicts

**Permission issues:**
- Disable App Sandbox for accessibility APIs
- Verify entitlements file in build settings
