#if os(macOS)
import AppKit
import SwiftUI
import Combine

final class AppDelegate: NSObject, NSApplicationDelegate {
    // MARK: - Properties

    private var statusItem: NSStatusItem?
    private var menuPanel: NSPanel?
    private var menuHostingView: NSHostingView<MenuBarView>?
    private var overlayWindows: [NSWindow] = []  // Multi-Monitor Support
    private var eventMonitor: Any?
    private var localEventMonitor: Any?

    private let timerViewModel = TimerViewModel()
    private let hotkeyService = HotkeyService.shared
    private var cancellables = Set<AnyCancellable>()

    // MARK: - App Lifecycle

    func applicationDidFinishLaunching(_ notification: Notification) {
        setupMenuBar()
        setupMenuPanel()
        setupOverlayWindows()
        setupHotkey()
        observeTimerState()
        observeSettingsExpanded()
        observeScreenChanges()

        // Statistiken initialisieren
        _ = StatisticsManager.shared
    }

    func applicationWillTerminate(_ notification: Notification) {
        timerViewModel.stop()
        stopEventMonitors()
        hotkeyService.unregister()
    }

    // MARK: - Menu Bar Setup

    private func setupMenuBar() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        if let button = statusItem?.button {
            button.image = NSImage(systemSymbolName: "eye", accessibilityDescription: "Augen")
            button.action = #selector(toggleMenu)
            button.target = self
        }
    }

    // MARK: - Menu Panel Setup

    private func setupMenuPanel() {
        // Erst die View erstellen um die ideale Größe zu berechnen
        let menuBarView = MenuBarView(viewModel: timerViewModel) { [weak self] in
            self?.quitApp()
        }
        let hostingView = NSHostingView(rootView: menuBarView)
        let fittingSize = hostingView.fittingSize

        let panel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: fittingSize.width, height: fittingSize.height),
            styleMask: [.borderless, .nonactivatingPanel, .hudWindow],
            backing: .buffered,
            defer: false
        )

        // Konfiguration für Vollbild-Kompatibilität
        panel.level = .mainMenu + 1
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = true
        panel.hidesOnDeactivate = false
        panel.worksWhenModal = true
        panel.becomesKeyOnlyIfNeeded = true

        // Visual Effect Hintergrund
        let visualEffect = NSVisualEffectView(frame: NSRect(x: 0, y: 0, width: fittingSize.width, height: fittingSize.height))
        visualEffect.material = .popover
        visualEffect.blendingMode = .behindWindow
        visualEffect.state = .active
        visualEffect.wantsLayer = true
        visualEffect.layer?.cornerRadius = 10
        visualEffect.layer?.masksToBounds = true
        visualEffect.autoresizingMask = [.width, .height]

        panel.contentView = visualEffect

        hostingView.frame = visualEffect.bounds
        hostingView.autoresizingMask = [.width, .height]

        visualEffect.addSubview(hostingView)

        self.menuPanel = panel
        self.menuHostingView = hostingView
    }

    // MARK: - Overlay Windows Setup (Multi-Monitor)

    private func setupOverlayWindows() {
        // Bestehende Windows entfernen
        overlayWindows.forEach { $0.orderOut(nil) }
        overlayWindows.removeAll()

        // Für jeden Bildschirm ein Overlay-Window erstellen
        for screen in NSScreen.screens {
            let window = createOverlayWindow(for: screen)
            overlayWindows.append(window)
        }
    }

    private func createOverlayWindow(for screen: NSScreen) -> NSWindow {
        // NSPanel für bessere Vollbild-Kompatibilität
        let window = NSPanel(
            contentRect: screen.frame,
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )

        // Gleiche Konfiguration wie menuPanel für Vollbild-Support
        window.level = .mainMenu + 2
        window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        window.backgroundColor = NSColor.black.withAlphaComponent(0.85)
        window.isOpaque = false
        window.hasShadow = false
        window.ignoresMouseEvents = false
        window.hidesOnDeactivate = false
        window.worksWhenModal = true

        let overlayView = BreakOverlayView(viewModel: timerViewModel)
        let hostingView = NSHostingView(rootView: overlayView)
        hostingView.frame = window.contentView?.bounds ?? .zero
        hostingView.autoresizingMask = [.width, .height]

        window.contentView?.addSubview(hostingView)

        return window
    }

    // MARK: - Hotkey Setup

    private func setupHotkey() {
        hotkeyService.register { [weak self] in
            self?.timerViewModel.togglePause()
        }
    }

    private func observeScreenChanges() {
        // Reagiere auf Änderungen der Bildschirmkonfiguration
        NotificationCenter.default.addObserver(
            forName: NSApplication.didChangeScreenParametersNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.setupOverlayWindows()
        }
    }

    // MARK: - State Observation

    private func observeTimerState() {
        timerViewModel.$showBreakOverlay
            .receive(on: DispatchQueue.main)
            .sink { [weak self] showOverlay in
                if showOverlay {
                    self?.showOverlay()
                } else {
                    self?.hideOverlay()
                }
            }
            .store(in: &cancellables)

        timerViewModel.$state
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.updateMenuBarIcon()
            }
            .store(in: &cancellables)
    }

    private func observeSettingsExpanded() {
        NotificationCenter.default.addObserver(
            forName: .settingsExpandedChanged,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.updatePanelSize()
        }

        // Beobachte Anfragen zum Schließen des Panels (z.B. für StoreKit)
        NotificationCenter.default.addObserver(
            forName: .closeMenuPanel,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.hideMenu()
        }
    }

    private func updatePanelSize() {
        guard let panel = menuPanel,
              menuHostingView != nil,
              panel.isVisible else { return }

        // Kleine Verzögerung für Animation
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) { [weak self] in
            guard let panel = self?.menuPanel,
                  let hostingView = self?.menuHostingView else { return }

            let newSize = hostingView.fittingSize
            let currentFrame = panel.frame

            // Neue Position berechnen (Panel wächst nach unten)
            let newOrigin = NSPoint(
                x: currentFrame.origin.x,
                y: currentFrame.origin.y + currentFrame.height - newSize.height
            )

            NSAnimationContext.runAnimationGroup { context in
                context.duration = 0.2
                context.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
                panel.animator().setFrame(
                    NSRect(origin: newOrigin, size: newSize),
                    display: true
                )
            }
        }
    }

    // MARK: - Menu Actions

    @objc private func toggleMenu() {
        guard let button = statusItem?.button,
              let panel = menuPanel else { return }

        if panel.isVisible {
            hideMenu()
        } else {
            showMenu(relativeTo: button)
        }
    }

    private func showMenu(relativeTo button: NSStatusBarButton) {
        guard let panel = menuPanel,
              let hostingView = menuHostingView else { return }

        // Größe neu berechnen basierend auf aktuellem Inhalt
        let fittingSize = hostingView.fittingSize
        panel.setContentSize(fittingSize)

        // Position berechnen
        let buttonRect = button.window?.convertToScreen(button.convert(button.bounds, to: nil)) ?? .zero
        let panelOrigin = NSPoint(
            x: buttonRect.midX - panel.frame.width / 2,
            y: buttonRect.minY - panel.frame.height - 4
        )

        panel.setFrameOrigin(panelOrigin)
        panel.orderFrontRegardless()

        startEventMonitors()
    }

    private func hideMenu() {
        menuPanel?.orderOut(nil)
        stopEventMonitors()
    }

    private func updateMenuBarIcon() {
        if let button = statusItem?.button {
            let iconName = timerViewModel.menuBarIcon
            button.image = NSImage(systemSymbolName: iconName, accessibilityDescription: "Augen")
        }
    }

    // MARK: - Event Monitors

    private func startEventMonitors() {
        // Global: Klicks außerhalb der App
        eventMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] _ in
            self?.hideMenu()
        }

        // Lokal: Escape-Taste
        localEventMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            if event.keyCode == 53 { // Escape
                self?.hideMenu()
                return nil
            }
            return event
        }
    }

    private func stopEventMonitors() {
        if let monitor = eventMonitor {
            NSEvent.removeMonitor(monitor)
            eventMonitor = nil
        }
        if let monitor = localEventMonitor {
            NSEvent.removeMonitor(monitor)
            localEventMonitor = nil
        }
    }

    // MARK: - Overlay Actions (Multi-Monitor)

    private func showOverlay() {
        // Sicherstellen, dass für jeden Bildschirm ein Overlay existiert
        let screens = NSScreen.screens
        if overlayWindows.count != screens.count {
            setupOverlayWindows()
        }

        // Alle Overlays auf allen Bildschirmen anzeigen
        for (index, screen) in screens.enumerated() {
            guard index < overlayWindows.count else { continue }

            let window = overlayWindows[index]
            window.setFrame(screen.frame, display: true)

            if let contentView = window.contentView,
               let hostingView = contentView.subviews.first as? NSHostingView<BreakOverlayView> {
                hostingView.frame = contentView.bounds
            }

            window.orderFrontRegardless()
        }

        // Aktiviere die App und bringe das Hauptfenster nach vorne
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) { [weak self] in
            NSApp.activate(ignoringOtherApps: true)
            // Erstes Fenster als Key-Window setzen
            self?.overlayWindows.first?.makeKeyAndOrderFront(nil)
            // Alle Fenster nochmal nach vorne bringen
            self?.overlayWindows.forEach { $0.orderFrontRegardless() }
        }
    }

    private func hideOverlay() {
        // Alle Overlay-Fenster ausblenden
        overlayWindows.forEach { $0.orderOut(nil) }
    }

    // MARK: - App Actions

    private func quitApp() {
        NSApplication.shared.terminate(nil)
    }
}
#endif
