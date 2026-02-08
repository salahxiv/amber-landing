import Foundation
import Combine

/// Definition aller verfügbaren Achievements
enum Achievement: String, CaseIterable, Identifiable {
    // Erste Schritte
    case firstBreak = "first_break"
    case fiveBreaks = "five_breaks"
    case twentyBreaks = "twenty_breaks"
    case hundredBreaks = "hundred_breaks"
    case fiveHundredBreaks = "five_hundred_breaks"

    // Streaks
    case threeDayStreak = "three_day_streak"
    case sevenDayStreak = "seven_day_streak"
    case fourteenDayStreak = "fourteen_day_streak"
    case thirtyDayStreak = "thirty_day_streak"

    // Disziplin
    case perfectDay = "perfect_day"         // 0 übersprungen an einem Tag mit >= 5 Pausen
    case perfectWeek = "perfect_week"       // 7 Tage in Folge ohne Skip

    var id: String { rawValue }

    var title: String {
        switch self {
        case .firstBreak: return String(localized: "achievement.firstBreak.title")
        case .fiveBreaks: return String(localized: "achievement.fiveBreaks.title")
        case .twentyBreaks: return String(localized: "achievement.twentyBreaks.title")
        case .hundredBreaks: return String(localized: "achievement.hundredBreaks.title")
        case .fiveHundredBreaks: return String(localized: "achievement.fiveHundredBreaks.title")
        case .threeDayStreak: return String(localized: "achievement.threeDayStreak.title")
        case .sevenDayStreak: return String(localized: "achievement.sevenDayStreak.title")
        case .fourteenDayStreak: return String(localized: "achievement.fourteenDayStreak.title")
        case .thirtyDayStreak: return String(localized: "achievement.thirtyDayStreak.title")
        case .perfectDay: return String(localized: "achievement.perfectDay.title")
        case .perfectWeek: return String(localized: "achievement.perfectWeek.title")
        }
    }

    var description: String {
        switch self {
        case .firstBreak: return String(localized: "achievement.firstBreak.description")
        case .fiveBreaks: return String(localized: "achievement.fiveBreaks.description")
        case .twentyBreaks: return String(localized: "achievement.twentyBreaks.description")
        case .hundredBreaks: return String(localized: "achievement.hundredBreaks.description")
        case .fiveHundredBreaks: return String(localized: "achievement.fiveHundredBreaks.description")
        case .threeDayStreak: return String(localized: "achievement.threeDayStreak.description")
        case .sevenDayStreak: return String(localized: "achievement.sevenDayStreak.description")
        case .fourteenDayStreak: return String(localized: "achievement.fourteenDayStreak.description")
        case .thirtyDayStreak: return String(localized: "achievement.thirtyDayStreak.description")
        case .perfectDay: return String(localized: "achievement.perfectDay.description")
        case .perfectWeek: return String(localized: "achievement.perfectWeek.description")
        }
    }

    var icon: String {
        switch self {
        case .firstBreak: return "star.fill"
        case .fiveBreaks: return "star.circle.fill"
        case .twentyBreaks: return "medal.fill"
        case .hundredBreaks: return "trophy.fill"
        case .fiveHundredBreaks: return "crown.fill"
        case .threeDayStreak: return "flame.fill"
        case .sevenDayStreak: return "flame.circle.fill"
        case .fourteenDayStreak: return "bolt.fill"
        case .thirtyDayStreak: return "bolt.circle.fill"
        case .perfectDay: return "checkmark.seal.fill"
        case .perfectWeek: return "checkmark.shield.fill"
        }
    }

    var color: String {
        switch self {
        case .firstBreak, .fiveBreaks: return "blue"
        case .twentyBreaks, .hundredBreaks, .fiveHundredBreaks: return "yellow"
        case .threeDayStreak, .sevenDayStreak: return "orange"
        case .fourteenDayStreak, .thirtyDayStreak: return "red"
        case .perfectDay, .perfectWeek: return "green"
        }
    }
}

/// Service der Achievements verwaltet und vergibt
@MainActor
final class AchievementService: ObservableObject {
    static let shared = AchievementService()

    // MARK: - Published

    @Published private(set) var unlockedAchievements: Set<String> = []
    @Published var newlyUnlocked: Achievement?

    // MARK: - Private

    private let userDefaultsKey = "unlockedAchievements"

    // MARK: - Computed

    var unlockedCount: Int { unlockedAchievements.count }
    var totalCount: Int { Achievement.allCases.count }

    func isUnlocked(_ achievement: Achievement) -> Bool {
        unlockedAchievements.contains(achievement.rawValue)
    }

    // MARK: - Init

    private init() {
        loadUnlocked()
        setupNotifications()
    }

    // MARK: - Check & Unlock

    /// Prüft alle Achievements basierend auf aktuellem Status
    func checkAchievements() {
        let stats = StatisticsManager.shared

        // Break-Count Achievements
        checkAndUnlock(.firstBreak, condition: stats.totalBreaks >= 1)
        checkAndUnlock(.fiveBreaks, condition: stats.totalBreaks >= 5)
        checkAndUnlock(.twentyBreaks, condition: stats.totalBreaks >= 20)
        checkAndUnlock(.hundredBreaks, condition: stats.totalBreaks >= 100)
        checkAndUnlock(.fiveHundredBreaks, condition: stats.totalBreaks >= 500)

        // Streak Achievements
        checkAndUnlock(.threeDayStreak, condition: stats.currentDayStreak >= 3)
        checkAndUnlock(.sevenDayStreak, condition: stats.currentDayStreak >= 7)
        checkAndUnlock(.fourteenDayStreak, condition: stats.currentDayStreak >= 14)
        checkAndUnlock(.thirtyDayStreak, condition: stats.currentDayStreak >= 30)

        // Perfect Day: >= 5 Pausen heute, 0 übersprungen
        let perfectDayCondition = stats.completedBreaksToday >= 5 && stats.skippedBreaksToday == 0
        checkAndUnlock(.perfectDay, condition: perfectDayCondition)

        // Perfect Week: 7-Tage-Streak und Abschlussrate >= 100%
        checkAndUnlock(.perfectWeek, condition: stats.currentDayStreak >= 7 && stats.completionRate >= 99.9)
    }

    private func checkAndUnlock(_ achievement: Achievement, condition: Bool) {
        guard condition, !isUnlocked(achievement) else { return }
        unlockedAchievements.insert(achievement.rawValue)
        saveUnlocked()
        newlyUnlocked = achievement
        AnalyticsService.shared.track("achievement_unlocked", with: ["achievement": achievement.rawValue])

        // Review-Prompt nach positivem Erlebnis (5 Pausen oder perfekter Tag)
        if achievement == .fiveBreaks || achievement == .perfectDay {
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                ReviewService.shared.requestReviewIfEligible()
            }
        }

        // Auto-dismiss nach 3 Sekunden
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) { [weak self] in
            if self?.newlyUnlocked == achievement {
                self?.newlyUnlocked = nil
            }
        }
    }

    // MARK: - Persistence

    private func loadUnlocked() {
        if let saved = UserDefaults.standard.array(forKey: userDefaultsKey) as? [String] {
            unlockedAchievements = Set(saved)
        }
    }

    private func saveUnlocked() {
        UserDefaults.standard.set(Array(unlockedAchievements), forKey: userDefaultsKey)
    }

    // MARK: - Notifications

    private func setupNotifications() {
        NotificationCenter.default.addObserver(
            forName: .statisticsUpdated,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.checkAchievements()
            }
        }
    }
}
