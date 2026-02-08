import Foundation

/// Synchronisiert Einstellungen über iCloud (NSUbiquitousKeyValueStore)
final class iCloudSyncService {
    static let shared = iCloudSyncService()

    private let store = NSUbiquitousKeyValueStore.default

    /// Callback bei externen Änderungen (Key, Value)
    var onExternalChange: ((String, Any?) -> Void)?

    private init() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleStoreChange(_:)),
            name: NSUbiquitousKeyValueStore.didChangeExternallyNotification,
            object: store
        )
        // Initiale Synchronisierung starten
        store.synchronize()
    }

    // MARK: - Schreiben

    func set(_ value: Int, forKey key: String) {
        store.set(Int64(value), forKey: key)
        store.synchronize()
    }

    func set(_ value: Bool, forKey key: String) {
        store.set(value, forKey: key)
        store.synchronize()
    }

    func set(_ value: String, forKey key: String) {
        store.set(value, forKey: key)
        store.synchronize()
    }

    func set(_ value: Double, forKey key: String) {
        store.set(value, forKey: key)
        store.synchronize()
    }

    // MARK: - Lesen

    func integer(forKey key: String) -> Int? {
        guard store.object(forKey: key) != nil else { return nil }
        return Int(store.longLong(forKey: key))
    }

    func bool(forKey key: String) -> Bool? {
        guard store.object(forKey: key) != nil else { return nil }
        return store.bool(forKey: key)
    }

    func string(forKey key: String) -> String? {
        return store.string(forKey: key)
    }

    func double(forKey key: String) -> Double? {
        guard store.object(forKey: key) != nil else { return nil }
        return store.double(forKey: key)
    }

    // MARK: - Externe Änderungen

    @objc private func handleStoreChange(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let reason = userInfo[NSUbiquitousKeyValueStoreChangeReasonKey] as? Int else { return }

        // Nur bei Server-Änderungen oder initialem Sync reagieren
        guard reason == NSUbiquitousKeyValueStoreServerChange ||
              reason == NSUbiquitousKeyValueStoreInitialSyncChange else { return }

        guard let changedKeys = userInfo[NSUbiquitousKeyValueStoreChangedKeysKey] as? [String] else { return }

        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            for key in changedKeys {
                let value = self.store.object(forKey: key)
                self.onExternalChange?(key, value)
            }
        }
    }
}
