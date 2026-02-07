#if os(iOS)
import Foundation
import UserNotifications

/// Service für Background-Timer auf iOS
/// Schedulet Local Notifications wenn die App in den Hintergrund wechselt
final class BackgroundTimerService {
    static let shared = BackgroundTimerService()

    private let notificationCenter = UNUserNotificationCenter.current()

    private init() {
        registerNotificationCategories()
    }

    // MARK: - Notification Categories

    /// Registriert Notification-Kategorien mit Aktionen
    private func registerNotificationCategories() {
        let skipAction = UNNotificationAction(
            identifier: "SKIP_BREAK",
            title: "Überspringen",
            options: .destructive
        )

        let startBreakAction = UNNotificationAction(
            identifier: "START_BREAK",
            title: "Pause starten",
            options: .foreground
        )

        let breakCategory = UNNotificationCategory(
            identifier: "BREAK_REMINDER",
            actions: [startBreakAction, skipAction],
            intentIdentifiers: [],
            options: .customDismissAction
        )

        notificationCenter.setNotificationCategories([breakCategory])
    }

    // MARK: - Schedule Notifications

    /// Schedulet eine Break-Notification für wenn die Arbeitszeit abläuft
    func scheduleBreakNotification(in seconds: TimeInterval) {
        // Alte Notifications entfernen
        cancelScheduledNotifications()

        guard seconds > 0 else { return }

        let content = UNMutableNotificationContent()
        content.title = "Zeit für eine Pause"
        content.body = "Schau für 20 Sekunden auf etwas 6 Meter entferntes."
        content.sound = .default
        content.categoryIdentifier = "BREAK_REMINDER"

        let trigger = UNTimeIntervalNotificationTrigger(
            timeInterval: seconds,
            repeats: false
        )

        let request = UNNotificationRequest(
            identifier: "backgroundBreakReminder",
            content: content,
            trigger: trigger
        )

        notificationCenter.add(request) { error in
            if let error = error {
                print("BackgroundTimerService: Fehler beim Schedulen: \(error)")
            }
        }
    }

    /// Entfernt alle geplanten Break-Notifications
    func cancelScheduledNotifications() {
        notificationCenter.removePendingNotificationRequests(
            withIdentifiers: ["backgroundBreakReminder"]
        )
    }
}
#endif
