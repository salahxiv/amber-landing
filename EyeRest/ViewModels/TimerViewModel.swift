import Foundation
import Combine
import UserNotifications
#if os(macOS)
import AppKit
#else
import UIKit
#endif

/// Das Herzstück der App: Verwaltet den 20-20-20 Timer
final class TimerViewModel: ObservableObject {
    // MARK: - Published Properties

    @Published private(set) var state: TimerState = .initial
    @Published var showBreakOverlay: Bool = false

    // MARK: - Private Properties

    private var timer: AnyCancellable?
    private var cancellables = Set<AnyCancellable>()
    private let settings = SettingsManager.shared
    private let audioService = AudioService.shared
    #if os(macOS)
    private let dndService = DndService.shared
    private var isIdlePaused = false  // Timer wurde wegen Inaktivität pausiert
    #endif
    private let calendarService = CalendarService.shared
    #if os(iOS)
    private let widgetService = WidgetDataService.shared
    #endif

    // MARK: - Computed Properties

    var remainingSeconds: Int { state.remainingSeconds }
    var currentPhase: TimerPhase { state.phase }
    var isPaused: Bool { state.isPaused }
    var progress: Double { state.progress }
    var formattedTime: String { state.formattedTime }
    var statusText: String { state.statusText }

    var isRunning: Bool {
        state.phase != .idle && !state.isPaused
    }

    var canSkip: Bool {
        state.phase == .rest
    }

    // MARK: - Menu Bar Icon

    var menuBarIcon: String {
        switch state.phase {
        case .work:
            return state.isPaused ? "eye.slash" : "eye"
        case .rest:
            return "eye.fill"
        case .idle:
            return "eye"
        }
    }

    // MARK: - Initialization

    init() {
        setupNotifications()
        setupSettingsObserver()
    }

    deinit {
        timer?.cancel()
        cancellables.removeAll()
    }

    // MARK: - Private Methods

    private func setupNotifications() {
        #if os(macOS)
        // Reagiere auf System-Events (z.B. Aufwachen aus Schlaf)
        NSWorkspace.shared.notificationCenter
            .publisher(for: NSWorkspace.didWakeNotification)
            .sink { [weak self] _ in
                self?.handleSystemWake()
            }
            .store(in: &cancellables)
        #else
        // Reagiere auf App-Lifecycle-Events auf iOS
        NotificationCenter.default
            .publisher(for: UIApplication.didBecomeActiveNotification)
            .sink { [weak self] _ in
                self?.handleSystemWake()
            }
            .store(in: &cancellables)

        NotificationCenter.default
            .publisher(for: UIApplication.willResignActiveNotification)
            .sink { [weak self] _ in
                self?.handleBackgrounding()
            }
            .store(in: &cancellables)
        #endif
    }

    private func handleSystemWake() {
        // Bei Systemaufwachen: Timer-Status beibehalten
        // Optional: Timer zurücksetzen oder fortsetzen
    }

    #if os(iOS)
    private func handleBackgrounding() {
        guard state.phase != .idle, !state.isPaused else { return }

        // Bei Hintergrundwechsel: Local Notification schedulen
        if state.phase == .work {
            BackgroundTimerService.shared.scheduleBreakNotification(
                in: TimeInterval(state.remainingSeconds)
            )
        }

        // Widget mit aktuellem State aktualisieren
        let phase = state.phase == .work ? "work" : "rest"
        widgetService.updateTimerState(
            phase: phase,
            endDate: Date.now.addingTimeInterval(TimeInterval(state.remainingSeconds)),
            isPaused: false,
            remainingSeconds: state.remainingSeconds,
            workDuration: state.workDuration,
            restDuration: state.restDuration,
            statusText: state.statusText
        )
    }
    #endif

