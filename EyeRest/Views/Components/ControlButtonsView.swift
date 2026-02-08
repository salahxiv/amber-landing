import SwiftUI

/// Steuerungs-Buttons für den Timer
struct ControlButtonsView: View {
    @ObservedObject var viewModel: TimerViewModel

    @GestureState private var isMainPressed = false
    @GestureState private var isResetPressed = false

    var body: some View {
        VStack(spacing: 16) {
            // Haupt-Button (Start / Pause / Weiter)
            Button(action: {
                viewModel.togglePause()
            }) {
                HStack(spacing: 8) {
                    Image(systemName: buttonIcon)
                        .font(.headline)
                    Text(buttonText)
                        .font(.headline)
                        .fontWeight(.semibold)
                }
                .foregroundColor(.white)
                .frame(minWidth: 160, minHeight: 50)
                .background(
                    Capsule()
                        .fill(buttonGradient)
                        .shadow(color: buttonColor.opacity(0.35), radius: 10, y: 4)
                )
                .clipShape(Capsule())
            }
            .buttonStyle(.plain)
            .scaleEffect(isMainPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.15), value: isMainPressed)
            .simultaneousGesture(
                DragGesture(minimumDistance: 0)
                    .updating($isMainPressed) { _, state, _ in
                        state = true
                    }
            )

            // Reset Button (nur wenn nicht idle)
            if viewModel.currentPhase != .idle {
                Button(action: {
                    viewModel.reset()
                }) {
                    Image(systemName: "arrow.counterclockwise")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.secondary)
                        .frame(width: 44, height: 44)
                        .background(
                            Circle()
                                .fill(.ultraThinMaterial)
                        )
                }
                .buttonStyle(.plain)
                .scaleEffect(isResetPressed ? 0.9 : 1.0)
                .animation(.easeInOut(duration: 0.15), value: isResetPressed)
                .simultaneousGesture(
                    DragGesture(minimumDistance: 0)
                        .updating($isResetPressed) { _, state, _ in
                            state = true
                        }
                )
                .transition(.scale.combined(with: .opacity))
            }
        }
        .animation(.spring(duration: 0.3), value: viewModel.currentPhase)
    }

    // MARK: - Computed Properties

    private var buttonIcon: String {
        switch viewModel.currentPhase {
        case .idle:
            return "play.fill"
        case .work, .rest:
            return viewModel.isPaused ? "play.fill" : "pause.fill"
        }
    }

    private var buttonText: String {
        switch viewModel.currentPhase {
        case .idle:
            return String(localized: "button.start")
        case .work, .rest:
            return viewModel.isPaused ? String(localized: "button.continue") : String(localized: "button.pause")
        }
    }

    private var theme: OverlayTheme {
        SettingsManager.shared.currentTheme
    }

    private var buttonColor: Color {
        switch viewModel.currentPhase {
        case .idle:
            return .blue
        case .work:
            return viewModel.isPaused ? .green : .orange
        case .rest:
            return theme.accentColor
        }
    }

    private var buttonGradient: LinearGradient {
        switch viewModel.currentPhase {
        case .idle:
            return LinearGradient(
                colors: [.blue, .cyan],
                startPoint: .leading,
                endPoint: .trailing
            )
        case .work:
            if viewModel.isPaused {
                return LinearGradient(
                    colors: [.green, .mint],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            } else {
                return LinearGradient(
                    colors: [.orange, Color(red: 0.9, green: 0.3, blue: 0.2)],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            }
        case .rest:
            return LinearGradient(
                colors: [theme.accentColor, theme.secondaryAccent],
                startPoint: .leading,
                endPoint: .trailing
            )
        }
    }
}

#Preview {
    ControlButtonsView(viewModel: TimerViewModel())
        .padding()
}
