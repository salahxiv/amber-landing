import Foundation
import SwiftData

/// SwiftData Model für eine einzelne Pausen-Session
/// Ersetzt das alte BreakRecord struct (UserDefaults-basiert)
@Model
final class BreakSession {
    var date: Date
    var completed: Bool
    var durationSeconds: Int

    init(completed: Bool, durationSeconds: Int = 20) {
        self.date = Date()
        self.completed = completed
        self.durationSeconds = durationSeconds
    }
}
