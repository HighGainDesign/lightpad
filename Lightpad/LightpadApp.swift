import SwiftUI
import UIKit

@main
struct LightpadApp: App {
    @Environment(\.scenePhase) private var scenePhase
    @AppStorage("keepAwake") private var keepAwake = true

    var body: some Scene {
        WindowGroup {
            ContentView(keepAwake: $keepAwake)
                .onChange(of: keepAwake) { value in
                    UIApplication.shared.isIdleTimerDisabled = value
                }
                .onChange(of: scenePhase) { phase in
                    if phase == .active {
                        UIApplication.shared.isIdleTimerDisabled = keepAwake
                    }
                }
        }
    }
}
