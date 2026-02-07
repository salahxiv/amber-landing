import SwiftUI
import ServiceManagement

/// Erweiterbare Einstellungsansicht für Timer und Audio
struct SettingsView: View {
    @ObservedObject var settings = SettingsManager.shared
    @AppStorage(Constants.launchAtLoginKey) private var launchAtLogin = false
    @Binding var isExpanded: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header mit Expand/Collapse Toggle
            Button(action: { withAnimation(.easeInOut(duration: 0.2)) { isExpanded.toggle() } }) {
                HStack(spacing: 8) {
                    Image(systemName: "gearshape")
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                        .frame(width: 16)
                    Text("Einstellungen")
                        .font(.system(size: 13))
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(.secondary)
                        .rotationEffect(.degrees(isExpanded ? 90 : 0))
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            if isExpanded {
                VStack(alignment: .leading, spacing: 12) {
                    // Timer Einstellungen
                    timerSettingsSection

                    Divider()

                    // Sound Einstellungen
                    soundSettingsSection

                    Divider()

                    // Nicht stören Modus
                    dndSection

                    Divider()

                    // Kalender-Sync
                    calendarSection

                    Divider()

                    // Bei Login starten
                    launchAtLoginSection
                }
                .padding(.horizontal, 12)
                .padding(.bottom, 6)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .onChange(of: isExpanded) { _, _ in
            // Panel-Größe aktualisieren
            NotificationCenter.default.post(name: .settingsExpandedChanged, object: nil)
        }
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

    // MARK: - Nicht stören Modus

    private var dndSection: some View {
        Toggle(isOn: $settings.dndEnabled) {
            HStack {
                Image(systemName: "moon.fill")
                    .foregroundColor(.purple)
                    .frame(width: 20)
                Text("Nicht stören (Fullscreen)")
            }
        }
        .toggleStyle(.checkbox)
        .font(.subheadline)
        .help("Pausen automatisch überspringen wenn eine Fullscreen-App aktiv ist")
    }

    // MARK: - Kalender-Sync

    private var calendarSection: some View {
        Toggle(isOn: $settings.calendarSyncEnabled) {
            HStack {
                Image(systemName: "calendar")
                    .foregroundColor(.red)
                    .frame(width: 20)
                Text("Bei Terminen pausieren")
            }
        }
        .toggleStyle(.checkbox)
        .font(.subheadline)
        .onChange(of: settings.calendarSyncEnabled) { _, newValue in
            if newValue {
                Task {
                    let granted = await CalendarService.shared.requestAccess()
                    print("Kalender-Berechtigung: \(granted ? "Gewährt" : "Abgelehnt")")
                    // Toggle bleibt an - Benutzer kann in Systemeinstellungen Berechtigung erteilen
                }
            }
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
