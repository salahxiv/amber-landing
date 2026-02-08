import Foundation
import Combine
import SwiftData

/// Manager für Pausen-Statistiken
/// Nutzt SwiftData für performante Langzeit-Speicherung
@MainActor
final class StatisticsManager: ObservableObject {
    static let shared = StatisticsManager()

    // MARK: - SwiftData

    let modelContainer: ModelContainer
    private var modelContext: ModelContext

    // MARK: - Published Properties

    @Published private(set) var completedBreaksToday: Int = 0
    @Published private(set) var skippedBreaksToday: Int = 0
    @Published private(set) var completedBreaksThisWeek: Int = 0
    @Published private(set) var averageBreaksPerDay: Double = 0
    @Published private(set) var completionRate: Double = 100
    @Published private(set) var totalBreaks: Int = 0

    // Streaks
    @Published private(set) var currentDayStreak: Int = 0
    @Published private(set) var longestDayStreak: Int = 0
    @Published private(set) var currentSessionStreak: Int = 0

    // MARK: - Initialization

    private init() {
        do {
            let schema = Schema([BreakSession.self])
            let config = ModelConfiguration(isStoredInMemoryOnly: false)
            self.modelContainer = try ModelContainer(for: schema, configurations: [config])
            self.modelContext = modelContainer.mainContext
        } catch {
            fatalError("SwiftData ModelContainer konnte nicht erstellt werden: \(error)")
        }

        migrateFromUserDefaults()
        refreshStatistics()
        setupNotifications()
    }

    // MARK: - Public Methods

    /// Zeichnet eine Pause auf
    func recordBreak(completed: Bool, duration: Int = 20) {
        let session = BreakSession(completed: completed, durationSeconds: duration)
        modelContext.insert(session)
        try? modelContext.save()

        refreshStatistics()
        NotificationCenter.default.post(name: .statisticsUpdated, object: nil)
    }

