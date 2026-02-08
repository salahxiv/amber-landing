import SwiftUI
#if os(macOS)
import ServiceManagement
#endif

/// Erweiterbare Einstellungsansicht für Timer und Audio
struct SettingsView: View {
    @ObservedObject var settings = SettingsManager.shared
    #if os(macOS)
    @AppStorage(Constants.launchAtLoginKey) private var launchAtLogin = false
    #endif
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
                    Text("settings.title")
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

                    // Strict Mode
                    strictModeSection

                    Divider()

                    // Overlay-Themes
                    themeSection

                    Divider()

                    // Smart Reminders
                    smartReminderSection

                    #if os(macOS)
                    Divider()

                    // Nicht stören Modus
                    dndSection

                    Divider()

                    // Idle-Erkennung
                    idleDetectionSection

                    Divider()

                    // Kalender-Sync
                    calendarSection

                    Divider()

                    // Menüleisten-Countdown
                    menuBarCountdownSection

                    Divider()

                    // Geräte-Sync
                    crossDeviceSyncSection

                    Divider()

                    // Bei Login starten
                    launchAtLoginSection
                    #else
                    Divider()

                    // Kalender-Sync (auch auf iOS verfügbar)
                    calendarSection

                    Divider()

                    // Geräte-Sync
                    crossDeviceSyncSection
                    #endif
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
            Text("settings.section.timer")
                .font(.caption)
                .foregroundColor(.secondary)

            // Arbeitszeit
            HStack {
                Image(systemName: "desktopcomputer")
                    .foregroundColor(.blue)
                    .frame(width: 20)
                Text("settings.workDuration")
                Spacer()
                TimeStepper(
                    value: $settings.workDuration,
                    range: 60...3600,
                    step: 60,
                    formatter: { String(localized: "settings.minutes \($0 / 60)") }
                )
            }
            .font(.subheadline)

