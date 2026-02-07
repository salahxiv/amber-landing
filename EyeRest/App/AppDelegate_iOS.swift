#if os(iOS)
import UIKit
import UserNotifications

/// iOS App Delegate für Background Notification Handling
final class AppDelegate_iOS: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        // Notification Delegate setzen für Foreground-Benachrichtigungen
        UNUserNotificationCenter.current().delegate = self

        // Notification-Berechtigung anfordern
        Task {
            _ = await NotificationService.shared.requestPermission()
        }

        // Statistiken initialisieren
        _ = StatisticsManager.shared

        return true
    }

    // MARK: - UNUserNotificationCenterDelegate

    /// Benachrichtigung im Vordergrund anzeigen
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .sound])
    }

    /// Auf Benachrichtigungs-Aktionen reagieren
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let actionIdentifier = response.actionIdentifier

        if actionIdentifier == "SKIP_BREAK" {
            NotificationCenter.default.post(name: .breakSkipped, object: nil)
        }

        completionHandler()
    }
}
#endif
