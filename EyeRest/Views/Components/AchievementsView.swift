import SwiftUI

/// Achievements-Abschnitt für die iOS Statistik-Liste
struct AchievementsSectionView: View {
    @ObservedObject private var achievements = AchievementService.shared

    var body: some View {
        if achievements.unlockedCount > 0 {
            Section {
                ForEach(Achievement.allCases) { achievement in
                    if achievements.isUnlocked(achievement) {
                        AchievementRow(achievement: achievement, unlocked: true)
                    }
                }

                // Nächstes zu erreichendes Achievement
                if let next = nextLocked {
                    AchievementRow(achievement: next, unlocked: false)
                }
            } header: {
                HStack {
                    Label(String(localized: "statistics.achievements"), systemImage: "trophy.fill")
                    Spacer()
                    Text("\(achievements.unlockedCount)/\(achievements.totalCount)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
    }

    private var nextLocked: Achievement? {
        Achievement.allCases.first { !achievements.isUnlocked($0) }
    }
}

/// Einzelne Achievement-Zeile
struct AchievementRow: View {
    let achievement: Achievement
    let unlocked: Bool

    var body: some View {
        HStack(spacing: 12) {
            // Icon
            Image(systemName: achievement.icon)
                .font(.title3)
                .foregroundColor(unlocked ? achievementColor : .gray.opacity(0.4))
                .frame(width: 30)

            // Text
            VStack(alignment: .leading, spacing: 2) {
                Text(achievement.title)
                    .font(.subheadline)
                    .fontWeight(unlocked ? .semibold : .regular)
                    .foregroundColor(unlocked ? .primary : .secondary)

                Text(achievement.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            if unlocked {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
                    .font(.subheadline)
            } else {
                Image(systemName: "lock.fill")
                    .foregroundColor(.gray.opacity(0.3))
                    .font(.caption)
            }
        }
        .opacity(unlocked ? 1.0 : 0.6)
    }

    private var achievementColor: Color {
        switch achievement.color {
        case "blue": return .blue
        case "yellow": return .yellow
        case "orange": return .orange
        case "red": return .red
        case "green": return .green
        default: return .blue
        }
    }
}

/// Achievement-Toast der kurz eingeblendet wird
struct AchievementToast: View {
    let achievement: Achievement

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: achievement.icon)
                .font(.title2)
                .foregroundColor(.yellow)

            VStack(alignment: .leading, spacing: 2) {
                Text("achievement.unlocked")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))

                Text(achievement.title)
                    .font(.headline)
                    .foregroundColor(.white)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
        .background(Color.black.opacity(0.85))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.3), radius: 10)
    }
}

#Preview {
    List {
        AchievementsSectionView()
    }
}
