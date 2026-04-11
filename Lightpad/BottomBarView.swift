import SwiftUI

struct BottomBarView: View {
    let palette: PanelPalette
    let kelvin: Double
    let rgb: RGB
    @Binding var kelvinValue: Double
    @Binding var brightness: Double
    @Binding var keepAwake: Bool
    @Binding var autoMaxBrightness: Bool
    let onShowTipJar: () -> Void

    var body: some View {
        HStack(spacing: 24) {
            readout
            sliders
            controls
        }
        .panelChrome(palette)
    }

    private var readout: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("\(Int(kelvin))K")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(palette.primaryText)
            Text("RGB \(Int(rgb.r * 255)), \(Int(rgb.g * 255)), \(Int(rgb.b * 255))")
                .font(.footnote)
                .foregroundColor(palette.mutedText)
        }
    }

    private var sliders: some View {
        VStack(spacing: 12) {
            HStack {
                Text("Temperature")
                    .font(.footnote)
                    .foregroundColor(palette.mutedText)
                Slider(value: $kelvinValue, in: 3000...7000, step: 50)
                    .tint(.orange)
                    .accessibilityLabel("Color temperature")
                    .accessibilityValue("\(Int(kelvinValue)) Kelvin")
            }
            HStack {
                Text("Screen brightness")
                    .font(.footnote)
                    .foregroundColor(palette.mutedText)
                Slider(value: $brightness, in: 0.2...1.0, step: 0.01)
                    .tint(.orange)
                    .accessibilityLabel("Screen brightness")
                    .accessibilityValue("\(Int(brightness * 100)) percent")
                Button {
                    brightness = 1.0
                } label: {
                    Text("Max")
                        .font(.caption)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .frame(minHeight: 44)
                        .background(palette.buttonBackground)
                        .clipShape(Capsule())
                        .foregroundColor(palette.primaryText)
                }
                .accessibilityLabel("Set brightness to maximum")
            }
        }
    }

    private var controls: some View {
        VStack(alignment: .leading, spacing: 10) {
            Toggle(isOn: $keepAwake) {
                Text("Keep awake")
                    .font(.footnote)
                    .foregroundColor(palette.primaryText)
            }
            .toggleStyle(SwitchToggleStyle(tint: .orange))

            Toggle(isOn: $autoMaxBrightness) {
                Text("Auto max brightness")
                    .font(.footnote)
                    .foregroundColor(palette.primaryText)
            }
            .toggleStyle(SwitchToggleStyle(tint: .orange))

            Button(action: onShowTipJar) {
                HStack(spacing: 4) {
                    Image(systemName: "heart.fill")
                        .font(.caption)
                    Text("Tip Jar")
                        .font(.footnote)
                }
                .capsuleButton(palette)
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel("Tip Jar")
            .accessibilityHint("Opens tip options to support LightPad")

            VStack(alignment: .leading, spacing: 4) {
                Text("Tips")
                    .font(.footnote)
                    .foregroundColor(palette.mutedText)
                Text("Disable True Tone/Night Shift in Control Center for stable color.")
                    .font(.caption)
                    .foregroundColor(palette.primaryText.opacity(0.8))
                    .fixedSize(horizontal: false, vertical: true)
                Text("Check Auto\u{2011}Brightness, Reduce White Point, and Color Filters in Accessibility.")
                    .font(.caption2)
                    .foregroundColor(palette.mutedText)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}
