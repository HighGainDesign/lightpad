# lightPad — Agent Instructions

## What This Is

A native iOS and iPadOS app built with SwiftUI that serves as a lightbox for scanning or viewing film negatives and slides. It provides an adjustable, color-accurate backlight by converting Kelvin temperatures into specific RGB displays.

## Architecture

```
lightpad/
├── .gitignore                           # Git ignore for Xcode and macOS artifacts
├── AGENTS.md                            # This file
├── LICENSE                              # Project license
├── project.yml                          # xcodegen project spec
├── README.md                            # User/contributor documentation
└── Lightpad/
    ├── LightpadApp.swift                # @main SwiftUI app entry point
    ├── ContentView.swift                # Main UI, gestures, and color logic
    ├── Info.plist                       # App metadata and bundle config
    ├── LaunchScreen.storyboard          # Native launch screen
    └── Assets.xcassets/                 # App icon and LaunchIcon catalyst
```

### Key Design Decisions

- **Color Calculation Framework**: The app contains an underlying math formula in `ContentView.swift` (`kelvinToRGB`) that calculates Red, Green, and Blue values given a desired Kelvin temperature limit.
- **Native Brightness Control**: Modifies `UIScreen.main.brightness` to provide absolute panel brightness logic. Because iOS does not allow perfect, un-dimmed app brightness indefinitely, users are prompted via the UI to disable Display Accommodations.
- **Settings Storage**: The app uses `@AppStorage` for persistent settings such as the target brightness level, the chosen Kelvin color temperature, and auto-hiding hints/controls.
- **UI Responsiveness**: A custom logic path computes the `effectiveLuminance` of the given backlight to determine if the floating settings panel should use white text on a dark background or black text on a light background.
- **Debug Features**: A debug overlay is built into the code, providing insights on sliders, screen brightness readouts, and `scenePhase` state. By default, it is commented out for standard users, but a toggle can easily be re-enabled inside `ContentView.swift`.

## Future Distribution (High Gain Design)

The `project.yml` is already set up to use the `design.highgain.lightpad` bundle identifier and `UQ654V3JGQ` as the Development Team ID.

When packaging for the App Store:
1.  **Code Signing**: Verify `CODE_SIGN_STYLE` works implicitly with the certificate available in Xcode for High Gain Design.
2.  **App Store Assets**: Ensure `Assets.xcassets` has all required icon sizes for iOS and iPadOS.
3.  **Fastlane**: If implementing CD/CI in the future, standard Fastlane scripts (`fastlane init`) can drop in next to `project.yml` seamlessly, with `.xcworkspace` generated on the fly.

### Tip Jar (In-App Purchases)

For a future version, the user wishes to add a Tip Jar. 

When adding this framework:
1. **StoreKit Configuration**: Create a local `.storekit` file to test purchases using Xcode. Update the `project.yml` to ensure the file is tracked.
2. **App Store Connect**: Create the corresponding Non-Consumable (or Consumable) In-App Purchases under the App Record in App Store Connect.
3. **Implementation Details**: Implement a swift-based `StoreProvider` or `TipManager` using `StoreKit 2` with `async/await`. 
    - The UI should live in a secondary settings or info view cleanly accessible from the `ContentView`.
    - Ensure purchased states are verified via `Transaction.currentEntitlements`.

## Maintenance Cautions

- **Gestures**: The app uses `simultaneousGesture(LongPressGesture(minimumDuration: 0.6))` to show controls without interfering with touch interactions. When adjusting the UI, ensure nothing consumes the taps before the main `ZStack` does.
- **Brightness Changes**: The system brightness can change asynchronously. The app continually polls `UIScreen.main.brightness` via a timer publisher when debugging is activated. Changing anything in the `onChange(of: scenePhase)` logic should be tested via real devices locking and unlocking.