    /// Alle Sessions für ein bestimmtes Datum
    func sessionsForDate(_ date: Date) -> [BreakSession] {
        let calendar = Calendar.current
        let start = calendar.startOfDay(for: date)
        guard let end = calendar.date(byAdding: .day, value: 1, to: start) else { return [] }

        let predicate = #Predicate<BreakSession> { session in
            session.date >= start && session.date < end
        }
        let descriptor = FetchDescriptor<BreakSession>(
            predicate: predicate,
            sortBy: [SortDescriptor(\.date)]
        )
        return (try? modelContext.fetch(descriptor)) ?? []
    }

    /// Alle Sessions im Zeitraum
    func sessions(from startDate: Date, to endDate: Date) -> [BreakSession] {
        let predicate = #Predicate<BreakSession> { session in
            session.date >= startDate && session.date < endDate
        }
        let descriptor = FetchDescriptor<BreakSession>(
            predicate: predicate,
            sortBy: [SortDescriptor(\.date)]
        )
        return (try? modelContext.fetch(descriptor)) ?? []
    }

    // MARK: - Erweiterte Statistiken (Pro)

    /// Pausen pro Tag der letzten 7 Tage
    func breaksPerDayLastWeek() -> [(date: Date, completed: Int, skipped: Int)] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        var result: [(date: Date, completed: Int, skipped: Int)] = []

        for dayOffset in (0..<7).reversed() {
            guard let date = calendar.date(byAdding: .day, value: -dayOffset, to: today) else { continue }
            let daySessions = sessionsForDate(date)
            let completed = daySessions.filter(\.completed).count
            let skipped = daySessions.filter { !$0.completed }.count
            result.append((date: date, completed: completed, skipped: skipped))
        }
        return result
    }

    /// Bester und schlechtester Tag (letzte 30 Tage)
    func bestAndWorstDay() -> (best: (date: Date, count: Int)?, worst: (date: Date, count: Int)?) {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        guard let monthAgo = calendar.date(byAdding: .day, value: -30, to: today) else {
            return (nil, nil)
        }

        let allSessions = sessions(from: monthAgo, to: Date())
        let grouped = Dictionary(grouping: allSessions) { calendar.startOfDay(for: $0.date) }

        var best: (date: Date, count: Int)?
        var worst: (date: Date, count: Int)?

        for (date, sessions) in grouped {
            let completedCount = sessions.filter(\.completed).count
            if completedCount == 0 { continue }
            if best == nil || completedCount > best!.count {
                best = (date: date, count: completedCount)
            }
            if worst == nil || completedCount < worst!.count {
                worst = (date: date, count: completedCount)
            }
        }

        return (best, worst)
    }

    /// Gesamte Ruhezeit in Minuten
    var totalRestMinutes: Double {
        let completedPredicate = #Predicate<BreakSession> { $0.completed }
        let descriptor = FetchDescriptor<BreakSession>(predicate: completedPredicate)
        guard let sessions = try? modelContext.fetch(descriptor) else { return 0 }
        let totalSeconds = sessions.reduce(0) { $0 + $1.durationSeconds }
        return Double(totalSeconds) / 60.0
    }

    /// Löscht alle Statistiken
    func clearAllRecords() {
        try? modelContext.delete(model: BreakSession.self)
        try? modelContext.save()
        refreshStatistics()
        NotificationCenter.default.post(name: .statisticsUpdated, object: nil)
    }

    // MARK: - Statistics Refresh

    func refreshStatistics() {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        // Heute
        let todaySessions = sessionsForDate(Date())
        completedBreaksToday = todaySessions.filter(\.completed).count
        skippedBreaksToday = todaySessions.filter { !$0.completed }.count

        // Diese Woche
        guard let weekAgo = calendar.date(byAdding: .day, value: -7, to: Date()) else { return }
        let weekSessions = sessions(from: weekAgo, to: Date())
        completedBreaksThisWeek = weekSessions.filter(\.completed).count

        // Durchschnitt pro Tag (letzte 7 Tage)
        if !weekSessions.isEmpty {
            let grouped = Dictionary(grouping: weekSessions) { session in
                calendar.startOfDay(for: session.date)
            }
            averageBreaksPerDay = Double(weekSessions.count) / Double(max(1, grouped.count))
        } else {
            averageBreaksPerDay = 0
        }

        // Gesamtanzahl
        let totalDescriptor = FetchDescriptor<BreakSession>()
        totalBreaks = (try? modelContext.fetchCount(totalDescriptor)) ?? 0

        // Abschlussrate
        if totalBreaks > 0 {
            let completedPredicate = #Predicate<BreakSession> { $0.completed }
            let completedDescriptor = FetchDescriptor<BreakSession>(predicate: completedPredicate)
            let completedCount = (try? modelContext.fetchCount(completedDescriptor)) ?? 0
            completionRate = Double(completedCount) / Double(totalBreaks) * 100
        } else {
            completionRate = 100
        }

        // Streaks
        calculateStreaks(today: today)
    }

    // MARK: - Streak-Berechnung

    /// Berechnet Tage-in-Folge-Streaks (robuster als Session-Streaks)
    private func calculateStreaks(today: Date) {
        let calendar = Calendar.current

        // Session-Streak (aufeinanderfolgende abgeschlossene Pausen heute)
        let todaySessions = sessionsForDate(Date())
        var sessionStreak = 0
        for session in todaySessions.reversed() {
            if session.completed { sessionStreak += 1 }
            else { break }
        }
        currentSessionStreak = sessionStreak

        // Day-Streak: Zähle aufeinanderfolgende Tage mit mindestens 1 abgeschlossenen Pause
        var dayStreak = 0
        var checkDate = today

        // Prüfe ob heute mindestens 1 Pause abgeschlossen wurde
        let todayCompleted = todaySessions.contains(where: \.completed)
        if !todayCompleted {
            // Prüfe gestern - vielleicht hat der User heute noch nicht pausiert
            guard let yesterday = calendar.date(byAdding: .day, value: -1, to: today) else {
                currentDayStreak = 0
                longestDayStreak = max(longestDayStreak, 0)
                return
            }
            let yesterdaySessions = sessionsForDate(yesterday)
            if !yesterdaySessions.contains(where: \.completed) {
                currentDayStreak = 0
                calculateLongestStreak()
                return
            }
            checkDate = yesterday
        }

        // Zähle rückwärts ab checkDate
        while true {
            let daySessions = sessionsForDate(checkDate)
            if daySessions.contains(where: \.completed) {
                dayStreak += 1
                guard let prevDay = calendar.date(byAdding: .day, value: -1, to: checkDate) else { break }
                checkDate = prevDay
            } else {
                break
            }
        }

        currentDayStreak = dayStreak
        calculateLongestStreak()
    }

    /// Berechnet den längsten jemals erreichten Day-Streak
    private func calculateLongestStreak() {
        let calendar = Calendar.current

        // Hole alle Tage mit abgeschlossenen Pausen
        let completedPredicate = #Predicate<BreakSession> { $0.completed }
        let descriptor = FetchDescriptor<BreakSession>(
            predicate: completedPredicate,
            sortBy: [SortDescriptor(\.date)]
        )
        guard let allCompleted = try? modelContext.fetch(descriptor), !allCompleted.isEmpty else {
            longestDayStreak = max(longestDayStreak, currentDayStreak)
            return
        }

        // Unique Tage extrahieren
        var uniqueDays = Set<Date>()
        for session in allCompleted {
            uniqueDays.insert(calendar.startOfDay(for: session.date))
        }
        let sortedDays = uniqueDays.sorted()

        // Längsten Streak finden
        var longest = 1
        var current = 1

        for i in 1..<sortedDays.count {
            let diff = calendar.dateComponents([.day], from: sortedDays[i-1], to: sortedDays[i]).day ?? 0
            if diff == 1 {
                current += 1
                longest = max(longest, current)
            } else {
                current = 1
            }
        }

        longestDayStreak = max(longest, currentDayStreak)
    }

    // MARK: - Migration

    /// Migriert alte BreakRecord-Daten aus UserDefaults nach SwiftData
    private func migrateFromUserDefaults() {
        let key = "breakStatistics"
        guard let data = UserDefaults.standard.data(forKey: key) else { return }

        struct LegacyBreakRecord: Codable {
            let id: UUID
            let date: Date
            let completed: Bool
        }

        guard let legacyRecords = try? JSONDecoder().decode([LegacyBreakRecord].self, from: data) else {
            return
        }

        // Prüfe ob bereits migriert
        let descriptor = FetchDescriptor<BreakSession>()
        let existingCount = (try? modelContext.fetchCount(descriptor)) ?? 0
        if existingCount > 0 { return }

        // Migriere
        for record in legacyRecords {
            let session = BreakSession(completed: record.completed)
            session.date = record.date
            modelContext.insert(session)
        }
        try? modelContext.save()

        // Alte Daten löschen
        UserDefaults.standard.removeObject(forKey: key)
    }

    // MARK: - Notifications

    private func setupNotifications() {
        NotificationCenter.default.addObserver(
            forName: .breakEnded,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.recordBreak(completed: true, duration: SettingsManager.shared.restDuration)
            }
        }

        NotificationCenter.default.addObserver(
            forName: .breakSkipped,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.recordBreak(completed: false)
            }
        }
    }
}

// MARK: - Legacy Compat

/// Behalte den alten Typ-Namen für Abwärtskompatibilität
typealias BreakRecord = BreakSession
