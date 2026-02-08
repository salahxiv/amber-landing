import WidgetKit
import SwiftUI

// MARK: - TimelineProvider

struct TimerWidgetProvider: TimelineProvider {
    func placeholder(in context: Context) -> TimerWidgetEntry {
        TimerWidgetEntry(date: .now, timerState: .idle)
    }

    func getSnapshot(in context: Context, completion: @escaping (TimerWidgetEntry) -> Void) {
        let state = readTimerState()
        completion(TimerWidgetEntry(date: .now, timerState: state))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<TimerWidgetEntry>) -> Void) {
        let state = readTimerState()
        let entry = TimerWidgetEntry(date: .now, timerState: state)

        let refreshDate: Date
        if state.phase == "idle" || state.isPaused {
            // Statisch: Refresh in 15 Minuten
            refreshDate = Calendar.current.date(byAdding: .minute, value: 15, to: .now) ?? .now.addingTimeInterval(900)
        } else if state.phase == "rest" {
            // Rest-Phase: Refresh nach Ablauf
            refreshDate = state.endDate.addingTimeInterval(1)
        } else {
            // Work-Phase: Refresh jede Minute
            refreshDate = Calendar.current.date(byAdding: .minute, value: 1, to: .now) ?? .now.addingTimeInterval(60)
        }

        let timeline = Timeline(entries: [entry], policy: .after(refreshDate))
        completion(timeline)
    }

    private func readTimerState() -> SharedTimerState {
        guard let defaults = UserDefaults(suiteName: AppGroupConstants.suiteName),
              let data = defaults.data(forKey: AppGroupConstants.sharedTimerStateKey),
              let state = try? JSONDecoder().decode(SharedTimerState.self, from: data) else {
            return .idle
        }
        // Veraltete aktive States zurücksetzen
        if state.phase != "idle" && !state.isPaused && state.endDate < .now {
            return .idle
        }
        return state
    }
}

// MARK: - Timeline Entry

struct TimerWidgetEntry: TimelineEntry {
    let date: Date
    let timerState: SharedTimerState
}

// MARK: - Widget Farb-Helfer

