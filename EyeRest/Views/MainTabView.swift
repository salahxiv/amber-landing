#if os(iOS)
import SwiftUI
import StoreKit

/// Haupt-TabView für die iOS-App
struct MainTabView: View {
    @ObservedObject var viewModel: TimerViewModel
    @State private var settingsExpanded = true
    @State private var statisticsExpanded = true
    @State private var showPaywall = false

    var body: some View {
        TabView {
            // Timer Tab
            timerTab
                .tabItem {
                    Label("tab.timer", systemImage: "timer")
                }

            // Statistiken Tab
            statisticsTab
                .tabItem {
                    Label("tab.statistics", systemImage: "chart.bar.fill")
                }

            // Einstellungen Tab
            settingsTab
                .tabItem {
                    Label("tab.settings", systemImage: "gearshape")
                }
        }
        .tint(.blue)
        .fullScreenCover(isPresented: $viewModel.showBreakOverlay) {
            BreakOverlayView(viewModel: viewModel)
        }
        .sheet(isPresented: $showPaywall) {
            PaywallView()
        }
        .overlay(alignment: .top) {
            if let achievement = AchievementService.shared.newlyUnlocked {
                AchievementToast(achievement: achievement)
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .padding(.top, 60)
            }
        }
        .animation(.spring(duration: 0.4), value: AchievementService.shared.newlyUnlocked != nil)
        .onAppear {
            SettingsManager.shared.recordFirstLaunchIfNeeded()
            if SettingsManager.shared.shouldShowPaywallReminder() {
                SettingsManager.shared.markPaywallReminderShown()
                showPaywall = true
            }
        }
    }

    // MARK: - Timer Tab

    private var phaseLabel: String {
        switch viewModel.currentPhase {
        case .idle: return String(localized: "timer.status.ready")
        case .work: return viewModel.isPaused ? String(localized: "timer.status.paused") : String(localized: "timer.status.working")
        case .rest: return String(localized: "timer.status.takingBreak")
        }
    }

    private var phaseSubtitle: String {
        switch viewModel.currentPhase {
        case .idle: return String(localized: "timer.subtitle.idle")
        case .work:
            if viewModel.isPaused {
                return String(localized: "timer.subtitle.paused")
            }
            return String(localized: "timer.subtitle.working")
        case .rest: return String(localized: "timer.subtitle.rest")
        }
    }

    private var theme: OverlayTheme {
        SettingsManager.shared.currentTheme
    }

    private var phaseBackgroundGradient: LinearGradient {
        switch viewModel.currentPhase {
        case .idle:
            return LinearGradient(
                colors: [.clear, Color.blue.opacity(0.03)],
                startPoint: .top,
                endPoint: .bottom
            )
        case .work:
            return LinearGradient(
                colors: [.clear, Color.blue.opacity(0.06)],
                startPoint: .top,
                endPoint: .bottom
            )
        case .rest:
            return LinearGradient(
                colors: [.clear, theme.accentColor.opacity(0.06)],
                startPoint: .top,
                endPoint: .bottom
            )
        }
    }

    private var timerTab: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    Spacer()
                        .frame(height: 16)

                    // Phase Label
                    VStack(spacing: 6) {
                        Text(phaseLabel)
                            .font(.title2.bold())
                            .foregroundColor(.primary)

                        Text(phaseSubtitle)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }

                    // Hero Timer Ring
                    TimerDisplayView(
                        remainingTime: viewModel.formattedTime,
                        progress: viewModel.progress,
                        statusText: viewModel.statusText,
                        phase: viewModel.currentPhase,
                        size: 240
                    )
                    .padding(.vertical, 8)

                    // Control Buttons
                    ControlButtonsView(viewModel: viewModel)

                    // Achievement Hint Card
                    NextAchievementHintCard()
                        .padding(.top, 8)

                    Spacer()
                        .frame(height: 24)
                }
                .padding(.horizontal)
            }
            .background(phaseBackgroundGradient.ignoresSafeArea())
            .navigationTitle("EyeRest")
            .animation(.easeInOut(duration: 0.4), value: viewModel.currentPhase)
        }
    }

    // MARK: - Statistiken Tab

    private var statisticsTab: some View {
        NavigationStack {
            List {
                StatisticsContentView(showPaywall: $showPaywall)
            }
            .navigationTitle(String(localized: "tab.statistics"))
        }
    }

    // MARK: - Einstellungen Tab

    private var settingsTab: some View {
        NavigationStack {
            List {
                SettingsContentView(showPaywall: $showPaywall)

                // Pro Section
                if !SettingsManager.shared.isPro {
                    Section {
                        ProUpgradeButton(showPaywall: $showPaywall)
                    } header: {
                        Label("EyeRest Pro", systemImage: "crown.fill")
                    }
                }
            }
            .navigationTitle(String(localized: "tab.settings"))
        }
    }
}

