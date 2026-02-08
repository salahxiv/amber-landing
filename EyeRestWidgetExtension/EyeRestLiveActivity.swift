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
                    Text("widget.minutes \(context.attributes.workDurationMinutes)")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }

                DynamicIslandExpandedRegion(.bottom) {
                    HStack {
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
                        }

                        Spacer()

                        // Kompakter Aktions-Button
                        if context.state.phase == "rest" {
                            Link(destination: URL(string: "eyerest://skip")!) {
                                Image(systemName: "forward.fill")
                                    .font(.body)
                                    .foregroundStyle(.white)
                                    .padding(8)
                                    .background(Color.white.opacity(0.15))
                                    .clipShape(Circle())
                            }
                        } else if context.state.isPaused {
                            Link(destination: URL(string: "eyerest://resume")!) {
                                Image(systemName: "play.fill")
                                    .font(.body)
                                    .foregroundStyle(.white)
                                    .padding(8)
                                    .background(Color.blue.opacity(0.4))
                                    .clipShape(Circle())
                            }
                        } else {
                            Link(destination: URL(string: "eyerest://pause")!) {
                                Image(systemName: "pause.fill")
                                    .font(.body)
                                    .foregroundStyle(.white)
                                    .padding(8)
                                    .background(Color.white.opacity(0.15))
                                    .clipShape(Circle())
                            }
                        }
                    }

                    // Fortschrittsbalken mit Gradient-Tint
                    if context.state.endDate > .now {
                        ProgressView(
                            timerInterval: Date.now...context.state.endDate,
                            countsDown: true
                        )
                        .progressViewStyle(.linear)
                        .tint(phaseColor(context.state.phase))
                        .scaleEffect(y: 1.5, anchor: .center)
                    } else {
                        ProgressView(value: 1.0)
                            .progressViewStyle(.linear)
                            .tint(phaseColor(context.state.phase))
                            .scaleEffect(y: 1.5, anchor: .center)
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
                .scaleEffect(y: 2, anchor: .center)
            } else {
                ProgressView(value: 1.0)
                    .progressViewStyle(.linear)
                    .tint(phaseColor(context.state.phase))
                    .scaleEffect(y: 2, anchor: .center)
            }

            // Aktions-Buttons
            actionButtons(for: context.state)
        }
        .padding()
        .activityBackgroundTint(phaseTintColor(context.state.phase))
        .activitySystemActionForegroundColor(.white)
    }

    // MARK: - Action Buttons

    @ViewBuilder
    private func actionButtons(for state: EyeRestActivityAttributes.ContentState) -> some View {
        HStack(spacing: 12) {
            if state.phase == "rest" {
                // Skip-Button während der Pause
                Link(destination: URL(string: "eyerest://skip")!) {
                    HStack(spacing: 6) {
                        Image(systemName: "forward.fill")
                            .font(.caption)
                        Text("widget.skip")
                            .font(.caption.weight(.medium))
                    }
                    .foregroundStyle(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(Color.white.opacity(0.15))
                    .clipShape(Capsule())
                }
            } else if state.phase == "work" {
                if state.isPaused {
                    // Fortsetzen-Button wenn pausiert
                    Link(destination: URL(string: "eyerest://resume")!) {
                        HStack(spacing: 6) {
                            Image(systemName: "play.fill")
                                .font(.caption)
                            Text("widget.resume")
                                .font(.caption.weight(.medium))
                        }
                        .foregroundStyle(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(Color.blue.opacity(0.4))
                        .clipShape(Capsule())
                    }
                } else {
                    // Pause-Button während der Arbeit
                    Link(destination: URL(string: "eyerest://pause")!) {
                        HStack(spacing: 6) {
                            Image(systemName: "pause.fill")
                                .font(.caption)
                            Text("widget.pause")
                                .font(.caption.weight(.medium))
                        }
                        .foregroundStyle(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(Color.white.opacity(0.15))
                        .clipShape(Capsule())
                    }
                }
            }
        }
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
        case "work": return .cyan
        case "rest": return .green
        default: return .gray
        }
    }

    private func phaseTintColor(_ phase: String) -> Color {
        switch phase {
        case "work": return Color(red: 0.05, green: 0.1, blue: 0.25)
        case "rest": return Color(red: 0.05, green: 0.2, blue: 0.1)
        default: return Color.black.opacity(0.7)
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