private func phaseGradient(for phase: String) -> LinearGradient {
    switch phase {
    case "work":
        return LinearGradient(
            colors: [Color(red: 0.06, green: 0.1, blue: 0.28), Color(red: 0.12, green: 0.22, blue: 0.55)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    case "rest":
        return LinearGradient(
            colors: [Color(red: 0.05, green: 0.18, blue: 0.12), Color(red: 0.1, green: 0.38, blue: 0.22)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    default:
        return LinearGradient(
            colors: [Color(red: 0.12, green: 0.12, blue: 0.14), Color(red: 0.22, green: 0.22, blue: 0.26)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

private func phaseAccentColor(for phase: String) -> Color {
    switch phase {
    case "work": return .cyan
    case "rest": return .green
    default: return .gray
    }
}

// MARK: - Small Widget View

struct TimerWidgetSmallView: View {
    let entry: TimerWidgetEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // App Name oben-links
            Text("EyeRest")
                .font(.caption2.bold())
                .foregroundColor(.white.opacity(0.7))

            Spacer()

            if entry.timerState.phase == "idle" {
                // Idle: Eye-Symbol + Bereit
                VStack(spacing: 8) {
                    Image(systemName: "eye")
                        .font(.system(size: 32))
                        .foregroundColor(.white.opacity(0.8))
                    Text("widget.ready")
                        .font(.headline)
                        .foregroundColor(.white)
                }
                .frame(maxWidth: .infinity)
            } else {
                // Active: Timer mittig
                VStack(spacing: 6) {
                    if !entry.timerState.isPaused {
                        Text(entry.timerState.endDate, style: .timer)
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .monospacedDigit()
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)
                    } else {
                        Text(formattedRemaining)
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .monospacedDigit()
                            .foregroundColor(.white.opacity(0.7))
                    }
                }
                .frame(maxWidth: .infinity)
            }

            Spacer()

            // Status + Mini Progress Bar
            VStack(spacing: 6) {
                Text(entry.timerState.statusText)
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.8))
                    .frame(maxWidth: .infinity, alignment: .leading)

                if entry.timerState.phase != "idle" {
                    // Mini Capsule Progress Bar
                    GeometryReader { geo in
                        Capsule()
                            .fill(.white.opacity(0.15))
                            .overlay(alignment: .leading) {
                                Capsule()
                                    .fill(phaseAccentColor(for: entry.timerState.phase))
                                    .frame(width: max(4, geo.size.width * progressValue))
                            }
                    }
                    .frame(height: 4)
                }
            }
        }
        .containerBackground(for: .widget) {
            phaseGradient(for: entry.timerState.phase)
        }
    }

    private var progressValue: CGFloat {
        if entry.timerState.isPaused {
            return CGFloat(entry.timerState.progress)
        }
        guard entry.timerState.endDate > .now else { return 1.0 }
        let total = entry.timerState.phase == "work"
            ? Double(entry.timerState.workDuration)
            : Double(entry.timerState.restDuration)
        guard total > 0 else { return 0 }
        let remaining = entry.timerState.endDate.timeIntervalSinceNow
        return CGFloat(max(0, min(1, (total - remaining) / total)))
    }

    private var formattedRemaining: String {
        let seconds = entry.timerState.remainingSeconds
        let min = seconds / 60
        let sec = seconds % 60
        return String(format: "%d:%02d", min, sec)
    }
}

// MARK: - Medium Widget View

struct TimerWidgetMediumView: View {
    let entry: TimerWidgetEntry

    var body: some View {
        HStack(spacing: 16) {
            // Custom Ring
            ZStack {
                Circle()
                    .stroke(.white.opacity(0.12), lineWidth: 6)

                if entry.timerState.phase != "idle" {
                    Circle()
                        .trim(from: 0, to: progressValue)
                        .stroke(
                            phaseAccentColor(for: entry.timerState.phase),
                            style: StrokeStyle(lineWidth: 6, lineCap: .round)
                        )
                        .rotationEffect(.degrees(-90))
                }

                Image(systemName: iconName)
                    .font(.title2)
                    .foregroundColor(.white.opacity(0.9))
            }
            .frame(width: 64, height: 64)

            VStack(alignment: .leading, spacing: 4) {
                Text("EyeRest")
                    .font(.caption2.bold())
                    .foregroundColor(.white.opacity(0.6))

                if entry.timerState.phase != "idle" && !entry.timerState.isPaused {
                    Text(entry.timerState.endDate, style: .timer)
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .monospacedDigit()
                        .foregroundColor(.white)
                } else if entry.timerState.isPaused {
                    Text(formattedRemaining)
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .monospacedDigit()
                        .foregroundColor(.white.opacity(0.7))
                } else {
                    Text("widget.ready")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                }

                Text(entry.timerState.statusText)
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.7))

                // Mini-Statistik
                HStack(spacing: 4) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.caption2)
                        .foregroundColor(phaseAccentColor(for: entry.timerState.phase))
                    Text("widget.todayBreaks \(entry.timerState.completedBreaksToday ?? 0)")
                        .font(.caption2)
                        .foregroundColor(.white.opacity(0.5))
                }
            }

            Spacer()
        }
        .containerBackground(for: .widget) {
            phaseGradient(for: entry.timerState.phase)
        }
    }

    private var progressValue: CGFloat {
        if entry.timerState.isPaused {
            return CGFloat(entry.timerState.progress)
        }
        guard entry.timerState.endDate > .now else { return 1.0 }
        let total = entry.timerState.phase == "work"
            ? Double(entry.timerState.workDuration)
            : Double(entry.timerState.restDuration)
        guard total > 0 else { return 0 }
        let remaining = entry.timerState.endDate.timeIntervalSinceNow
        return CGFloat(max(0, min(1, (total - remaining) / total)))
    }

    private var iconName: String {
        switch entry.timerState.phase {
        case "work": return entry.timerState.isPaused ? "eye.slash" : "eye"
        case "rest": return "eye.fill"
        default: return "eye"
        }
    }

    private var formattedRemaining: String {
        let seconds = entry.timerState.remainingSeconds
        let min = seconds / 60
        let sec = seconds % 60
        return String(format: "%d:%02d", min, sec)
    }
}

// MARK: - Widget Definition

struct EyeRestTimerWidget: Widget {
    let kind: String = "EyeRestTimerWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: TimerWidgetProvider()) { entry in
            TimerWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("EyeRest Timer")
        .description(String(localized: "widget.description"))
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

// MARK: - Widget View Auswahl per Family

struct TimerWidgetEntryView: View {
    @Environment(\.widgetFamily) var family
    let entry: TimerWidgetEntry

    var body: some View {
        switch family {
        case .systemMedium:
            TimerWidgetMediumView(entry: entry)
        default:
            TimerWidgetSmallView(entry: entry)
        }
    }
}
