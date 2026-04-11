import SwiftUI

struct StartupHintOverlay: View {
    @Binding var isVisible: Bool
    @Binding var dontShowAgain: Bool

    var body: some View {
        VStack(spacing: 14) {
            Text("Controls")
                .font(.headline)
                .foregroundColor(.white)
            Text("Double\u{2011}tap or press and hold (0.6s) to show controls.\nDisable True Tone & Night Shift in Control Center for stable color.")
                .font(.subheadline)
                .multilineTextAlignment(.center)
                .foregroundColor(.white.opacity(0.95))
            Text("Also check Auto\u{2011}Brightness, Reduce White Point, and Color Filters in Accessibility.")
                .font(.footnote)
                .multilineTextAlignment(.center)
                .foregroundColor(.white.opacity(0.8))

            Toggle("Don't show again", isOn: $dontShowAgain)
                .toggleStyle(SwitchToggleStyle(tint: .orange))
                .foregroundColor(.white)

            Button {
                isVisible = false
            } label: {
                Text("Got it")
                    .font(.subheadline)
                    .padding(.horizontal, 18)
                    .padding(.vertical, 8)
                    .frame(minHeight: 44)
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
        .accessibilityAddTraits(.isModal)
        .transition(.opacity)
    }
}
