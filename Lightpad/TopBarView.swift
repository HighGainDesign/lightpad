import SwiftUI

struct TopBarView: View {
    let palette: PanelPalette
    let presets: [Preset]
    let activePresetId: String?
    let controlsHidden: Bool
    let onSelectPreset: (Double) -> Void
    let onToggleControls: () -> Void

    var body: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 2) {
                Text("LightPad")
                    .font(.headline)
                    .foregroundColor(palette.primaryText)
                Text("Film viewing lightbox")
                    .font(.footnote)
                    .foregroundColor(palette.mutedText)
            }

            Spacer()

            HStack(spacing: 8) {
                ForEach(presets) { preset in
                    Button {
                        onSelectPreset(preset.kelvin)
                    } label: {
                        Text(preset.name)
                            .capsuleButton(palette, isActive: activePresetId == preset.id)
                    }
                    .accessibilityLabel("\(preset.name) preset")
                    .accessibilityAddTraits(activePresetId == preset.id ? .isSelected : [])
                    .accessibilityHint("Sets color temperature to \(Int(preset.kelvin)) Kelvin")
                }
            }

            Button {
                onToggleControls()
            } label: {
                Text(controlsHidden ? "Show controls" : "Hide controls")
                    .capsuleButton(palette)
            }
        }
        .panelChrome(palette)
    }
}
