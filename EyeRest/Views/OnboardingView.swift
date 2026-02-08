import SwiftUI
import StoreKit

/// Onboarding-Flow beim ersten App-Start
/// Erklärt die 20-20-20 Regel und fordert Berechtigungen kontextbezogen an
struct OnboardingView: View {
    @ObservedObject var settings = SettingsManager.shared
    @ObservedObject var subscriptionManager = SubscriptionManager.shared
    var onComplete: () -> Void

    @State private var currentPage = 0
    @State private var notificationGranted = false
    @State private var isPurchasing = false
    @State private var crownGlow: Double = 0.3

    var body: some View {
        ZStack {
            // Hintergrund
            backgroundGradient

            VStack(spacing: 0) {
                // Seiten-Inhalt
                TabView(selection: $currentPage) {
                    welcomePage.tag(0)
                    rulePage.tag(1)
                    notificationPage.tag(2)
                    proUpgradePage.tag(3)
                    startPage.tag(4)
                }
                #if os(iOS)
                .tabViewStyle(.page(indexDisplayMode: .never))
                #endif
                .animation(.easeInOut(duration: 0.3), value: currentPage)

                // Navigation
                navigationBar
                    .padding(.horizontal, 32)
                    .padding(.bottom, 40)
            }
        }
        #if os(iOS)
        .statusBarHidden()
        #endif
    }

    // MARK: - Hintergrund

    private var backgroundGradient: some View {
        LinearGradient(
            colors: gradientColors,
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
        .animation(.easeInOut(duration: 0.5), value: currentPage)
    }

    private var gradientColors: [Color] {
        switch currentPage {
        case 0: return [Color(red: 0.1, green: 0.1, blue: 0.2), Color(red: 0.15, green: 0.15, blue: 0.3)]
        case 1: return [Color(red: 0.05, green: 0.15, blue: 0.25), Color(red: 0.1, green: 0.2, blue: 0.35)]
        case 2: return [Color(red: 0.1, green: 0.12, blue: 0.22), Color(red: 0.15, green: 0.18, blue: 0.32)]
        case 3: return [Color(red: 0.2, green: 0.12, blue: 0.05), Color(red: 0.15, green: 0.1, blue: 0.2)]
        default: return [Color(red: 0.08, green: 0.16, blue: 0.2), Color(red: 0.12, green: 0.22, blue: 0.3)]
        }
    }

    // MARK: - Seite 1: Willkommen

    private var welcomePage: some View {
        VStack(spacing: 24) {
            Spacer()

            // Animated Eye Icon
            EyeAnimationView()
                .frame(width: 120, height: 120)

            Text("EyeRest")
                .font(.system(size: 42, weight: .bold, design: .rounded))
                .foregroundColor(.white)

            Text("onboarding.welcome.subtitle")
                .font(.title3)
                .foregroundColor(.white.opacity(0.8))
                .multilineTextAlignment(.center)

            Spacer()
            Spacer()
        }
        .padding(.horizontal, 32)
    }

    // MARK: - Seite 2: 20-20-20 Regel

    private var rulePage: some View {
        VStack(spacing: 32) {
            Spacer()

            Text("onboarding.rule.title")
                .font(.title.bold())
                .foregroundColor(.white)

            // Visuelle Erklärung
            VStack(spacing: 24) {
                RuleStepView(
                    number: "20",
                    unit: String(localized: "onboarding.rule.minutes"),
                    description: String(localized: "onboarding.rule.workFocused"),
                    icon: "desktopcomputer",
                    color: .blue
                )

                // Verbindungslinie
                RoundedRectangle(cornerRadius: 1)
                    .fill(Color.white.opacity(0.2))
                    .frame(width: 2, height: 20)

                RuleStepView(
                    number: "20",
                    unit: String(localized: "onboarding.rule.seconds"),
                    description: String(localized: "onboarding.rule.takeEyeBreak"),
                    icon: "eye.fill",
                    color: .green
                )

                RoundedRectangle(cornerRadius: 1)
                    .fill(Color.white.opacity(0.2))
                    .frame(width: 2, height: 20)

                RuleStepView(
                    number: "6",
                    unit: String(localized: "onboarding.rule.meters"),
                    description: String(localized: "onboarding.rule.lookFar"),
                    icon: "mountain.2.fill",
                    color: .mint
                )
            }

            Text("onboarding.rule.recommended")
                .font(.footnote)
                .foregroundColor(.white.opacity(0.5))

            Spacer()
            Spacer()
        }
        .padding(.horizontal, 32)
    }

    // MARK: - Seite 3: Benachrichtigungen

    private var notificationPage: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "bell.badge.fill")
                .font(.system(size: 64))
                .foregroundStyle(.white, .yellow)
                .symbolEffect(.bounce, options: .repeating.speed(0.5))

            Text("onboarding.notifications.title")
                .font(.title.bold())
                .foregroundColor(.white)

            Text("onboarding.notifications.subtitle")
                .font(.body)
                .foregroundColor(.white.opacity(0.8))
                .multilineTextAlignment(.center)

