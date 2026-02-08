import SwiftUI
import Charts

/// Erweiterte Statistiken mit Wochen-Chart (Pro Feature)
/// Verfügbar auf iOS 16+ / macOS 13+
struct EnhancedStatisticsView: View {
    @ObservedObject private var statistics = StatisticsManager.shared

    private var weeklyData: [(date: Date, completed: Int, skipped: Int)] {
        statistics.breaksPerDayLastWeek()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Titel
            Label(String(localized: "statistics.weeklyReport"), systemImage: "chart.bar.fill")
                .font(.headline)
                .foregroundColor(.primary)

            // Bar Chart
            weeklyChart

            // Summary Cards
            summaryCards

            // Gesamte Ruhezeit
            totalRestRow
        }
    }

    // MARK: - Wochen-Chart

    private var weeklyChart: some View {
        Chart {
            ForEach(weeklyData, id: \.date) { entry in
                BarMark(
                    x: .value(String(localized: "chart.day"), entry.date, unit: .day),
                    y: .value(String(localized: "chart.completed"), entry.completed)
                )
                .foregroundStyle(.mint)

                if entry.skipped > 0 {
                    BarMark(
                        x: .value(String(localized: "chart.day"), entry.date, unit: .day),
                        y: .value(String(localized: "chart.skipped"), entry.skipped)
                    )
                    .foregroundStyle(.orange)
                }
            }
        }
        .chartXAxis {
            AxisMarks(values: .stride(by: .day)) { value in
                if let date = value.as(Date.self) {
                    AxisValueLabel {
                        Text(date, format: .dateTime.weekday(.abbreviated))
                            .font(.caption2)
                    }
                }
            }
        }
        .chartYAxis {
            AxisMarks { value in
                AxisGridLine()
                AxisValueLabel {
                    if let intValue = value.as(Int.self) {
                        Text("\(intValue)")
                            .font(.caption2)
                    }
                }
            }
        }
        .frame(height: 160)
    }

    // MARK: - Summary Cards

    private var summaryCards: some View {
        let bestWorst = statistics.bestAndWorstDay()
        let dateFormatter: DateFormatter = {
            let f = DateFormatter()
            f.dateStyle = .medium
            f.timeStyle = .none
            return f
        }()

        return HStack(spacing: 12) {
            if let best = bestWorst.best {
                SummaryCard(
                    icon: "star.fill",
                    color: .yellow,
                    title: String(localized: "statistics.bestDay"),
                    value: String(localized: "statistics.breaksCount \(best.count)"),
                    detail: dateFormatter.string(from: best.date)
                )
            }

            if let worst = bestWorst.worst, worst.count != bestWorst.best?.count {
                SummaryCard(
                    icon: "arrow.down.circle.fill",
                    color: .orange,
                    title: String(localized: "statistics.worstDay"),
                    value: String(localized: "statistics.breaksCount \(worst.count)"),
                    detail: dateFormatter.string(from: worst.date)
                )
            }
        }
    }

    // MARK: - Gesamte Ruhezeit

    private var totalRestRow: some View {
        HStack {
            Image(systemName: "clock.fill")
                .foregroundColor(.cyan)
            Text("statistics.totalRestTime")
                .font(.subheadline)
            Spacer()
            Text(String(localized: "statistics.minutesValue \(String(format: "%.1f", statistics.totalRestMinutes))"))
                .font(.subheadline.bold())
                .foregroundColor(.cyan)
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Summary Card

private struct SummaryCard: View {
    let icon: String
    let color: Color
    let title: String
    let value: String
    let detail: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.caption)
                    .foregroundColor(color)
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Text(value)
                .font(.subheadline.bold())

            Text(detail)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(10)
        .background(Color.secondary.opacity(0.08))
        .cornerRadius(10)
    }
}