    private func setupSettingsObserver() {
        NotificationCenter.default.publisher(for: .settingsChanged)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.handleSettingsChanged()
            }
            .store(in: &cancellables)
    }

    private func handleSettingsChanged() {
        // Wenn Timer im Idle-Zustand ist, aktualisiere die Anzeige mit neuen Einstellungen
        if state.phase == .idle {
            state.remainingSeconds = settings.workDuration
            state.workDuration = settings.workDuration
            state.restDuration = settings.restDuration
        }
    }

    private func startTimer() {
        timer?.cancel()
        timer = Timer.publish(every: 1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.tick()
            }
    }

    private func stopTimer() {
        timer?.cancel()
        timer = nil
    }

    private func tick() {
        guard !state.isPaused else {
            #if os(macOS)
            // Idle-Pause automatisch aufheben wenn Benutzer zurückkehrt
            if isIdlePaused && settings.idleDetectionEnabled {
                let threshold = TimeInterval(settings.idleThreshold)
                if !dndService.isUserIdle(threshold: threshold) {
                    isIdlePaused = false
                    state.isPaused = false
                    // Arbeitsphase zurücksetzen da Benutzer bereits geruht hat
                    if state.phase == .work {
                        state.remainingSeconds = settings.workDuration
                    }
                }
            }
            #endif
            return
        }

        #if os(macOS)
        // Idle-Erkennung: Timer pausieren wenn Benutzer inaktiv
        if settings.idleDetectionEnabled && state.phase == .work {
            let threshold = TimeInterval(settings.idleThreshold)
            if dndService.isUserIdle(threshold: threshold) {
                isIdlePaused = true
                state.isPaused = true
                return
            }
        }
        #endif

        if state.remainingSeconds > 0 {
            // Smart Reminder: Vorab-Warnung vor Pausenbeginn
            if state.phase == .work
                && settings.preBreakWarningEnabled
                && SubscriptionManager.shared.isPro
                && state.remainingSeconds == settings.preBreakWarningSeconds {
                sendPreBreakWarning()
            }

            state.remainingSeconds -= 1
        } else {
            transitionToNextPhase()
        }
    }

    private func shouldSkipBreak() -> Bool {
        #if os(macOS)
        // Fullscreen-Apps Check
        if settings.dndEnabled && dndService.isFullscreenAppActive() {
            return true
        }
        #endif

        // Kalender-Termin Check
        if settings.calendarSyncEnabled && calendarService.isEventInProgress() {
            return true
        }

        return false
    }

    private func transitionToNextPhase() {
        switch state.phase {
        case .work:
            // DND-Check: Bei Fullscreen-App die Pause überspringen
            if shouldSkipBreak() {
                state.remainingSeconds = settings.workDuration
                return
            }

            // Wechsel zur Pausenphase
            state.phase = .rest
            state.remainingSeconds = settings.restDuration
            state.restDuration = settings.restDuration
            showBreakOverlay = true
            audioService.playBreakStartSound()
            NotificationCenter.default.post(name: .breakStarted, object: nil)
            CrossDeviceBreakService.shared.broadcastBreakStarted()

            #if os(iOS)
            let restEndDate = Date.now.addingTimeInterval(TimeInterval(settings.restDuration))
            if #available(iOS 16.2, *) {
                LiveActivityService.shared.updateActivity(
                    phase: "rest",
                    endDate: restEndDate,
                    isPaused: false,
                    remainingSeconds: settings.restDuration,
                    statusText: String(localized: "timer.status.takingBreak")
                )
            }
            widgetService.updateTimerState(
                phase: "rest",
                endDate: restEndDate,
                isPaused: false,
                remainingSeconds: settings.restDuration,
                workDuration: settings.workDuration,
                restDuration: settings.restDuration,
                statusText: String(localized: "timer.status.takingBreak")
            )
            #endif

        case .rest:
            // Wechsel zurück zur Arbeitsphase
            state.phase = .work
            state.remainingSeconds = settings.workDuration
            state.workDuration = settings.workDuration
            showBreakOverlay = false
            audioService.playBreakEndSound()
            NotificationCenter.default.post(name: .breakEnded, object: nil)
            AnalyticsService.shared.track("break_completed", with: ["duration": settings.restDuration])

            #if os(iOS)
            let newWorkEndDate = Date.now.addingTimeInterval(TimeInterval(settings.workDuration))
            if #available(iOS 16.2, *) {
                LiveActivityService.shared.updateActivity(
                    phase: "work",
                    endDate: newWorkEndDate,
                    isPaused: false,
                    remainingSeconds: settings.workDuration,
                    statusText: String(localized: "timer.status.working")
                )
            }
            widgetService.updateTimerState(
                phase: "work",
                endDate: newWorkEndDate,
                isPaused: false,
                remainingSeconds: settings.workDuration,
                workDuration: settings.workDuration,
                restDuration: settings.restDuration,
                statusText: String(localized: "timer.status.working")
            )
            #endif

        case .idle:
            break
        }
    }

    // MARK: - Public Methods

    /// Startet den Timer
    func start() {
        state.phase = .work
        state.remainingSeconds = settings.workDuration
        state.workDuration = settings.workDuration
        state.restDuration = settings.restDuration
        state.isPaused = false
        startTimer()
        AnalyticsService.shared.track("timer_started")

        #if os(iOS)
        let workEndDate = Date.now.addingTimeInterval(TimeInterval(settings.workDuration))
        if #available(iOS 16.2, *) {
            LiveActivityService.shared.startActivity(
                phase: "work",
                endDate: workEndDate,
                statusText: String(localized: "timer.status.working"),
                workMinutes: settings.workDuration / 60
            )
        }
        widgetService.updateTimerState(
            phase: "work",
            endDate: workEndDate,
            isPaused: false,
            remainingSeconds: settings.workDuration,
            workDuration: settings.workDuration,
            restDuration: settings.restDuration,
            statusText: String(localized: "timer.status.working")
        )
        #endif
    }

    /// Pausiert den Timer
    func pause() {
        state.isPaused = true
        AnalyticsService.shared.track("timer_paused")

        #if os(iOS)
        let phase = state.phase == .work ? "work" : "rest"
        let pauseEndDate = Date.now.addingTimeInterval(TimeInterval(state.remainingSeconds))
        if #available(iOS 16.2, *) {
            LiveActivityService.shared.updateActivity(
                phase: phase,
                endDate: pauseEndDate,
                isPaused: true,
                remainingSeconds: state.remainingSeconds,
                statusText: String(localized: "timer.status.paused")
            )
        }
        widgetService.updateTimerState(
            phase: phase,
            endDate: pauseEndDate,
            isPaused: true,
            remainingSeconds: state.remainingSeconds,
            workDuration: state.workDuration,
            restDuration: state.restDuration,
            statusText: String(localized: "timer.status.paused")
        )
        #endif
    }

    /// Setzt den pausierten Timer fort
    func resume() {
        state.isPaused = false
        AnalyticsService.shared.track("timer_resumed")

        #if os(iOS)
        let phase = state.phase == .work ? "work" : "rest"
        let resumeEndDate = Date.now.addingTimeInterval(TimeInterval(state.remainingSeconds))
        if #available(iOS 16.2, *) {
            LiveActivityService.shared.updateActivity(
                phase: phase,
                endDate: resumeEndDate,
                isPaused: false,
                remainingSeconds: state.remainingSeconds,
                statusText: state.statusText
            )
        }
        widgetService.updateTimerState(
            phase: phase,
            endDate: resumeEndDate,
            isPaused: false,
            remainingSeconds: state.remainingSeconds,
            workDuration: state.workDuration,
            restDuration: state.restDuration,
            statusText: state.statusText
        )
        #endif
    }

    /// Wechselt zwischen Pause und Fortsetzen
    func togglePause() {
        if state.phase == .idle {
            start()
        } else if state.isPaused {
            resume()
        } else {
            pause()
        }
    }

    /// Setzt den Timer zurück
    func reset() {
        stopTimer()
        state = .initial
        showBreakOverlay = false

        #if os(iOS)
        if #available(iOS 16.2, *) {
            LiveActivityService.shared.endActivity()
        }
        widgetService.resetToIdle()
        #endif
    }

    /// Überspringt die aktuelle Pause
    func skip() {
        guard state.phase == .rest else { return }
        // Strict Mode Safety-Net: Überspringen blockieren wenn aktiv
        if settings.strictModeEnabled && SubscriptionManager.shared.isPro {
            return
        }
        NotificationCenter.default.post(name: .breakSkipped, object: nil)
        AnalyticsService.shared.track("break_skipped")
        // transitionToNextPhase() aktualisiert die Live Activity automatisch (rest→work)
        transitionToNextPhase()
    }

    // MARK: - Smart Reminders

    private func sendPreBreakWarning() {
        let seconds = settings.preBreakWarningSeconds
        let timeText: String
        if seconds >= 120 {
            timeText = String(localized: "time.minutes \(seconds / 60)")
        } else if seconds >= 60 {
            timeText = String(localized: "time.oneMinute")
        } else {
            timeText = String(localized: "time.seconds \(seconds)")
        }

        let content = UNMutableNotificationContent()
        content.title = String(localized: "notification.breakIn \(timeText)")
        content.body = String(localized: "notification.getReady")
        content.sound = .default

        let request = UNNotificationRequest(
            identifier: "preBreakWarning",
            content: content,
            trigger: nil  // Sofort anzeigen
        )
        UNUserNotificationCenter.current().add(request)
    }

    /// Stoppt den Timer komplett
    func stop() {
        stopTimer()
        state.phase = .idle
        state.isPaused = false
        showBreakOverlay = false

        #if os(iOS)
        if #available(iOS 16.2, *) {
            LiveActivityService.shared.endActivity()
        }
        widgetService.resetToIdle()
        #endif
    }
}
