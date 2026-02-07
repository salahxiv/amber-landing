#if os(macOS)
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

            Divider()

            // Einstellungen
            SettingsView(isExpanded: $settingsExpanded)

            Divider()

            // Tip Jar
            TipJarView(isExpanded: $tipJarExpanded)

            Divider()

            // Beenden Button
            quitButton
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
            HStack(spacing: 8) {
                Image(systemName: "xmark.circle")
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
                    .frame(width: 16)
                Text("Beenden")
                    .font(.system(size: 13))
                Spacer()
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

}

#Preview {
    MenuBarView(viewModel: TimerViewModel()) {
        print("Quit pressed")
    }
}
#endif
