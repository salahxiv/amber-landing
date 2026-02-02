import SwiftUI
import ServiceManagement

/// Erweiterbare Einstellungsansicht für Timer und Audio
struct SettingsView: View {
    @ObservedObject var settings = SettingsManager.shared
    @AppStorage(Constants.launchAtLoginKey) private var launchAtLogin = false
    @Binding var isExpanded: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header mit Expand/Collapse Toggle
            Button(action: { withAnimation(.easeInOut(duration: 0.2)) { isExpanded.toggle() } }) {
                HStack {
                    Image(systemName: "gearshape")
                        .foregroundColor(.secondary)
                    Text("Einstellungen")
                        .font(.subheadline.weight(.medium))
                    Spacer()
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .foregroundColor(.secondary)
                        .font(.caption)
                }
                .padding(.vertical, 8)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            if isExpanded {
                VStack(alignment: .leading, spacing: 16) {
                    // Timer Einstellungen
                    timerSettingsSection

                    Divider()

                    // Sound Einstellungen
                    soundSettingsSection

                    Divider()

                    // Bei Login starten
                    launchAtLoginSection
                }
                .padding(.leading, 4)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding(.horizontal, 16)
    }

    // MARK: - Timer Einstellungen

    private var timerSettingsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Timer")
                .font(.caption)
                .foregroundColor(.secondary)

            // Arbeitszeit
            HStack {
                Image(systemName: "desktopcomputer")
                    .foregroundColor(.blue)
                    .frame(width: 20)
                Text("Arbeitszeit")
                Spacer()
                TimeStepper(
                    value: $settings.workDuration,
                    range: 60...3600,
                    step: 60,
                    formatter: { "\($0 / 60) Min" }
                )
            }
            .font(.subheadline)

            // Pausenzeit
            HStack {
                Image(systemName: "eye")
                    .foregroundColor(.green)
                    .frame(width: 20)
                Text("Pausenzeit")
                Spacer()
                TimeStepper(
                    value: $settings.restDuration,
                    range: 5...120,
                    step: 5,
                    formatter: { "\($0) Sek" }
                )
            }
            .font(.subheadline)
        }
    }

    // MARK: - Sound Einstellungen

    private var soundSettingsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Audio")
                .font(.caption)
                .foregroundColor(.secondary)

            Toggle(isOn: $settings.soundEnabled) {
                HStack {
                    Image(systemName: settings.soundEnabled ? "speaker.wave.2" : "speaker.slash")
                        .foregroundColor(.secondary)
                        .frame(width: 20)
                    Text("Ton bei Pausen")
                }
            }
            .toggleStyle(.checkbox)
            .font(.subheadline)
        }
    }

    // MARK: - Bei Login starten

    private var launchAtLoginSection: some View {
        Toggle(isOn: $launchAtLogin) {
            HStack {
                Image(systemName: "power")
                    .foregroundColor(.secondary)
                    .frame(width: 20)
                Text("Bei Login starten")
            }
        }
        .toggleStyle(.checkbox)
        .font(.subheadline)
        .onChange(of: launchAtLogin) { _, newValue in
            updateLaunchAtLogin(newValue)
        }
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
            launchAtLogin = !enabled
        }
    }
}

// MARK: - Time Stepper Component

/// Stepper mit +/- Buttons für Zeiteinstellungen
struct TimeStepper: View {
    @Binding var value: Int
    let range: ClosedRange<Int>
    let step: Int
    let formatter: (Int) -> String

    var body: some View {
        HStack(spacing: 4) {
            Button(action: decrement) {
                Image(systemName: "minus")
                    .font(.caption.weight(.semibold))
                    .frame(width: 20, height: 20)
            }
            .buttonStyle(.borderless)
            .disabled(value <= range.lowerBound)

            Text(formatter(value))
                .font(.subheadline.monospacedDigit())
                .frame(width: 50)

            Button(action: increment) {
                Image(systemName: "plus")
                    .font(.caption.weight(.semibold))
                    .frame(width: 20, height: 20)
            }
            .buttonStyle(.borderless)
            .disabled(value >= range.upperBound)
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 3)
        .background(Color.secondary.opacity(0.1))
        .cornerRadius(6)
    }

    private func increment() {
        if value + step <= range.upperBound {
            value += step
        }
    }

    private func decrement() {
        if value - step >= range.lowerBound {
            value -= step
        }
    }
}

#Preview {
    SettingsView(isExpanded: .constant(true))
        .frame(width: 280)
        .padding()
}