            if notificationGranted {
                Label("onboarding.notifications.enabled", systemImage: "checkmark.circle.fill")
                    .font(.headline)
                    .foregroundColor(.green)
                    .padding(.top, 8)
            } else {
                Button(action: requestNotifications) {
                    HStack {
                        Image(systemName: "bell.fill")
                        Text("onboarding.notifications.allow")
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color.white.opacity(0.2))
                    .cornerRadius(14)
                }
                .padding(.top, 8)
            }

            Spacer()
            Spacer()
        }
        .padding(.horizontal, 32)
    }

    // MARK: - Seite 4: Pro Upgrade

    private var lifetimeProduct: Product? {
        subscriptionManager.products.first { $0.id == Constants.subscriptionLifetime }
    }

    private var proUpgradePage: some View {
        VStack(spacing: 20) {
            Spacer()

            // Krone mit Glow
            ZStack {
                Circle()
                    .fill(Color.orange.opacity(crownGlow * 0.4))
                    .frame(width: 100, height: 100)
                    .blur(radius: 20)

                Image(systemName: "crown.fill")
                    .font(.system(size: 56))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color.yellow, Color.orange],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .shadow(color: .orange.opacity(0.5), radius: 10)
            }
            .onAppear {
                withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
                    crownGlow = 0.8
                }
            }

            Text("onboarding.pro.title")
                .font(.title.bold())
                .foregroundColor(.white)

            Text("onboarding.pro.subtitle")
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.7))

            // Feature-Liste
            VStack(spacing: 10) {
                ProFeatureRow(icon: "calendar.badge.checkmark", text: String(localized: "pro.feature.calendarSync"), detail: String(localized: "pro.feature.calendarSync.detail"))
                ProFeatureRow(icon: "lock.shield.fill", text: String(localized: "pro.feature.strictMode"), detail: String(localized: "pro.feature.strictMode.detail"))
                ProFeatureRow(icon: "speaker.wave.3.fill", text: String(localized: "pro.feature.customSounds"), detail: String(localized: "pro.feature.customSounds.detail"))
                ProFeatureRow(icon: "paintbrush.fill", text: String(localized: "pro.feature.themes"), detail: String(localized: "pro.feature.themes.detail"))
                ProFeatureRow(icon: "arrow.triangle.2.circlepath", text: String(localized: "pro.feature.deviceSync"), detail: String(localized: "pro.feature.deviceSync.detail"))
                ProFeatureRow(icon: "bell.badge.fill", text: String(localized: "pro.feature.smartReminders"), detail: String(localized: "pro.feature.smartReminders.detail"))
            }
            .padding(.vertical, 8)

            // Kauf-Button
            if let product = lifetimeProduct {
                Button(action: {
                    Task {
                        isPurchasing = true
                        await subscriptionManager.purchase(product)
                        isPurchasing = false
                        if subscriptionManager.isPro {
                            withAnimation {
                                currentPage = 4
                            }
                        }
                    }
                }) {
                    HStack {
                        if isPurchasing {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .black))
                                .scaleEffect(0.8)
                        } else {
                            Image(systemName: "crown.fill")
                                .foregroundColor(.orange)
                            Text("onboarding.pro.unlockForever \(product.displayPrice)")
                        }
                    }
                    .font(.headline)
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        LinearGradient(
                            colors: [Color.yellow, Color.orange],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(16)
                }
                .disabled(isPurchasing)
            } else if subscriptionManager.isLoading {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    .frame(height: 50)
            }

            // Restore
            Button(action: {
                Task {
                    await subscriptionManager.restorePurchases()
                    if subscriptionManager.isPro {
                        withAnimation {
                            currentPage = 4
                        }
                    }
                }
            }) {
                Text("onboarding.pro.restore")
                    .font(.footnote)
                    .foregroundColor(.white.opacity(0.5))
            }

            Spacer()
        }
        .padding(.horizontal, 32)
    }

    // MARK: - Seite 5: Los geht's

    private var startPage: some View {
        VStack(spacing: 24) {
            Spacer()

            // Animierter Countdown-Ring
            ZStack {
                Circle()
                    .stroke(Color.white.opacity(0.15), lineWidth: 6)
                    .frame(width: 140, height: 140)

                Circle()
                    .trim(from: 0, to: 0.75)
                    .stroke(
                        AngularGradient(
                            colors: [.blue, .cyan, .blue],
                            center: .center,
                            startAngle: .degrees(-90),
                            endAngle: .degrees(270)
                        ),
                        style: StrokeStyle(lineWidth: 6, lineCap: .round)
                    )
                    .frame(width: 140, height: 140)
                    .rotationEffect(.degrees(-90))
                    .shadow(color: .blue.opacity(0.5), radius: 10)

                VStack(spacing: 2) {
                    Text("20:00")
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .monospacedDigit()

                    Text("timer.status.ready")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.6))
                }
            }

            Text("onboarding.start.title")
                .font(.title.bold())
                .foregroundColor(.white)

            Text("onboarding.start.subtitle")
                .font(.body)
                .foregroundColor(.white.opacity(0.8))
                .multilineTextAlignment(.center)

            Button(action: completeOnboarding) {
                HStack {
                    Text("onboarding.start.button")
                    Image(systemName: "arrow.right")
                }
                .font(.headline)
                .foregroundColor(.black)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(Color.white)
                .cornerRadius(16)
            }
            .padding(.top, 16)

            Spacer()
        }
        .padding(.horizontal, 32)
    }

    // MARK: - Navigation

    private var navigationBar: some View {
        HStack {
            // Überspringen
            if currentPage < 4 {
                Button(String(localized: "onboarding.skip")) {
                    completeOnboarding()
                }
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.5))
            } else {
                Spacer().frame(width: 80)
            }

            Spacer()

            // Page Indicator
            HStack(spacing: 8) {
                ForEach(0..<5) { index in
                    Circle()
                        .fill(index == currentPage ? Color.white : Color.white.opacity(0.3))
                        .frame(width: index == currentPage ? 10 : 6, height: index == currentPage ? 10 : 6)
                        .animation(.easeInOut(duration: 0.2), value: currentPage)
                }
            }

            Spacer()

            // Weiter
            if currentPage < 4 {
                Button(action: nextPage) {
                    HStack(spacing: 4) {
                        Text("onboarding.next")
                        Image(systemName: "chevron.right")
                    }
                    .font(.subheadline.bold())
                    .foregroundColor(.white)
                }
            } else {
                Spacer().frame(width: 80)
            }
        }
    }

    // MARK: - Actions

    private func nextPage() {
        withAnimation {
            currentPage = min(currentPage + 1, 4)
        }
    }

    private func requestNotifications() {
        Task {
            let granted = await NotificationService.shared.requestPermission()
            await MainActor.run {
                withAnimation {
                    notificationGranted = granted
                }
            }
        }
    }

    private func completeOnboarding() {
        settings.hasCompletedOnboarding = true
        AnalyticsService.shared.track("onboarding_completed")
        onComplete()
    }
}

