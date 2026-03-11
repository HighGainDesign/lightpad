# lightPad — Agent Instructions

## Commands

```sh
# Generate Xcode project from spec
xcodegen generate

# Build (requires macOS with Xcode)
xcodebuild -project Lightpad.xcodeproj -scheme Lightpad -sdk iphonesimulator build

# No test target configured yet
```

## Architecture

A native iOS/iPadOS SwiftUI app that serves as a lightbox for scanning film negatives and slides. It provides an adjustable, color-accurate backlight by converting Kelvin temperatures to RGB values displayed fullscreen. Single-screen app with one main view and floating settings panel.

Uses xcodegen (`project.yml`) to generate the Xcode project. Bundle ID: `design.highgain.lightpad`, Team: `UQ654V3JGQ`, minimum iOS 16.0.

## Key Design Decisions

- **Kelvin→RGB conversion**: `kelvinToRGB()` in ContentView.swift implements the color math formula
- **Native brightness control**: Directly sets `UIScreen.main.brightness`; user prompted to disable Display Accommodations for best results
- **Persistent settings**: `@AppStorage` for brightness, Kelvin temp, and UI preferences
- **Adaptive UI contrast**: `effectiveLuminance` determines whether floating panel uses light or dark text
- **Debug overlay**: Built-in but commented out by default; toggle available in ContentView.swift

## Gotchas

- **Gesture conflicts**: Uses `simultaneousGesture(LongPressGesture(minimumDuration: 0.6))` — don't let other gestures consume taps before the main ZStack
- **Brightness is async**: System brightness can change outside the app. Test `onChange(of: scenePhase)` logic on real devices with lock/unlock cycles

## Safety & Permissions

- **Allowed**: Edit Swift source, update project.yml, modify assets
- **Ask first**: Changes to bundle ID, team ID, or deployment target
- **Never**: Commit signing keys or provisioning profiles

## Session Continuity

See HANDOFF.md for current task state and next steps.

## Handoff Protocol

This project uses AGENTS.md + HANDOFF.md for cross-agent continuity.
On session start: read both files. While working: update HANDOFF.md before/after each step.
On session end: full HANDOFF.md update, commit it.
