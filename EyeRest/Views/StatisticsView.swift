import SwiftUI

/// Ansicht für Pausen-Statistiken im Menüleisten-Popover
struct StatisticsView: View {
    @ObservedObject private var statistics = StatisticsManager.shared
    @Binding var isExpanded: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header mit Toggle
            Button(action: {
                withAnimation(.easeInOut(duration: 0.2)) {
                    isExpanded.toggle()
                }
                NotificationCenter.default.post(name: .settingsExpandedChanged, object: nil)
            }) {
                HStack(spacing: 8) {
                    Image(systemName: "chart.bar.fill")
                        .font(.system(size: 13))
                        .foregroundColor(.blue)
                        .frame(width: 16)

                    Text("statistics.title")
                        .font(.system(size: 13))

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(.secondary)
                        .rotationEffect(.degrees(isExpanded ? 90 : 0))
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            // Erweiterte Statistiken
            if isExpanded {
                VStack(spacing: 6) {
                    // Heute
                    StatisticRowView(
                        title: String(localized: "statistics.today"),
                        value: "\(statistics.completedBreaksToday)",
                        subtitle: statistics.skippedBreaksToday > 0
                            ? String(localized: "statistics.skipped \(statistics.skippedBreaksToday)")
                            : String(localized: "statistics.breaks")
                    )

                    // Diese Woche
                    StatisticRowView(
                        title: String(localized: "statistics.thisWeek"),
                        value: "\(statistics.completedBreaksThisWeek)",
                        subtitle: String(localized: "statistics.breaks")
                    )

                    // Durchschnitt
                    StatisticRowView(
                        title: String(localized: "statistics.average"),
                        value: String(format: "%.1f", statistics.averageBreaksPerDay),
                        subtitle: String(localized: "statistics.perDay")
                    )

                    // Aktuelle Serie
                    if statistics.currentDayStreak > 0 {
                        StatisticRowView(
                            title: String(localized: "statistics.dayStreak"),
                            value: "\(statistics.currentDayStreak)",
                            subtitle: String(localized: "statistics.days"),
                            highlighted: true
                        )
                    }

                    // Längste Serie
                    if statistics.longestDayStreak > 1 {
                        StatisticRowView(
                            title: String(localized: "statistics.longestStreak"),
                            value: "\(statistics.longestDayStreak)",
                            subtitle: String(localized: "statistics.days")
                        )
                    }

                    // Achievements
                    let achievements = AchievementService.shared
                    if achievements.unlockedCount > 0 {
                        StatisticRowView(
                            title: String(localized: "statistics.achievements"),
                            value: "\(achievements.unlockedCount)/\(achievements.totalCount)",
                            subtitle: ""
                        )
                    }

                    // Erweiterte Statistiken (Pro)
                    if SettingsManager.shared.isPro {
                        Divider()
                        EnhancedStatisticsView()
                    } else {
                        #if os(macOS)
                        Divider()
                        Button {
                            PaywallWindowController.shared.show()
                        } label: {
                            HStack {
                                Image(systemName: "chart.bar.fill")
                                    .foregroundColor(.blue)
                                Text("statistics.advancedCharts")
                                    .font(.caption)
                                Spacer()
                                HStack(spacing: 3) {
                                    Image(systemName: "lock.fill")
                                        .font(.system(size: 8))
                                    Text("PRO")
                                        .font(.system(size: 9, weight: .bold))
                                }
                                .foregroundColor(.yellow)
                                .padding(.horizontal, 5)
                                .padding(.vertical, 2)
                                .background(Color.yellow.opacity(0.15))
                                .cornerRadius(4)
                            }
                        }
                        .buttonStyle(.plain)
                        #endif
                    }
                }
                .padding(.horizontal, 12)
                .padding(.bottom, 6)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }
}

/// Einzelne Zeile in der Statistik-Ansicht
struct StatisticRowView: View {
    let title: String
    let value: String
    let subtitle: String
    var highlighted: Bool = false

    var body: some View {
        HStack {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)

            Spacer()

            HStack(spacing: 4) {
                Text(value)
                    .font(.system(.body, design: .rounded))
                    .fontWeight(.semibold)
                    .foregroundColor(highlighted ? .orange : .primary)

                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 2)
    }
}

#Preview {
    StatisticsView(isExpanded: .constant(true))
        .frame(width: 280)
        .padding()
}
