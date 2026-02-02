import SwiftUI

/// Steuerungs-Buttons für den Timer
struct ControlButtonsView: View {
    @ObservedObject var viewModel: TimerViewModel

    var body: some View {
        HStack(spacing: 16) {
            // Start/Pause Button
            Button(action: {
                viewModel.togglePause()
            }) {
                HStack {
                    Image(systemName: buttonIcon)
                    Text(buttonText)
                }
                .frame(minWidth: 80)
            }
            .buttonStyle(.borderedProminent)
            .tint(buttonColor)

            // Reset Button
            Button(action: {
                viewModel.reset()
            }) {
                HStack {
                    Image(systemName: "arrow.counterclockwise")
                    Text("Reset")
                }
            }
            .buttonStyle(.bordered)
            .disabled(viewModel.currentPhase == .idle)
        }
    }

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
            return "Start"
        case .work, .rest:
            return viewModel.isPaused ? "Weiter" : "Pause"
        }
    }

    private var buttonColor: Color {
        switch viewModel.currentPhase {
        case .idle:
            return .blue
        case .work:
            return viewModel.isPaused ? .green : .orange
        case .rest:
            return .green
        }
    }
}

#Preview {
    ControlButtonsView(viewModel: TimerViewModel())
        .padding()
}
