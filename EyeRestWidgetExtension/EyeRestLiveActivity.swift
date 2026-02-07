import ActivityKit
import WidgetKit
import SwiftUI

struct EyeRestLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: EyeRestActivityAttributes.self) { context in
            // MARK: - Lock Screen Banner
            lockScreenView(context: context)
        } dynamicIsland: { context in
            DynamicIsland {
                // MARK: - Expanded Dynamic Island
                DynamicIslandExpandedRegion(.leading) {
                    Image(systemName: phaseIcon(context.state.phase))
                        .font(.title2)
                        .foregroundStyle(phaseColor(context.state.phase))
                }

                DynamicIslandExpandedRegion(.center) {
                    Text(context.state.statusText)
                        .font(.headline)
                        .foregroundStyle(.primary)
                }

                DynamicIslandExpandedRegion(.trailing) {
                    Text("\(context.attributes.workDurationMinutes) Min")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }

                DynamicIslandExpandedRegion(.bottom) {
                    if context.state.isPaused {
                        Text(formatSeconds(context.state.remainingSeconds))
                            .font(.title)
                            .fontWeight(.bold)
                            .monospacedDigit()
                            .foregroundStyle(.secondary)
                    } else {
                        Text(context.state.endDate, style: .timer)
                            .font(.title)
                            .fontWeight(.bold)
                            .monospacedDigit()
                            .multilineTextAlignment(.center)
                    }

                    // Fortschrittsbalken
                    if context.state.endDate > .now {
                        ProgressView(
                            timerInterval: Date.now...context.state.endDate,
                            countsDown: true
                        )
                        .progressViewStyle(.linear)
                        .tint(phaseColor(context.state.phase))
                    } else {
                        ProgressView(value: 1.0)
                            .progressViewStyle(.linear)
                            .tint(phaseColor(context.state.phase))
                    }
                }
            } compactLeading: {
                // MARK: - Compact Leading
                Image(systemName: phaseIcon(context.state.phase))
                    .foregroundStyle(phaseColor(context.state.phase))
            } compactTrailing: {
                // MARK: - Compact Trailing
                if context.state.isPaused {
                    Text(formatSeconds(context.state.remainingSeconds))
                        .monospacedDigit()
                        .foregroundStyle(.secondary)
                } else {
                    Text(context.state.endDate, style: .timer)
                        .monospacedDigit()
                }
            } minimal: {
                // MARK: - Minimal (bei mehreren Activities)
                Image(systemName: phaseIcon(context.state.phase))
                    .foregroundStyle(phaseColor(context.state.phase))
            }
        }
    }

    // MARK: - Lock Screen View

    @ViewBuilder
    private func lockScreenView(context: ActivityViewContext<EyeRestActivityAttributes>) -> some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: phaseIcon(context.state.phase))
                    .font(.title3)
                    .foregroundStyle(phaseColor(context.state.phase))

                Text(context.state.statusText)
                    .font(.headline)

                Spacer()

                Text("EyeRest")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            if context.state.isPaused {
                Text(formatSeconds(context.state.remainingSeconds))
                    .font(.system(size: 36, weight: .bold, design: .monospaced))
                    .foregroundStyle(.secondary)
            } else {
                Text(context.state.endDate, style: .timer)
                    .font(.system(size: 36, weight: .bold, design: .monospaced))
                    .multilineTextAlignment(.center)
            }

            if context.state.endDate > .now {
                ProgressView(
                    timerInterval: Date.now...context.state.endDate,
                    countsDown: true
                )
                .progressViewStyle(.linear)
                .tint(phaseColor(context.state.phase))
            } else {
                ProgressView(value: 1.0)
                    .progressViewStyle(.linear)
                    .tint(phaseColor(context.state.phase))
            }
        }
        .padding()
        .activityBackgroundTint(Color.black.opacity(0.7))
        .activitySystemActionForegroundColor(.white)
    }

    // MARK: - Hilfsfunktionen

    private func phaseIcon(_ phase: String) -> String {
        switch phase {
        case "work": return "eye.fill"
        case "rest": return "eye.trianglebadge.exclamationmark"
        default: return "eye"
        }
    }

    private func phaseColor(_ phase: String) -> Color {
        switch phase {
        case "work": return .blue
        case "rest": return .green
        default: return .gray
        }
    }

    private func formatSeconds(_ seconds: Int) -> String {
        let minutes = seconds / 60
        let secs = seconds % 60
        if minutes > 0 {
            return String(format: "%d:%02d", minutes, secs)
        }
        return "\(secs)s"
    }
}
