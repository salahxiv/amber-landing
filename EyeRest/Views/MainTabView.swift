#if os(iOS)
import SwiftUI
import StoreKit

/// Haupt-TabView für die iOS-App
struct MainTabView: View {
    @ObservedObject var viewModel: TimerViewModel
    @State private var settingsExpanded = true
    @State private var statisticsExpanded = true
    @State private var tipJarExpanded = true

    var body: some View {
        TabView {
            // Timer Tab
            timerTab
                .tabItem {
                    Label("Timer", systemImage: "timer")
                }

            // Statistiken Tab
            statisticsTab
                .tabItem {
                    Label("Statistiken", systemImage: "chart.bar.fill")
                }

            // Einstellungen Tab
            settingsTab
                .tabItem {
                    Label("Einstellungen", systemImage: "gearshape")
                }
        }
        .tint(.blue)
        .fullScreenCover(isPresented: $viewModel.showBreakOverlay) {
            BreakOverlayView(viewModel: viewModel)
        }
    }

    // MARK: - Timer Tab

    private var timerTab: some View {
        NavigationStack {
            VStack(spacing: 32) {
                Spacer()

                // Timer Display
                TimerDisplayView(
                    remainingTime: viewModel.formattedTime,
                    progress: viewModel.progress,
                    statusText: viewModel.statusText,
                    phase: viewModel.currentPhase
                )
                .frame(width: 200, height: 200)

                // Status Text
                Text(viewModel.statusText)
                    .font(.title3)
                    .foregroundColor(.secondary)

                // Control Buttons
                ControlButtonsView(viewModel: viewModel)

                Spacer()
            }
            .padding()
            .navigationTitle("EyeRest")
        }
    }

    // MARK: - Statistiken Tab

    private var statisticsTab: some View {
        NavigationStack {
            List {
                StatisticsContentView()
            }
            .navigationTitle("Statistiken")
        }
    }

    // MARK: - Einstellungen Tab

    private var settingsTab: some View {
        NavigationStack {
            List {
                SettingsContentView()

                // Tip Jar Section
                Section {
                    TipJarContentView()
                } header: {
                    Label("Tip Jar", systemImage: "heart.fill")
                }
            }
            .navigationTitle("Einstellungen")
        }
    }
}

// MARK: - Statistics Content (für iOS List)

/// Statistik-Inhalt für iOS List-Darstellung
struct StatisticsContentView: View {
    @ObservedObject private var statistics = StatisticsManager.shared

    var body: some View {
        Section("Heute") {
            HStack {
                Label("Pausen", systemImage: "checkmark.circle.fill")
                Spacer()
                Text("\(statistics.completedBreaksToday)")
                    .font(.system(.body, design: .rounded))
                    .fontWeight(.semibold)
            }

            if statistics.skippedBreaksToday > 0 {
                HStack {
                    Label("Übersprungen", systemImage: "forward.fill")
                    Spacer()
                    Text("\(statistics.skippedBreaksToday)")
                        .font(.system(.body, design: .rounded))
                        .fontWeight(.semibold)
                        .foregroundColor(.orange)
                }
            }
        }

        Section("Diese Woche") {
            HStack {
                Label("Pausen", systemImage: "calendar")
                Spacer()
                Text("\(statistics.completedBreaksThisWeek)")
                    .font(.system(.body, design: .rounded))
                    .fontWeight(.semibold)
            }

            HStack {
                Label("Durchschnitt/Tag", systemImage: "chart.line.uptrend.xyaxis")
                Spacer()
                Text(String(format: "%.1f", statistics.averageBreaksPerDay))
                    .font(.system(.body, design: .rounded))
                    .fontWeight(.semibold)
            }
        }

        if statistics.currentStreak > 0 {
            Section("Serie") {
                HStack {
                    Label("Aktuelle Serie", systemImage: "flame.fill")
                        .foregroundColor(.orange)
                    Spacer()
                    Text("\(statistics.currentStreak) in Folge")
                        .font(.system(.body, design: .rounded))
                        .fontWeight(.semibold)
                        .foregroundColor(.orange)
                }
            }
        }
    }
}

// MARK: - Settings Content (für iOS List)

/// Einstellungs-Inhalt für iOS List-Darstellung
struct SettingsContentView: View {
    @ObservedObject var settings = SettingsManager.shared

    var body: some View {
        Section("Timer") {
            HStack {
                Label("Arbeitszeit", systemImage: "desktopcomputer")
                Spacer()
                TimeStepper(
                    value: $settings.workDuration,
                    range: 60...3600,
                    step: 60,
                    formatter: { "\($0 / 60) Min" }
                )
            }

            HStack {
                Label("Pausenzeit", systemImage: "eye")
                Spacer()
                TimeStepper(
                    value: $settings.restDuration,
                    range: 5...120,
                    step: 5,
                    formatter: { "\($0) Sek" }
                )
            }
        }

        Section("Audio") {
            Toggle(isOn: $settings.soundEnabled) {
                Label(
                    settings.soundEnabled ? "Ton bei Pausen" : "Ton bei Pausen",
                    systemImage: settings.soundEnabled ? "speaker.wave.2" : "speaker.slash"
                )
            }
        }

        Section("Kalender") {
            Toggle(isOn: $settings.calendarSyncEnabled) {
                Label("Bei Terminen pausieren", systemImage: "calendar")
            }
            .onChange(of: settings.calendarSyncEnabled) { _, newValue in
                if newValue {
                    Task {
                        let granted = await CalendarService.shared.requestAccess()
                        print("Kalender-Berechtigung: \(granted ? "Gewährt" : "Abgelehnt")")
                    }
                }
            }
        }
    }
}

// MARK: - Tip Jar Content (für iOS List)

/// Tip Jar Inhalt für iOS List-Darstellung
struct TipJarContentView: View {
    @ObservedObject private var tipJar = TipJarService.shared

    var body: some View {
        if tipJar.showThankYou {
            VStack(spacing: 8) {
                Image(systemName: "heart.circle.fill")
                    .font(.largeTitle)
                    .foregroundColor(.pink)
                Text("Vielen Dank!")
                    .font(.headline)
                Text("Deine Unterstützung bedeutet mir viel")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
        } else if tipJar.isLoading && tipJar.tips.isEmpty {
            ProgressView()
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
        } else if tipJar.tips.isEmpty {
            Text("Nicht verfügbar")
                .font(.caption)
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity)
        } else {
            ForEach(tipJar.tips, id: \.id) { product in
                Button {
                    Task {
                        await tipJar.purchase(product)
                    }
                } label: {
                    HStack {
                        Text(product.tipEmoji)
                            .font(.title3)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(product.tipDescription)
                                .font(.subheadline)
                                .fontWeight(.medium)
                        }
                        Spacer()
                        if tipJar.isLoading {
                            ProgressView()
                                .scaleEffect(0.7)
                        } else {
                            Text(product.displayPrice)
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundColor(.blue)
                        }
                    }
                }
                .disabled(tipJar.isLoading)
            }
        }

        if let error = tipJar.purchaseError {
            Text(error)
                .font(.caption)
                .foregroundColor(.red)
        }
    }
}

#Preview {
    MainTabView(viewModel: TimerViewModel())
}
#endif
