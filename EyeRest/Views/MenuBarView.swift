import SwiftUI

/// Hauptansicht im Menüleisten-Popover
struct MenuBarView: View {
    @ObservedObject var viewModel: TimerViewModel
    @State private var settingsExpanded = false
    @State private var statisticsExpanded = false
    @State private var tipJarExpanded = false

    let onQuit: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            // Header
            headerView
                .padding(.vertical, 12)

            Divider()

            // Timer Display
            VStack(spacing: 16) {
                TimerDisplayView(
                    remainingTime: viewModel.formattedTime,
                    progress: viewModel.progress,
                    statusText: viewModel.statusText,
                    phase: viewModel.currentPhase
                )

                ControlButtonsView(viewModel: viewModel)
            }
            .padding(.vertical, 20)

            Divider()

            // Statistiken
            StatisticsView(isExpanded: $statisticsExpanded)
                .padding(.vertical, 8)

            Divider()

            // Einstellungen
            SettingsView(isExpanded: $settingsExpanded)
                .padding(.vertical, 8)

            Divider()

            // Tip Jar
            TipJarView(isExpanded: $tipJarExpanded)
                .padding(.vertical, 8)

            Divider()

            // Beenden Button
            quitButton
                .padding(.vertical, 8)
        }
        .frame(width: Constants.popoverWidth)
        .fixedSize(horizontal: false, vertical: true)
    }

    // MARK: - Subviews

    private var headerView: some View {
        HStack {
            Image(systemName: "eye.fill")
                .font(.title2)
                .foregroundColor(.blue)

            Text("EyeRest")
                .font(.headline)
        }
    }

    private var quitButton: some View {
        Button(action: onQuit) {
            HStack {
                Image(systemName: "xmark.circle")
                    .foregroundColor(.secondary)
                Text("Quit EyeRest")
            }
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 16)
    }

}

#Preview {
    MenuBarView(viewModel: TimerViewModel()) {
        print("Quit pressed")
    }
}