// MARK: - Next Achievement Hint Card

/// Zeigt das nächste zu erreichende Achievement mit Fortschritt
struct NextAchievementHintCard: View {
    @ObservedObject private var achievementService = AchievementService.shared
    @ObservedObject private var statistics = StatisticsManager.shared

    private var nextAchievement: (achievement: Achievement, progress: Double, hint: String)? {
        // Finde das erste nicht-freigeschaltete Achievement und berechne Fortschritt
        let breakAchievements: [(Achievement, Int)] = [
            (.firstBreak, 1),
            (.fiveBreaks, 5),
            (.twentyBreaks, 20),
            (.hundredBreaks, 100),
            (.fiveHundredBreaks, 500)
        ]

        for (achievement, target) in breakAchievements {
            if !achievementService.isUnlocked(achievement) {
                let current = statistics.totalBreaks
                let progress = min(Double(current) / Double(target), 1.0)
                let remaining = max(target - current, 0)
                return (achievement, progress, String(localized: "hint.breaksRemaining \(remaining)"))
            }
        }

        let streakAchievements: [(Achievement, Int)] = [
            (.threeDayStreak, 3),
            (.sevenDayStreak, 7),
            (.fourteenDayStreak, 14),
            (.thirtyDayStreak, 30)
        ]

        for (achievement, target) in streakAchievements {
            if !achievementService.isUnlocked(achievement) {
                let current = statistics.currentDayStreak
                let progress = min(Double(current) / Double(target), 1.0)
                let remaining = max(target - current, 0)
                return (achievement, progress, String(localized: "hint.daysRemaining \(remaining)"))
            }
        }

        if !achievementService.isUnlocked(.perfectDay) {
            let todayBreaks = statistics.completedBreaksToday
            let progress = min(Double(todayBreaks) / 5.0, 1.0)
            let remaining = max(5 - todayBreaks, 0)
            return (.perfectDay, progress, String(localized: "hint.breaksNoSkip \(remaining)"))
        }

        return nil
    }

    var body: some View {
        if let next = nextAchievement {
            HStack(spacing: 12) {
                Image(systemName: next.achievement.icon)
                    .font(.title3)
                    .foregroundColor(achievementColor(next.achievement.color))
                    .frame(width: 36, height: 36)
                    .background(
                        Circle()
                            .fill(achievementColor(next.achievement.color).opacity(0.12))
                    )

                VStack(alignment: .leading, spacing: 4) {
                    Text(next.achievement.title)
                        .font(.subheadline.weight(.semibold))
                    Text(next.hint)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                // Mini Circular Progress
                ZStack {
                    Circle()
                        .stroke(Color.gray.opacity(0.15), lineWidth: 3)
                    Circle()
                        .trim(from: 0, to: next.progress)
                        .stroke(
                            achievementColor(next.achievement.color),
                            style: StrokeStyle(lineWidth: 3, lineCap: .round)
                        )
                        .rotationEffect(.degrees(-90))
                    Text("\(Int(next.progress * 100))%")
                        .font(.system(size: 9, weight: .bold, design: .rounded))
                        .foregroundColor(.secondary)
                }
                .frame(width: 36, height: 36)
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(.ultraThinMaterial)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(Color.primary.opacity(0.06), lineWidth: 1)
            )
        }
    }

    private func achievementColor(_ colorName: String) -> Color {
        switch colorName {
        case "blue": return .blue
        case "yellow": return .yellow
        case "orange": return .orange
        case "red": return .red
        case "green": return .green
        default: return .gray
        }
    }
}

// MARK: - Statistics Content (für iOS List)

/// Statistik-Inhalt für iOS List-Darstellung
struct StatisticsContentView: View {
    @ObservedObject private var statistics = StatisticsManager.shared
    @Binding var showPaywall: Bool

