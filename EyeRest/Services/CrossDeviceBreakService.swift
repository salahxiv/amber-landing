import Foundation
import UserNotifications
#if os(macOS)
import AppKit
#else
import UIKit
#endif

/// Synchronisiert Break-Events über iCloud KVStore zwischen Geräten
final class CrossDeviceBreakService {
    static let shared = CrossDeviceBreakService()

    private let store = NSUbiquitousKeyValueStore.default
    private let deviceID: String
    private let deviceName: String
    private var lastReceivedTimestamp: TimeInterval = 0

    private init() {
        // Device-ID generieren/laden (lokal, nicht iCloud)
        if let existingID = UserDefaults.standard.string(forKey: Constants.localDeviceIDKey) {
            self.deviceID = existingID
        } else {
            let newID = UUID().uuidString
            UserDefaults.standard.set(newID, forKey: Constants.localDeviceIDKey)
            self.deviceID = newID
        }

        // Device-Name ermitteln
        #if os(macOS)
        self.deviceName = Host.current().localizedName ?? "Mac"
        #else
        self.deviceName = UIDevice.current.name
        #endif

        // Eigenen Observer für Cross-Device Break Events registrieren
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleStoreChange(_:)),
            name: NSUbiquitousKeyValueStore.didChangeExternallyNotification,
            object: store
        )
    }

    // MARK: - Broadcast

    /// Sendet ein Break-Event an andere Geräte über iCloud KVStore
    func broadcastBreakStarted() {
        guard SettingsManager.shared.crossDeviceSyncEnabled,
              SubscriptionManager.shared.isPro else { return }

        let timestamp = Date().timeIntervalSince1970
        store.set(timestamp, forKey: Constants.crossDeviceBreakTimestampKey)
        store.set(deviceID, forKey: Constants.crossDeviceBreakDeviceIDKey)
        store.set(deviceName, forKey: Constants.crossDeviceBreakDeviceNameKey)
        store.synchronize()
    }

    // MARK: - Receive

    @objc private func handleStoreChange(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let reason = userInfo[NSUbiquitousKeyValueStoreChangeReasonKey] as? Int else { return }

        guard reason == NSUbiquitousKeyValueStoreServerChange ||
              reason == NSUbiquitousKeyValueStoreInitialSyncChange else { return }

        guard let changedKeys = userInfo[NSUbiquitousKeyValueStoreChangedKeysKey] as? [String] else { return }

        // Nur auf Break-Timestamp-Änderungen reagieren
        guard changedKeys.contains(Constants.crossDeviceBreakTimestampKey) else { return }

        DispatchQueue.main.async { [weak self] in
            self?.handleBreakEvent()
        }
    }

    private func handleBreakEvent() {
        guard SettingsManager.shared.crossDeviceSyncEnabled,
              SubscriptionManager.shared.isPro else { return }

        // Sender-Daten lesen
        let timestamp = store.double(forKey: Constants.crossDeviceBreakTimestampKey)
        let senderDeviceID = store.string(forKey: Constants.crossDeviceBreakDeviceIDKey) ?? ""
        let senderDeviceName = store.string(forKey: Constants.crossDeviceBreakDeviceNameKey) ?? "Anderes Gerät"

        // Eigenes Event ignorieren
        guard senderDeviceID != deviceID else { return }

        // Altes Event ignorieren (>60 Sek)
        let age = Date().timeIntervalSince1970 - timestamp
        guard age < 60 else { return }

        // Doppelte Events ignorieren
        guard timestamp != lastReceivedTimestamp else { return }
        lastReceivedTimestamp = timestamp

        // Notification senden
        sendCrossDeviceNotification(deviceName: senderDeviceName)
        NotificationCenter.default.post(name: .crossDeviceBreakReceived, object: nil)
    }

    private func sendCrossDeviceNotification(deviceName: String) {
        let content = UNMutableNotificationContent()
        content.title = "Augenpause auf \(deviceName)"
        content.body = "Dein \(deviceName) macht gerade Pause — ruh auch hier deine Augen aus!"
        content.sound = .default

        let request = UNNotificationRequest(
            identifier: "crossDeviceBreak-\(Date().timeIntervalSince1970)",
            content: content,
            trigger: nil
        )
        UNUserNotificationCenter.current().add(request)
    }
}
