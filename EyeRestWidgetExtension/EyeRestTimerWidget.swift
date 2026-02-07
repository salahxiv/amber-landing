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

// MARK: - Small Widget View

struct TimerWidgetSmallView: View {
    let entry: TimerWidgetEntry

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: iconName)
                .font(.title)
                .foregroundColor(phaseColor)

            if entry.timerState.phase != "idle" && !entry.timerState.isPaused {
                Text(entry.timerState.endDate, style: .timer)
                    .font(.title2.monospacedDigit())
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
            } else if entry.timerState.isPaused {
                Text(formattedRemaining)
                    .font(.title2.monospacedDigit())
                    .fontWeight(.bold)
            } else {
                Text("--:--")
                    .font(.title2.monospacedDigit())
                    .fontWeight(.bold)
                    .foregroundColor(.secondary)
            }

            Text(entry.timerState.statusText)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .containerBackground(.clear, for: .widget)
    }

    private var iconName: String {
        switch entry.timerState.phase {
        case "work": return entry.timerState.isPaused ? "eye.slash" : "eye"
        case "rest": return "eye.fill"
        default: return "eye"
        }
    }

    private var phaseColor: Color {
        switch entry.timerState.phase {
        case "work": return .blue
        case "rest": return .green
        default: return .secondary
        }
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
            // Fortschrittsring
            ZStack {
                if entry.timerState.phase != "idle" && !entry.timerState.isPaused && entry.timerState.endDate > .now {
                    ProgressView(
                        timerInterval: Date.now...entry.timerState.endDate,
                        countsDown: true
                    )
                    .progressViewStyle(.circular)
                    .tint(phaseColor)
                } else {
                    Circle()
                        .stroke(Color.secondary.opacity(0.2), lineWidth: 6)
                }

                Image(systemName: iconName)
                    .font(.title2)
                    .foregroundColor(phaseColor)
            }
            .frame(width: 60, height: 60)

            VStack(alignment: .leading, spacing: 4) {
                Text("EyeRest")
                    .font(.headline)

                if entry.timerState.phase != "idle" && !entry.timerState.isPaused {
                    Text(entry.timerState.endDate, style: .timer)
                        .font(.title.monospacedDigit())
                        .fontWeight(.bold)
                } else if entry.timerState.isPaused {
                    Text(formattedRemaining)
                        .font(.title.monospacedDigit())
                        .fontWeight(.bold)
                } else {
                    Text("--:--")
                        .font(.title.monospacedDigit())
                        .fontWeight(.bold)
                        .foregroundColor(.secondary)
                }

                Text(entry.timerState.statusText)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            Spacer()
        }
        .containerBackground(.clear, for: .widget)
    }

    private var iconName: String {
        switch entry.timerState.phase {
        case "work": return entry.timerState.isPaused ? "eye.slash" : "eye"
        case "rest": return "eye.fill"
        default: return "eye"
        }
    }

    private var phaseColor: Color {
        switch entry.timerState.phase {
        case "work": return .blue
        case "rest": return .green
        default: return .secondary
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
        .description("Zeigt den aktuellen Timer-Status an.")
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
