import Foundation
import Combine
import AppKit

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
        // Reagiere auf System-Events (z.B. Aufwachen aus Schlaf)
        NSWorkspace.shared.notificationCenter
            .publisher(for: NSWorkspace.didWakeNotification)
            .sink { [weak self] _ in
                self?.handleSystemWake()
            }
            .store(in: &cancellables)
    }

    private func handleSystemWake() {
        // Bei Systemaufwachen: Timer-Status beibehalten
        // Optional: Timer zurücksetzen oder fortsetzen
    }

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
        guard !state.isPaused else { return }

        if state.remainingSeconds > 0 {
            state.remainingSeconds -= 1
        } else {
            transitionToNextPhase()
        }
    }

    private func transitionToNextPhase() {
        switch state.phase {
        case .work:
            // Wechsel zur Pausenphase
            state.phase = .rest
            state.remainingSeconds = settings.restDuration
            state.restDuration = settings.restDuration
            showBreakOverlay = true
            audioService.playBreakStartSound()
            NotificationCenter.default.post(name: .breakStarted, object: nil)

        case .rest:
            // Wechsel zurück zur Arbeitsphase
            state.phase = .work
            state.remainingSeconds = settings.workDuration
            state.workDuration = settings.workDuration
            showBreakOverlay = false
            audioService.playBreakEndSound()
            NotificationCenter.default.post(name: .breakEnded, object: nil)

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
    }

    /// Pausiert den Timer
    func pause() {
        state.isPaused = true
    }

    /// Setzt den pausierten Timer fort
    func resume() {
        state.isPaused = false
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
    }

    /// Überspringt die aktuelle Pause
    func skip() {
        guard state.phase == .rest else { return }
        NotificationCenter.default.post(name: .breakSkipped, object: nil)
        transitionToNextPhase()
    }

    /// Stoppt den Timer komplett
    func stop() {
        stopTimer()
        state.phase = .idle
        state.isPaused = false
        showBreakOverlay = false
    }
}
