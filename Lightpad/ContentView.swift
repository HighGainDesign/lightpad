import SwiftUI
import UIKit

struct ContentView: View {
    @Environment(\.scenePhase) private var scenePhase
    @Binding var keepAwake: Bool
    @AppStorage("kelvin") private var kelvin: Double = 5500
    @AppStorage("screenBrightness") private var brightness: Double = 1.0
    @AppStorage("autoMaxBrightness") private var autoMaxBrightness = true
    @State private var controlsHidden = false
    @State private var showStartupHint = true
    @State private var autoHideTask: Task<Void, Never>?
    @State private var showSplash = true
    @State private var hasShownSplash = false
    @AppStorage("hideStartupHint") private var hideStartupHint = false
    @AppStorage("debugOverlayEnabled") private var debugOverlay = false
    @State private var showTipJar = false
    @ObservedObject private var storeManager = StoreManager.shared
    @State private var controlsManuallyHidden = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private let presets: [Preset] = [
        Preset(id: "bw", name: "B&W (D50)", kelvin: 5000),
        Preset(id: "daylight", name: "Daylight (C-41/E-6)", kelvin: 5500),
        Preset(id: "tungsten", name: "Tungsten", kelvin: 3200)
    ]

    private var activePresetId: String? {
        presets.first { abs($0.kelvin - kelvin) < 1 }?.id
    }

    private var rgb: RGB { kelvinToRGB(kelvin) }

    private var effectiveLuminance: Double {
        (0.2126 * rgb.r) + (0.7152 * rgb.g) + (0.0722 * rgb.b)
    }

    private var palette: PanelPalette {
        PanelPalette(useDark: effectiveLuminance > 0.55)
    }

    private var animation: Animation? {
        reduceMotion ? nil : .easeInOut(duration: 0.2)
    }

    var body: some View {
        ZStack {
            Color(red: rgb.r, green: rgb.g, blue: rgb.b)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                TopBarView(
                    palette: palette,
                    presets: presets,
                    activePresetId: activePresetId,
                    controlsHidden: controlsHidden,
                    onSelectPreset: { kelvin = $0 },
                    onToggleControls: toggleControls
                )
                .opacity(controlsHidden ? 0 : 1)
                .offset(y: controlsHidden ? -12 : 0)
                .allowsHitTesting(!controlsHidden)

                Spacer()

                BottomBarView(
                    palette: palette,
                    kelvin: kelvin,
                    rgb: rgb,
                    kelvinValue: $kelvin,
                    brightness: $brightness,
                    keepAwake: $keepAwake,
                    autoMaxBrightness: $autoMaxBrightness,
                    onShowTipJar: { showTipJar = true }
                )
                .opacity(controlsHidden ? 0 : 1)
                .offset(y: controlsHidden ? 12 : 0)
                .allowsHitTesting(!controlsHidden)
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 12)

            if showStartupHint {
                StartupHintOverlay(
                    isVisible: $showStartupHint,
                    dontShowAgain: $hideStartupHint
                )
            }

            if showSplash {
                splashView
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .transition(.opacity)
            }

            if debugOverlay {
                debugPanel
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                    .padding(16)
                    .transition(.opacity)
            }
        }
        .gesture(
            TapGesture(count: 2)
                .onEnded { toggleControls() }
        )
        .simultaneousGesture(
            LongPressGesture(minimumDuration: 0.6)
                .onEnded { _ in showControls() }
        )
        .accessibilityAction(.magicTap) { toggleControls() }
        .animation(animation, value: controlsHidden)
        .onAppear {
            let currentBrightness = Double(UIScreen.main.brightness)
            brightness = currentBrightness
            if autoMaxBrightness {
                brightness = 1.0
                UIScreen.main.brightness = 1.0
            }
            showSplashBrieflyIfNeeded()
            showControlsBriefly()
        }
        .onChange(of: brightness) { value in
            UIScreen.main.brightness = CGFloat(value)
        }
        .onChange(of: autoMaxBrightness) { value in
            if value { brightness = 1.0 }
        }
        .onChange(of: hideStartupHint) { value in
            if value { showStartupHint = false }
        }
        .onChange(of: scenePhase) { phase in
            if phase == .active, !controlsManuallyHidden {
                showControlsBriefly()
            }
        }
        .sheet(isPresented: $showTipJar) {
            TipJarView(store: storeManager)
        }
    }

    // MARK: - Controls visibility

    private func showControlsBriefly() {
        controlsHidden = false
        showStartupHint = !hideStartupHint
        if !UIAccessibility.isVoiceOverRunning {
            scheduleAutoHide()
        }
    }

    private func showControls() {
        withAnimation(animation) {
            controlsHidden = false
            controlsManuallyHidden = false
        }
    }

    private func toggleControls() {
        withAnimation(animation) {
            controlsHidden.toggle()
            controlsManuallyHidden = controlsHidden
        }
    }

    private func scheduleAutoHide() {
        autoHideTask?.cancel()
        autoHideTask = Task {
            try? await Task.sleep(for: .seconds(3.5))
            guard !Task.isCancelled else { return }
            withAnimation(animation) {
                controlsHidden = true
            }
        }
    }

    // MARK: - Splash

    private var splashView: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            VStack(spacing: 14) {
                Image("LaunchIcon")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 140, height: 140)
                Text("LightPad")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                Text("Film viewing lightbox")
                    .font(.footnote)
                    .foregroundColor(.white.opacity(0.7))
                Text("© 2026 High Gain Design")
                    .font(.caption2)
                    .foregroundColor(.white.opacity(0.6))
                    .padding(.top, 24)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("LightPad, Film viewing lightbox, loading")
    }

    private func showSplashBrieflyIfNeeded() {
        guard !hasShownSplash else { return }
        hasShownSplash = true
        showSplash = true
        Task {
            try? await Task.sleep(for: .seconds(3.0))
            withAnimation(reduceMotion ? nil : .easeOut(duration: 0.3)) {
                showSplash = false
            }
        }
    }

    // MARK: - Debug

    private var debugPanel: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Debug")
                .font(.caption)
                .fontWeight(.semibold)
            Text("Kelvin: \(Int(kelvin))K")
            Text("RGB: \(Int(rgb.r * 255)), \(Int(rgb.g * 255)), \(Int(rgb.b * 255))")
            Text(String(format: "Brightness: slider %.2f, system %.2f", brightness, Double(UIScreen.main.brightness)))
            Text("Auto max: \(autoMaxBrightness ? "On" : "Off")")
            Text("Scene: \(scenePhase == .active ? "Active" : "Inactive")")
        }
        .font(.caption2)
        .padding(10)
        .background(Color.black.opacity(0.6))
        .foregroundColor(.white)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}
