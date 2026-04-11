import SwiftUI

struct PanelPalette {
    let useDark: Bool

    var background: Color {
        useDark ? Color.black.opacity(0.65) : Color.white.opacity(0.78)
    }

    var stroke: Color {
        useDark ? Color.white.opacity(0.12) : Color.black.opacity(0.12)
    }

    var primaryText: Color {
        useDark ? .white : .black
    }

    var mutedText: Color {
        useDark ? Color.white.opacity(0.65) : Color.black.opacity(0.6)
    }

    var buttonBackground: Color {
        useDark ? Color.white.opacity(0.1) : Color.white.opacity(0.95)
    }

    var buttonBorder: Color {
        useDark ? Color.white.opacity(0.25) : Color.black.opacity(0.2)
    }

    var activeFill: Color {
        useDark ? Color.orange.opacity(0.22) : Color.orange.opacity(0.2)
    }
}

struct PanelChromeModifier: ViewModifier {
    let palette: PanelPalette

    func body(content: Content) -> some View {
        content
            .padding(12)
            .background(palette.background)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(palette.stroke, lineWidth: 1)
            )
    }
}

struct CapsuleButtonModifier: ViewModifier {
    let palette: PanelPalette
    var isActive: Bool = false

    func body(content: Content) -> some View {
        content
            .font(.subheadline)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .frame(minHeight: 44)
            .background(isActive ? palette.activeFill : palette.buttonBackground)
            .overlay(
                Capsule()
                    .stroke(isActive ? Color.orange : palette.buttonBorder, lineWidth: 1)
            )
            .foregroundColor(palette.primaryText)
            .clipShape(Capsule())
    }
}

extension View {
    func panelChrome(_ palette: PanelPalette) -> some View {
        modifier(PanelChromeModifier(palette: palette))
    }

    func capsuleButton(_ palette: PanelPalette, isActive: Bool = false) -> some View {
        modifier(CapsuleButtonModifier(palette: palette, isActive: isActive))
    }
}
