import EventKit
import Foundation

/// Service zur Kalender-Integration - prüft ob gerade ein Termin läuft
final class CalendarService {
    static let shared = CalendarService()

    private let eventStore = EKEventStore()
    private var authorizationStatus: EKAuthorizationStatus {
        EKEventStore.authorizationStatus(for: .event)
    }

    private init() {}

    // MARK: - Authorization

    /// Fordert Kalender-Berechtigung an
    func requestAccess() async -> Bool {
        // Prüfe zuerst den aktuellen Status
        let status = EKEventStore.authorizationStatus(for: .event)
        print("Kalender-Status: \(status.rawValue)")

        // Wenn bereits autorisiert, return true
        #if os(macOS)
        if #available(macOS 14.0, *) {
            if status == .fullAccess { return true }
        } else {
            if status == .authorized { return true }
        }
        #else
        if #available(iOS 17.0, *) {
            if status == .fullAccess { return true }
        } else {
            if status == .authorized { return true }
        }
        #endif

        // Berechtigung anfordern
        do {
            #if os(macOS)
            if #available(macOS 14.0, *) {
                let result = try await eventStore.requestFullAccessToEvents()
                print("Kalender requestFullAccess Result: \(result)")
                return result
            } else {
                let result = try await eventStore.requestAccess(to: .event)
                print("Kalender requestAccess Result: \(result)")
                return result
            }
            #else
            if #available(iOS 17.0, *) {
                let result = try await eventStore.requestFullAccessToEvents()
                print("Kalender requestFullAccess Result: \(result)")
                return result
            } else {
                let result = try await eventStore.requestAccess(to: .event)
                print("Kalender requestAccess Result: \(result)")
                return result
            }
            #endif
        } catch {
            print("Kalender-Zugriff fehlgeschlagen: \(error)")
            return true
        }
    }

    /// Prüft ob Kalender-Zugriff gewährt wurde
    var hasAccess: Bool {
        #if os(macOS)
        if #available(macOS 14.0, *) {
            return authorizationStatus == .fullAccess
        } else {
            return authorizationStatus == .authorized
        }
        #else
        if #available(iOS 17.0, *) {
            return authorizationStatus == .fullAccess
        } else {
            return authorizationStatus == .authorized
        }
        #endif
    }

    // MARK: - Event Check

    /// Prüft ob gerade ein Kalendertermin läuft
    func isEventInProgress() -> Bool {
        guard hasAccess else { return false }

        let now = Date()
        let calendars = eventStore.calendars(for: .event)

        // Nur Kalender mit Events berücksichtigen
        let predicate = eventStore.predicateForEvents(
            withStart: now.addingTimeInterval(-60), // 1 Minute Puffer
            end: now.addingTimeInterval(60),
            calendars: calendars
        )

        let events = eventStore.events(matching: predicate)

        // Prüfen ob ein Event gerade aktiv ist
        for event in events {
            // Ganztägige Events ignorieren
            if event.isAllDay { continue }

            // Abgelehnte Events ignorieren
            if event.status == .canceled { continue }

            // Prüfen ob Event gerade läuft
            if event.startDate <= now && event.endDate > now {
                return true
            }
        }

        return false
    }

    /// Gibt den Namen des aktuellen Termins zurück (für Debug/UI)
    func currentEventTitle() -> String? {
        guard hasAccess else { return nil }

        let now = Date()
        let calendars = eventStore.calendars(for: .event)

        let predicate = eventStore.predicateForEvents(
            withStart: now.addingTimeInterval(-60),
            end: now.addingTimeInterval(60),
            calendars: calendars
        )

        let events = eventStore.events(matching: predicate)

        for event in events {
            if event.isAllDay { continue }
            if event.status == .canceled { continue }

            if event.startDate <= now && event.endDate > now {
                return event.title
            }
        }

        return nil
    }
}
