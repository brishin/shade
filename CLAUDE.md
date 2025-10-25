# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview
Shade is a SwiftUI application for Apple platforms (iOS/macOS). The project was created on October 24, 2025.

## Project Structure
```
Shade/
├── Shade.xcodeproj/          # Xcode project files
├── Shade/                     # Main application source
│   ├── ShadeApp.swift        # App entry point (@main)
│   ├── ContentView.swift     # Main view
│   └── Assets.xcassets/      # App assets, icons, colors
├── ShadeTests/               # Unit tests (Swift Testing framework)
└── ShadeUITests/             # UI tests
```

## Development Commands

### Building
```bash
# Build the project (using xcodebuild for Xcode projects)
xcodebuild -project Shade/Shade.xcodeproj -scheme Shade build

# Build for release
xcodebuild -project Shade/Shade.xcodeproj -scheme Shade -configuration Release build
```

### Running Tests
```bash
# Run all tests
swift test --package-path Shade

# For running specific test targets with xcodebuild:
xcodebuild test -project Shade/Shade.xcodeproj -scheme Shade -only-testing:ShadeTests
xcodebuild test -project Shade/Shade.xcodeproj -scheme Shade -only-testing:ShadeUITests
```

### Opening in Xcode
```bash
open Shade/Shade.xcodeproj
```

## Architecture Notes

### Testing Framework
The project uses Apple's modern **Swift Testing** framework (not XCTest). Tests use the `@Test` attribute and `#expect(...)` for assertions instead of XCTest's `XCTAssert` functions.

### App Structure
- **ShadeApp.swift**: Standard SwiftUI app entry point with `@main` attribute
- **ContentView.swift**: Root view with preview support using `#Preview` macro
