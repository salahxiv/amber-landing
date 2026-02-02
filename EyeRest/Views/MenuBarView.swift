import SwiftUI
import ServiceManagement

/// Hauptansicht im Menüleisten-Popover
struct MenuBarView: View {
    @ObservedObject var viewModel: TimerViewModel
    @AppStorage(Constants.launchAtLoginKey) private var launchAtLogin = false

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

            // Einstellungen
            settingsView
                .padding(.vertical, 8)

            Divider()

            // Beenden Button
            quitButton
                .padding(.vertical, 8)
        }
        .frame(width: Constants.popoverWidth)
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

    private var settingsView: some View {
        Toggle(isOn: $launchAtLogin) {
            HStack {
                Image(systemName: "power")
                    .foregroundColor(.secondary)
                Text("Bei Login starten")
            }
        }
        .toggleStyle(.checkbox)
        .padding(.horizontal, 16)
        .onChange(of: launchAtLogin) { _, newValue in
            updateLaunchAtLogin(newValue)
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

    // MARK: - Actions

    private func updateLaunchAtLogin(_ enabled: Bool) {
        do {
            if enabled {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
        } catch {
            print("Fehler beim Ändern der Login-Einstellung: \(error)")
            // Bei Fehler den Toggle zurücksetzen
            launchAtLogin = !enabled
        }
    }
}

#Preview {
    MenuBarView(viewModel: TimerViewModel()) {
        print("Quit pressed")
    }
}