    var body: some View {
        Section(String(localized: "statistics.today")) {
            HStack {
                Label(String(localized: "statistics.breaks"), systemImage: "checkmark.circle.fill")
                Spacer()
                Text("\(statistics.completedBreaksToday)")
                    .font(.system(.body, design: .rounded))
                    .fontWeight(.semibold)
            }

            if statistics.skippedBreaksToday > 0 {
                HStack {
                    Label(String(localized: "statistics.skippedLabel"), systemImage: "forward.fill")
                    Spacer()
                    Text("\(statistics.skippedBreaksToday)")
                        .font(.system(.body, design: .rounded))
                        .fontWeight(.semibold)
                        .foregroundColor(.orange)
                }
            }
        }

        Section(String(localized: "statistics.thisWeek")) {
            HStack {
                Label(String(localized: "statistics.breaks"), systemImage: "calendar")
                Spacer()
                Text("\(statistics.completedBreaksThisWeek)")
                    .font(.system(.body, design: .rounded))
                    .fontWeight(.semibold)
            }

            HStack {
                Label(String(localized: "statistics.averagePerDay"), systemImage: "chart.line.uptrend.xyaxis")
                Spacer()
                Text(String(format: "%.1f", statistics.averageBreaksPerDay))
                    .font(.system(.body, design: .rounded))
                    .fontWeight(.semibold)
            }
        }

        if statistics.currentDayStreak > 0 || statistics.longestDayStreak > 1 {
            Section(String(localized: "statistics.streaks")) {
                if statistics.currentDayStreak > 0 {
                    HStack {
                        Label(String(localized: "statistics.currentDayStreak"), systemImage: "flame.fill")
                            .foregroundColor(.orange)
                        Spacer()
                        Text(String(localized: "statistics.daysCount \(statistics.currentDayStreak)"))
                            .font(.system(.body, design: .rounded))
                            .fontWeight(.semibold)
                            .foregroundColor(.orange)
                    }
                }

                if statistics.longestDayStreak > 1 {
                    HStack {
                        Label(String(localized: "statistics.longestStreak"), systemImage: "trophy.fill")
                            .foregroundColor(.yellow)
                        Spacer()
                        Text(String(localized: "statistics.daysCount \(statistics.longestDayStreak)"))
                            .font(.system(.body, design: .rounded))
                            .fontWeight(.semibold)
                    }
                }
            }
        }

        // Erweiterte Statistiken (Pro)
        if SettingsManager.shared.isPro {
            Section(String(localized: "statistics.weeklyReport")) {
                EnhancedStatisticsView()
            }
        } else {
            Section {
                ProLockedRow(
                    icon: "chart.bar.fill",
                    title: String(localized: "statistics.advancedStatistics"),
                    showPaywall: $showPaywall
                )
            } header: {
                Text("statistics.weeklyReport")
            }
        }

        // Achievements
        AchievementsSectionView()
    }
}

// MARK: - Settings Content (für iOS List)

/// Einstellungs-Inhalt für iOS List-Darstellung
struct SettingsContentView: View {
    @ObservedObject var settings = SettingsManager.shared
    @Binding var showPaywall: Bool

    var body: some View {
        Section(String(localized: "settings.section.timer")) {
            HStack {
                Label(String(localized: "settings.workDuration"), systemImage: "desktopcomputer")
                Spacer()
                TimeStepper(
                    value: $settings.workDuration,
                    range: 60...3600,
                    step: 60,
                    formatter: { String(localized: "settings.minutes \($0 / 60)") }
                )
            }

            HStack {
                Label(String(localized: "settings.restDuration"), systemImage: "eye")
                Spacer()
                TimeStepper(
                    value: $settings.restDuration,
                    range: 5...120,
                    step: 5,
                    formatter: { String(localized: "settings.seconds \($0)") }
                )
            }
        }

        Section(String(localized: "settings.section.audio")) {
            Toggle(isOn: $settings.soundEnabled) {
                Label(
                    String(localized: "settings.breakSound"),
                    systemImage: settings.soundEnabled ? "speaker.wave.2" : "speaker.slash"
                )
            }

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
                    ProLockedRow(
                        icon: "speaker.wave.3.fill",
                        title: String(localized: "settings.customSounds"),
                        showPaywall: $showPaywall
                    )
                }
            }
        }

        // Strict Mode
        Section(String(localized: "settings.section.discipline")) {
            if settings.isPro {
                Toggle(isOn: $settings.strictModeEnabled) {
                    Label(String(localized: "settings.strictMode"), systemImage: "lock.shield.fill")
                }
            } else {
                ProLockedRow(
                    icon: "lock.shield.fill",
                    title: String(localized: "settings.strictMode"),
                    showPaywall: $showPaywall
                )
            }
        }

