import SwiftUI

/// Visuelle Vorschau-Karte für ein Overlay-Theme
struct ThemeCard: View {
    let theme: OverlayTheme
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                // Vorschau
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(theme.previewGradient)
                        .frame(height: 70)

                    // Akzent-Kreis
                    Circle()
                        .fill(theme.accentColor.opacity(0.3))
                        .frame(width: 30, height: 30)

                    // Ring
                    Circle()
                        .stroke(theme.accentColor, lineWidth: 2)
                        .frame(width: 28, height: 28)
                }
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(isSelected ? theme.accentColor : Color.clear, lineWidth: 2)
                )

                // Name
                HStack(spacing: 4) {
                    Image(systemName: theme.icon)
                        .font(.system(size: 10))
                    Text(theme.displayName)
                        .font(.system(size: 11, weight: .medium))
                }
                .foregroundColor(isSelected ? theme.accentColor : .secondary)
            }
        }
        .buttonStyle(.plain)
    }
}