// MARK: - Regel-Schritt Komponente

/// Einzelner Schritt in der 20-20-20 Regel-Erklärung
struct RuleStepView: View {
    let number: String
    let unit: String
    let description: String
    let icon: String
    let color: Color

    var body: some View {
        HStack(spacing: 16) {
            // Icon
            ZStack {
                Circle()
                    .fill(color.opacity(0.2))
                    .frame(width: 50, height: 50)

                Image(systemName: icon)
                    .font(.system(size: 22))
                    .foregroundColor(color)
            }

            // Text
            VStack(alignment: .leading, spacing: 2) {
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text(number)
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundColor(.white)

                    Text(unit)
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.7))
                }

                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.6))
            }

            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color.white.opacity(0.08))
        .cornerRadius(14)
    }
}

// MARK: - Pro Feature Zeile

/// Kompakte Feature-Zeile für die Pro-Upgrade Seite im Onboarding
struct ProFeatureRow: View {
    let icon: String
    let text: String
    let detail: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(.orange)
                .frame(width: 32, height: 32)
                .background(Color.orange.opacity(0.15))
                .clipShape(RoundedRectangle(cornerRadius: 8))

            VStack(alignment: .leading, spacing: 1) {
                Text(text)
                    .font(.subheadline.bold())
                    .foregroundColor(.white)
                Text(detail)
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.5))
            }

            Spacer()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color.white.opacity(0.06))
        .cornerRadius(10)
    }
}

// MARK: - Augen-Animation

/// Animiertes Augen-Icon für die Willkommensseite
struct EyeAnimationView: View {
    @State private var scale: CGFloat = 0.8
    @State private var glowOpacity: Double = 0.3
    @State private var rotation: Double = 0

    var body: some View {
        ZStack {
            // Glow
            Circle()
                .fill(Color.blue.opacity(glowOpacity * 0.4))
                .scaleEffect(scale * 1.3)
                .blur(radius: 20)

            // Äußerer Ring
            Circle()
                .stroke(Color.white.opacity(0.15), lineWidth: 3)
                .scaleEffect(scale)

            // Rotierender Ring
            Circle()
                .trim(from: 0, to: 0.3)
                .stroke(
                    AngularGradient(
                        colors: [.blue, .cyan],
                        center: .center
                    ),
                    style: StrokeStyle(lineWidth: 3, lineCap: .round)
                )
                .scaleEffect(scale)
                .rotationEffect(.degrees(rotation))

            // Auge
            Image(systemName: "eye.fill")
                .font(.system(size: 48))
                .foregroundColor(.white)
                .symbolEffect(.pulse, options: .repeating.speed(0.4))
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
                scale = 1.0
                glowOpacity = 0.6
            }
            withAnimation(.linear(duration: 4).repeatForever(autoreverses: false)) {
                rotation = 360
            }
        }
    }
}

// MARK: - Preview

#Preview {
    OnboardingView {
        print("Onboarding abgeschlossen")
    }
}
