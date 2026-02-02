import Foundation
import Combine

/// Statistik-Eintrag für eine einzelne Pause
struct BreakRecord: Codable, Identifiable {
    let id: UUID
    let date: Date
    let completed: Bool  // true = Pause vollständig, false = übersprungen

    init(completed: Bool) {
        self.id = UUID()
        self.date = Date()
        self.completed = completed
    }
}

/// Manager für Pausen-Statistiken
/// Speichert Historie und berechnet Statistiken
final class StatisticsManager: ObservableObject {
    static let shared = StatisticsManager()

    // MARK: - Published Properties

    @Published private(set) var records: [BreakRecord] = []

    // MARK: - Private Properties

    private let userDefaultsKey = "breakStatistics"
    private let maxRecordsToKeep = 1000  // Begrenzung der gespeicherten Einträge

    // MARK: - Computed Properties

    /// Anzahl der Pausen heute
    var breaksToday: Int {
        recordsForDate(Date()).count
    }

    /// Anzahl der abgeschlossenen Pausen heute
    var completedBreaksToday: Int {
        recordsForDate(Date()).filter { $0.completed }.count
    }

    /// Anzahl der übersprungenen Pausen heute
    var skippedBreaksToday: Int {
        recordsForDate(Date()).filter { !$0.completed }.count
    }

    /// Anzahl der Pausen diese Woche
    var breaksThisWeek: Int {
        recordsForCurrentWeek().count
    }

    /// Anzahl der abgeschlossenen Pausen diese Woche
    var completedBreaksThisWeek: Int {
        recordsForCurrentWeek().filter { $0.completed }.count
    }

    /// Durchschnittliche Pausen pro Tag (letzte 7 Tage)
    var averageBreaksPerDay: Double {
        let weekRecords = recordsForCurrentWeek()
        guard !weekRecords.isEmpty else { return 0 }

        // Gruppiere nach Tag
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: weekRecords) { record in
            calendar.startOfDay(for: record.date)
        }

        return Double(weekRecords.count) / Double(max(1, grouped.count))
    }

    /// Abschlussrate (Prozent der nicht übersprungenen Pausen)
    var completionRate: Double {
        guard !records.isEmpty else { return 100 }
        let completed = records.filter { $0.completed }.count
        return Double(completed) / Double(records.count) * 100
    }

    /// Aktuelle Serie (aufeinanderfolgende abgeschlossene Pausen heute)
    var currentStreak: Int {
        let todayRecords = recordsForDate(Date()).reversed()
        var streak = 0

        for record in todayRecords {
            if record.completed {
                streak += 1
            } else {
                break
            }
        }

        return streak
    }

    // MARK: - Initialization

    private init() {
        loadRecords()
        setupNotifications()
    }

    // MARK: - Public Methods

    /// Fügt einen neuen Pausen-Eintrag hinzu
    func recordBreak(completed: Bool) {
        let record = BreakRecord(completed: completed)
        records.append(record)
        cleanupOldRecords()
        saveRecords()

        // Benachrichtigung senden
        NotificationCenter.default.post(name: .statisticsUpdated, object: nil)
    }

    /// Löscht alle Statistiken
    func clearAllRecords() {
        records.removeAll()
        saveRecords()
        NotificationCenter.default.post(name: .statisticsUpdated, object: nil)
    }

    /// Holt Statistiken für einen bestimmten Tag
    func recordsForDate(_ date: Date) -> [BreakRecord] {
        let calendar = Calendar.current
        return records.filter { calendar.isDate($0.date, inSameDayAs: date) }
    }

    // MARK: - Private Methods

    private func setupNotifications() {
        // Lausche auf Pausen-Events
        NotificationCenter.default.addObserver(
            forName: .breakEnded,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.recordBreak(completed: true)
        }

        NotificationCenter.default.addObserver(
            forName: .breakSkipped,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.recordBreak(completed: false)
        }
    }

    private func recordsForCurrentWeek() -> [BreakRecord] {
        let calendar = Calendar.current
        guard let weekAgo = calendar.date(byAdding: .day, value: -7, to: Date()) else {
            return []
        }

        return records.filter { $0.date >= weekAgo }
    }

    private func cleanupOldRecords() {
        // Behalte nur die letzten X Einträge
        if records.count > maxRecordsToKeep {
            records = Array(records.suffix(maxRecordsToKeep))
        }

        // Lösche Einträge älter als 30 Tage
        let calendar = Calendar.current
        guard let thirtyDaysAgo = calendar.date(byAdding: .day, value: -30, to: Date()) else {
            return
        }
        records = records.filter { $0.date >= thirtyDaysAgo }
    }

    private func loadRecords() {
        guard let data = UserDefaults.standard.data(forKey: userDefaultsKey),
              let decoded = try? JSONDecoder().decode([BreakRecord].self, from: data) else {
            return
        }
        records = decoded
    }

    private func saveRecords() {
        guard let encoded = try? JSONEncoder().encode(records) else { return }
        UserDefaults.standard.set(encoded, forKey: userDefaultsKey)
    }
}