        // Overlay-Themes
        Section(String(localized: "settings.section.overlayDesign")) {
            if settings.isPro {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(OverlayTheme.allCases) { theme in
                            ThemeCard(
                                theme: theme,
                                isSelected: settings.overlayTheme == theme.rawValue,
                                action: { settings.overlayTheme = theme.rawValue }
                            )
                            .frame(width: 100)
                        }
                    }
                    .padding(.vertical, 4)
                }
            } else {
                ProLockedRow(
                    icon: "paintbrush.fill",
                    title: String(localized: "settings.unlockThemes"),
                    showPaywall: $showPaywall
                )
            }
        }

        // Smart Reminders
        Section(String(localized: "settings.section.reminders")) {
            if settings.isPro {
                Toggle(isOn: $settings.preBreakWarningEnabled) {
                    Label(String(localized: "settings.preWarning"), systemImage: "bell.badge.fill")
                }

                if settings.preBreakWarningEnabled {
                    Picker(String(localized: "settings.warningBefore"), selection: $settings.preBreakWarningSeconds) {
                        Text("settings.30sec").tag(30)
                        Text("settings.1min").tag(60)
                        Text("settings.2min").tag(120)
                    }
                }
            } else {
                ProLockedRow(
                    icon: "bell.badge.fill",
                    title: String(localized: "settings.smartReminders"),
                    showPaywall: $showPaywall
                )
            }
        }

        Section(String(localized: "settings.section.calendar")) {
            if settings.isPro {
                Toggle(isOn: $settings.calendarSyncEnabled) {
                    Label(String(localized: "settings.pauseDuringEvents"), systemImage: "calendar")
                }
                .onChange(of: settings.calendarSyncEnabled) { _, newValue in
                    if newValue {
                        Task {
                            let granted = await CalendarService.shared.requestAccess()
                            print("Kalender-Berechtigung: \(granted ? "Gewährt" : "Abgelehnt")")
                        }
                    }
                }
            } else {
                ProLockedRow(
                    icon: "calendar",
                    title: String(localized: "settings.pauseDuringEvents"),
                    showPaywall: $showPaywall
                )
            }
        }

        Section(String(localized: "settings.section.deviceSync")) {
            if settings.isPro {
                Toggle(isOn: $settings.crossDeviceSyncEnabled) {
                    Label(String(localized: "settings.deviceSync"), systemImage: "arrow.triangle.2.circlepath")
                }

                if settings.crossDeviceSyncEnabled {
                    Text("settings.deviceSync.description")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            } else {
                ProLockedRow(
                    icon: "arrow.triangle.2.circlepath",
                    title: String(localized: "settings.deviceSync"),
                    showPaywall: $showPaywall
                )
            }
        }

        Section(String(localized: "settings.section.health")) {
            if HealthService.shared.isAvailable {
                Toggle(isOn: Binding(
                    get: { HealthService.shared.isEnabled },
                    set: { HealthService.shared.isEnabled = $0 }
                )) {
                    Label("Apple Health", systemImage: "heart.fill")
                }

                if HealthService.shared.isEnabled {
                    Text("settings.health.description")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
    }
}

// MARK: - Pro Upgrade Button (für iOS List)

/// Zeigt Upgrade-Button in den Einstellungen
struct ProUpgradeButton: View {
    @Binding var showPaywall: Bool

    var body: some View {
        Button {
            showPaywall = true
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "crown.fill")
                    .font(.title3)
                    .foregroundColor(.yellow)

                VStack(alignment: .leading, spacing: 2) {
                    Text("pro.upgrade")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    Text("pro.unlockAll")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
}

// MARK: - Pro Locked Row

/// Zeigt ein gesperrtes Pro-Feature mit Paywall-Trigger
struct ProLockedRow: View {
    let icon: String
    let title: String
    @Binding var showPaywall: Bool

    var body: some View {
        Button {
            showPaywall = true
        } label: {
            HStack {
                Label(title, systemImage: icon)
                Spacer()
                HStack(spacing: 4) {
                    Image(systemName: "lock.fill")
                        .font(.caption2)
                    Text("PRO")
                        .font(.caption2.bold())
                }
                .foregroundColor(.yellow)
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(Color.yellow.opacity(0.15))
                .cornerRadius(6)
            }
        }
        .foregroundColor(.primary)
    }
}

#Preview {
    MainTabView(viewModel: TimerViewModel())
}
#endif
