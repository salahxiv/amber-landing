import Foundation
import UserNotifications

/// Service für macOS Benachrichtigungen
final class NotificationService {
    static let shared = NotificationService()

    private init() {}

    // MARK: - Permission

    /// Fordert Berechtigung für Benachrichtigungen an
    func requestPermission() async -> Bool {
        do {
            let granted = try await UNUserNotificationCenter.current()
                .requestAuthorization(options: [.alert, .sound])
            return granted
        } catch {
            print("Fehler bei Benachrichtigungs-Berechtigung: \(error)")
            return false
        }
    }

    /// Prüft ob Benachrichtigungen erlaubt sind
    func checkPermission() async -> Bool {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        return settings.authorizationStatus == .authorized
    }

    // MARK: - Notifications

    /// Sendet eine Benachrichtigung für Pausenbeginn
    func sendBreakNotification() {
        let content = UNMutableNotificationContent()
        content.title = "Zeit für eine Pause"
        content.body = "Schau für 20 Sekunden auf etwas 6 Meter entferntes."
        content.sound = .default

        let request = UNNotificationRequest(
            identifier: "breakReminder",
            content: content,
            trigger: nil // Sofort senden
        )

        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Fehler beim Senden der Benachrichtigung: \(error)")
            }
        }
    }

    /// Sendet eine Benachrichtigung für Pausenende
    func sendBreakEndedNotification() {
        let content = UNMutableNotificationContent()
        content.title = "Pause beendet"
        content.body = "Weiter geht's! Nächste Pause in 20 Minuten."
        content.sound = .default

        let request = UNNotificationRequest(
            identifier: "breakEnded",
            content: content,
            trigger: nil
        )

        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Fehler beim Senden der Benachrichtigung: \(error)")
            }
        }
    }

    /// Entfernt alle ausstehenden Benachrichtigungen
    func clearPendingNotifications() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }
}
