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
    @State private var autoHideTask: DispatchWorkItem?
    @State private var showSplash = true
    @State private var hasShownSplash = false
    @State private var splashTask: DispatchWorkItem?
    @State private var observedBrightness: Double = Double(UIScreen.main.brightness)
    @State private var lastBrightnessChange = Date()
    @AppStorage("hideStartupHint") private var hideStartupHint = false
    @AppStorage("debugOverlayEnabled") private var debugOverlay = false
    @State private var showTipJar = false
    @StateObject private var storeManager = StoreManager.shared

    private let presets: [Preset] = [
        Preset(id: "bw", name: "B&W (D50)", kelvin: 5000),
        Preset(id: "daylight", name: "Daylight (C-41/E-6)", kelvin: 5500),
        Preset(id: "tungsten", name: "Tungsten", kelvin: 3200)
    ]

    private var activePresetId: String? {
        presets.first { abs($0.kelvin - kelvin) < 1 }?.id
    }

    private var rgb: RGB {
        kelvinToRGB(kelvin)
    }

    private var effectiveLuminance: Double {
        (0.2126 * rgb.r) + (0.7152 * rgb.g) + (0.0722 * rgb.b)
    }

    private var useDarkPanel: Bool {
        effectiveLuminance > 0.55
    }

    private var panelBackground: Color {
        useDarkPanel ? Color.black.opacity(0.65) : Color.white.opacity(0.78)
    }

    private var panelStroke: Color {
        useDarkPanel ? Color.white.opacity(0.12) : Color.black.opacity(0.12)
    }

    private var primaryText: Color {
        useDarkPanel ? .white : .black
    }

    private var mutedText: Color {
        useDarkPanel ? Color.white.opacity(0.65) : Color.black.opacity(0.6)
    }

    private var buttonBackground: Color {
        useDarkPanel ? Color.white.opacity(0.1) : Color.white.opacity(0.95)
    }

    private var buttonBorder: Color {
        useDarkPanel ? Color.white.opacity(0.25) : Color.black.opacity(0.2)
    }

    private var activeFill: Color {
        useDarkPanel ? Color.orange.opacity(0.22) : Color.orange.opacity(0.2)
    }

    private let brightnessTimer = Timer.publish(every: 0.3, on: .main, in: .common).autoconnect()

    var body: some View {
        ZStack {
            Color(red: rgb.r, green: rgb.g, blue: rgb.b)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                topBar
                    .opacity(controlsHidden ? 0 : 1)
                    .offset(y: controlsHidden ? -12 : 0)
                    .allowsHitTesting(!controlsHidden)
                Spacer()
                bottomBar
                    .opacity(controlsHidden ? 0 : 1)
                    .offset(y: controlsHidden ? 12 : 0)
                    .allowsHitTesting(!controlsHidden)
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 12)

            if showStartupHint {
                VStack(spacing: 14) {
                    Text("Controls")
                        .font(.headline)
                        .foregroundColor(.white)
                    Text("Double‑tap or press and hold (0.6s) to show controls.\nDisable True Tone & Night Shift in Control Center for stable color.")
                        .font(.subheadline)
                        .multilineTextAlignment(.center)
                        .foregroundColor(.white.opacity(0.95))
                    Text("Also check Auto‑Brightness, Reduce White Point, and Color Filters in Accessibility.")
                        .font(.footnote)
                        .multilineTextAlignment(.center)
                        .foregroundColor(.white.opacity(0.8))

                    Toggle("Don’t show again", isOn: $hideStartupHint)
                        .toggleStyle(SwitchToggleStyle(tint: .orange))
                        .foregroundColor(.white)

                    Button(action: {
                        showStartupHint = false
                    }) {
                        Text("Got it")
                            .font(.subheadline)
                            .padding(.horizontal, 18)
                            .padding(.vertical, 8)
                            .background(Color.white.opacity(0.15))
                            .clipShape(Capsule())
                            .foregroundColor(.white)
                    }
                }
                .padding(.horizontal, 26)
                .padding(.vertical, 18)
                .background(Color.black.opacity(0.65))
                .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                .frame(maxWidth: 520)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                .transition(.opacity)
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
        .animation(.easeInOut(duration: 0.2), value: controlsHidden)
        .onAppear {
            let currentBrightness = Double(UIScreen.main.brightness)
            brightness = currentBrightness
            observedBrightness = currentBrightness
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
            if value {
                brightness = 1.0
            }
        }
        .onChange(of: hideStartupHint) { value in
            if value {
                showStartupHint = false
            }
        }
        .onChange(of: scenePhase) { phase in
            if phase == .active {
                showSplashBrieflyIfNeeded()
                showControlsBriefly()
            }
        }
        .sheet(isPresented: $showTipJar) {
            TipJarView(store: storeManager)
        }
        .onReceive(brightnessTimer) { _ in
            let current = Double(UIScreen.main.brightness)
            if abs(current - observedBrightness) > 0.005 {
                observedBrightness = current
                lastBrightnessChange = Date()
            }
        }
    }

    private var topBar: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 2) {
                Text("LightPad")
                    .font(.headline)
                    .foregroundColor(primaryText)
                Text("Film viewing lightbox")
                    .font(.footnote)
                    .foregroundColor(mutedText)
            }

            Spacer()

            HStack(spacing: 8) {
                ForEach(presets) { preset in
                    Button(action: {
                        kelvin = preset.kelvin
                    }) {
                        Text(preset.name)
                            .font(.subheadline)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(activePresetId == preset.id ? activeFill : buttonBackground)
                            .overlay(
                                Capsule()
                                    .stroke(activePresetId == preset.id ? Color.orange : buttonBorder, lineWidth: 1)
                            )
                            .foregroundColor(primaryText)
                            .clipShape(Capsule())
                    }
                }
            }

            Button(action: {
                toggleControls()
            }) {
                Text(controlsHidden ? "Show controls" : "Hide controls")
                    .font(.subheadline)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(buttonBackground)
                    .overlay(
                        Capsule()
                            .stroke(buttonBorder, lineWidth: 1)
                    )
                    .foregroundColor(primaryText)
                    .clipShape(Capsule())
            }
        }
        .padding(12)
        .background(panelBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(panelStroke, lineWidth: 1)
        )
    }

    private var bottomBar: some View {
        HStack(spacing: 24) {
            VStack(alignment: .leading, spacing: 6) {
                Text("\(Int(kelvin))K")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(primaryText)
                Text("RGB \(Int(rgb.r * 255)), \(Int(rgb.g * 255)), \(Int(rgb.b * 255))")
                    .font(.footnote)
                    .foregroundColor(mutedText)
            }

            VStack(spacing: 12) {
                HStack {
                    Text("Temperature")
                        .font(.footnote)
                        .foregroundColor(mutedText)
                    Slider(value: $kelvin, in: 3000...7000, step: 50)
                        .tint(.orange)
                }
                HStack {
                    Text("Screen brightness")
                        .font(.footnote)
                        .foregroundColor(mutedText)
                    Slider(value: $brightness, in: 0.2...1.0, step: 0.01)
                        .tint(.orange)
                    Button(action: {
                        brightness = 1.0
                    }) {
                        Text("Max")
                            .font(.caption)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(buttonBackground)
                            .clipShape(Capsule())
                            .foregroundColor(primaryText)
                    }
                }
            }

            VStack(alignment: .leading, spacing: 10) {
                Toggle(isOn: $keepAwake) {
                    Text("Keep awake")
                        .font(.footnote)
                        .foregroundColor(primaryText)
                }
                .toggleStyle(SwitchToggleStyle(tint: .orange))

                Toggle(isOn: $autoMaxBrightness) {
                    Text("Auto max brightness")
                        .font(.footnote)
                        .foregroundColor(primaryText)
                }
                .toggleStyle(SwitchToggleStyle(tint: .orange))

//                Toggle(isOn: $debugOverlay) {
//                    Text("Debug overlay")
//                        .font(.footnote)
//                        .foregroundColor(primaryText)
//                }
//                .toggleStyle(SwitchToggleStyle(tint: .orange))

                Button(action: { showTipJar = true }) {
                    HStack(spacing: 4) {
                        Image(systemName: "heart.fill")
                            .font(.caption)
                        Text("Tip Jar")
                            .font(.footnote)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(buttonBackground)
                    .overlay(
                        Capsule()
                            .stroke(buttonBorder, lineWidth: 1)
                    )
                    .foregroundColor(primaryText)
                    .clipShape(Capsule())
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("Tips")
                        .font(.footnote)
                        .foregroundColor(mutedText)
                    Text("Disable True Tone/Night Shift in Control Center for stable color.")
                        .font(.caption)
                        .foregroundColor(primaryText.opacity(0.8))
                        .fixedSize(horizontal: false, vertical: true)
                    Text("Check Auto‑Brightness, Reduce White Point, and Color Filters in Accessibility.")
                        .font(.caption2)
                        .foregroundColor(mutedText)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
        .padding(12)
        .background(panelBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(panelStroke, lineWidth: 1)
        )
    }

    private func showControlsBriefly() {
        controlsHidden = false
        showStartupHint = !hideStartupHint
        scheduleAutoHide()
    }

    private func showControls() {
        withAnimation(.easeInOut(duration: 0.2)) {
            controlsHidden = false
        }
    }

    private func toggleControls() {
        withAnimation(.easeInOut(duration: 0.2)) {
            controlsHidden.toggle()
        }
    }

    private var splashView: some View {
        ZStack {
            Color.black
                .ignoresSafeArea()
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
                Text("© 2026 Anand Mandapati")
                    .font(.caption2)
                    .foregroundColor(.white.opacity(0.6))
                    .padding(.top, 24)
            }
        }
    }

    private func showSplashBrieflyIfNeeded() {
        guard !hasShownSplash else { return }
        hasShownSplash = true
        showSplash = true
        splashTask?.cancel()
        let task = DispatchWorkItem {
            withAnimation(.easeOut(duration: 0.3)) {
                showSplash = false
            }
        }
        splashTask = task
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0, execute: task)
    }

    private var debugPanel: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Debug")
                .font(.caption)
                .fontWeight(.semibold)
            Text("Kelvin: \(Int(kelvin))K")
            Text("RGB: \(Int(rgb.r * 255)), \(Int(rgb.g * 255)), \(Int(rgb.b * 255))")
            Text(String(format: "Brightness: slider %.2f, system %.2f", brightness, observedBrightness))
            Text("Auto max: \(autoMaxBrightness ? "On" : "Off")")
            Text("Scene: \(scenePhase == .active ? "Active" : "Inactive")")
            Text("Brightness change: \(relativeTime(lastBrightnessChange))")
        }
        .font(.caption2)
        .padding(10)
        .background(Color.black.opacity(0.6))
        .foregroundColor(.white)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    private func relativeTime(_ date: Date) -> String {
        let seconds = Int(Date().timeIntervalSince(date))
        if seconds < 5 { return "now" }
        if seconds < 60 { return "\(seconds)s ago" }
        return "\(seconds / 60)m ago"
    }

    private func scheduleAutoHide() {
        autoHideTask?.cancel()
        let task = DispatchWorkItem {
            withAnimation(.easeInOut(duration: 0.2)) {
                controlsHidden = true
            }
        }
        autoHideTask = task
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.5, execute: task)
    }
}
