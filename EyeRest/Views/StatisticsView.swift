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

                    Text("Statistiken")
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
                        title: "Heute",
                        value: "\(statistics.completedBreaksToday)",
                        subtitle: statistics.skippedBreaksToday > 0
                            ? "(\(statistics.skippedBreaksToday) übersprungen)"
                            : "Pausen"
                    )

                    // Diese Woche
                    StatisticRowView(
                        title: "Diese Woche",
                        value: "\(statistics.completedBreaksThisWeek)",
                        subtitle: "Pausen"
                    )

                    // Durchschnitt
                    StatisticRowView(
                        title: "Durchschnitt",
                        value: String(format: "%.1f", statistics.averageBreaksPerDay),
                        subtitle: "pro Tag"
                    )

                    // Aktuelle Serie
                    if statistics.currentStreak > 0 {
                        StatisticRowView(
                            title: "Aktuelle Serie",
                            value: "\(statistics.currentStreak)",
                            subtitle: "in Folge",
                            highlighted: true
                        )
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