            // Pausenzeit
            HStack {
                Image(systemName: "eye")
                    .foregroundColor(.green)
                    .frame(width: 20)
                Text("settings.restDuration")
                Spacer()
                TimeStepper(
                    value: $settings.restDuration,
                    range: 5...120,
                    step: 5,
                    formatter: { String(localized: "settings.seconds \($0)") }
                )
            }
            .font(.subheadline)
        }
    }

    // MARK: - Sound Einstellungen

    private var soundSettingsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("settings.section.audio")
                .font(.caption)
                .foregroundColor(.secondary)

            Toggle(isOn: $settings.soundEnabled) {
                HStack {
                    Image(systemName: settings.soundEnabled ? "speaker.wave.2" : "speaker.slash")
                        .foregroundColor(.secondary)
                        .frame(width: 20)
                    Text("settings.breakSound")
                }
            }
            #if os(macOS)
            .toggleStyle(.checkbox)
            #endif
            .font(.subheadline)

            // Custom Sounds (Pro)
            if settings.soundEnabled {
                if settings.isPro {
                    SoundPickerRow(
                        label: String(localized: "settings.breakStart"),
                        selection: $settings.breakStartSound,
                        sounds: AudioService.availableSounds
                    )
                    SoundPickerRow(
                        label: String(localized: "settings.breakEnd"),
                        selection: $settings.breakEndSound,
                        sounds: AudioService.availableSounds
                    )
                } else {
                    proLockedButton(icon: "speaker.wave.3.fill", title: String(localized: "settings.customSounds"))
                }
            }
        }
    }

    // MARK: - Strict Mode

    private var strictModeSection: some View {
        Group {
            if settings.isPro {
                Toggle(isOn: $settings.strictModeEnabled) {
                    HStack {
                        Image(systemName: "lock.shield.fill")
                            .foregroundColor(.red)
                            .frame(width: 20)
                        Text("settings.strictMode")
                    }
                }
                #if os(macOS)
                .toggleStyle(.checkbox)
                #endif
                .font(.subheadline)
            } else {
                proLockedButton(icon: "lock.shield.fill", title: String(localized: "settings.strictMode"))
            }
        }
    }

    // MARK: - Overlay-Themes

    private var themeSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("settings.section.overlayDesign")
                .font(.caption)
                .foregroundColor(.secondary)

            if settings.isPro {
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 8) {
                    ForEach(OverlayTheme.allCases) { theme in
                        ThemeCard(
                            theme: theme,
                            isSelected: settings.overlayTheme == theme.rawValue,
                            action: { settings.overlayTheme = theme.rawValue }
                        )
                    }
                }
            } else {
                proLockedButton(icon: "paintbrush.fill", title: String(localized: "settings.unlockThemes"))
            }
        }
    }

    // MARK: - Smart Reminders

    private var smartReminderSection: some View {
        Group {
            if settings.isPro {
                VStack(alignment: .leading, spacing: 6) {
                    Toggle(isOn: $settings.preBreakWarningEnabled) {
                        HStack {
                            Image(systemName: "bell.badge.fill")
                                .foregroundColor(.indigo)
                                .frame(width: 20)
                            Text("settings.preWarning")
                        }
                    }
                    #if os(macOS)
                    .toggleStyle(.checkbox)
                    #endif
                    .font(.subheadline)

                    if settings.preBreakWarningEnabled {
                        HStack {
                            Text("settings.warning")
                                .font(.caption)
                                .foregroundColor(.secondary)

                            Picker("", selection: $settings.preBreakWarningSeconds) {
                                Text("settings.30sec").tag(30)
                                Text("settings.1min").tag(60)
                                Text("settings.2min").tag(120)
                            }
                            .labelsHidden()
                            #if os(macOS)
                            .frame(width: 100)
                            #endif

                            Text("settings.before")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding(.leading, 28)
                    }
                }
            } else {
                proLockedButton(icon: "bell.badge.fill", title: String(localized: "settings.smartReminders"))
            }
        }
    }

    // MARK: - Nicht stören Modus

    #if os(macOS)
    private var dndSection: some View {
        Toggle(isOn: $settings.dndEnabled) {
            HStack {
                Image(systemName: "moon.fill")
                    .foregroundColor(.purple)
                    .frame(width: 20)
                Text("settings.dnd")
            }
        }
        .toggleStyle(.checkbox)
        .font(.subheadline)
        .help(String(localized: "settings.dnd.help"))
    }
    #endif

    // MARK: - Idle-Erkennung

    #if os(macOS)
    private var idleDetectionSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Toggle(isOn: $settings.idleDetectionEnabled) {
                HStack {
                    Image(systemName: "zzz")
                        .foregroundColor(.orange)
                        .frame(width: 20)
                    Text("settings.idleDetection")
                }
            }
            .toggleStyle(.checkbox)
            .font(.subheadline)
            .help(String(localized: "settings.idleDetection.help"))

            if settings.idleDetectionEnabled {
                HStack {
                    Text("settings.after")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    TimeStepper(
                        value: $settings.idleThreshold,
                        range: 60...1800,
                        step: 60,
                        formatter: { String(localized: "settings.minutes \($0 / 60)") }
                    )
                    Text("settings.inactivity")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.leading, 28)
            }
        }
    }
    #endif

    // MARK: - Kalender-Sync

    private var calendarSection: some View {
        Group {
            if settings.isPro {
                Toggle(isOn: $settings.calendarSyncEnabled) {
                    HStack {
                        Image(systemName: "calendar")
                            .foregroundColor(.red)
                            .frame(width: 20)
                        Text("settings.pauseDuringEvents")
                    }
                }
                #if os(macOS)
                .toggleStyle(.checkbox)
                #endif
                .font(.subheadline)
                .onChange(of: settings.calendarSyncEnabled) { _, newValue in
                    if newValue {
                        Task {
                            let granted = await CalendarService.shared.requestAccess()
                            print("Kalender-Berechtigung: \(granted ? "Gewährt" : "Abgelehnt")")
                        }
                    }
                }
            } else {
                proLockedButton(icon: "calendar", title: String(localized: "settings.pauseDuringEvents"))
            }
        }
    }

    // MARK: - Geräte-Sync

    private var crossDeviceSyncSection: some View {
        Group {
            if settings.isPro {
                Toggle(isOn: $settings.crossDeviceSyncEnabled) {
                    HStack {
                        Image(systemName: "arrow.triangle.2.circlepath")
                            .foregroundColor(.teal)
                            .frame(width: 20)
                        Text("settings.deviceSync")
                    }
                }
                #if os(macOS)
                .toggleStyle(.checkbox)
                #endif
                .font(.subheadline)
                .help(String(localized: "settings.deviceSync.help"))
            } else {
                proLockedButton(icon: "arrow.triangle.2.circlepath", title: String(localized: "settings.deviceSync"))
            }
        }
    }

    // MARK: - Menüleisten-Countdown

    #if os(macOS)
    private var menuBarCountdownSection: some View {
        Group {
            if settings.isPro {
                Toggle(isOn: $settings.showMenuBarCountdown) {
                    HStack {
                        Image(systemName: "timer")
                            .foregroundColor(.cyan)
                            .frame(width: 20)
                        Text("settings.menuBarCountdown")
                    }
                }
                .toggleStyle(.checkbox)
                .font(.subheadline)
                .help(String(localized: "settings.menuBarCountdown.help"))
            } else {
                proLockedButton(icon: "timer", title: String(localized: "settings.menuBarCountdown"))
            }
        }
    }
    #endif

    // MARK: - Bei Login starten

    #if os(macOS)
    private var launchAtLoginSection: some View {
        Toggle(isOn: $launchAtLogin) {
            HStack {
                Image(systemName: "power")
                    .foregroundColor(.secondary)
                    .frame(width: 20)
                Text("settings.launchAtLogin")
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
    #endif

    // MARK: - Pro Locked Helper (macOS)

    private func proLockedButton(icon: String, title: String) -> some View {
        Button {
            #if os(macOS)
            NotificationCenter.default.post(name: .closeMenuPanel, object: nil)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                PaywallWindowController.shared.show()
            }
            #endif
        } label: {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(.secondary)
                    .frame(width: 20)
                Text(title)
                Spacer()
                HStack(spacing: 3) {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 8))
                    Text("PRO")
                        .font(.system(size: 9, weight: .bold))
                }
                .foregroundColor(.yellow)
                .padding(.horizontal, 5)
                .padding(.vertical, 2)
                .background(Color.yellow.opacity(0.15))
                .cornerRadius(4)
            }
            .font(.subheadline)
        }
        .buttonStyle(.plain)
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
