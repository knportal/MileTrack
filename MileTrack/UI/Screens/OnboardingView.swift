import SwiftUI
import CoreLocation
import Combine

struct OnboardingView: View {
  @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
  @State private var currentPage = 0
  @StateObject private var permissionRequester = LocationPermissionRequester()

  var body: some View {
    TabView(selection: $currentPage) {
      hookPage.tag(0)
      howItWorksPage.tag(1)
      locationPage.tag(2)
      readyPage.tag(3)
    }
    .tabViewStyle(.page(indexDisplayMode: .always))
    .ignoresSafeArea(edges: .bottom)
    .background(.background)
  }

  // MARK: - Pages

  private var hookPage: some View {
    OnboardingPage(
      systemImage: "dollarsign.circle.fill",
      imageColor: .green,
      title: "Every Mile Is Money",
      subtitle: "The IRS lets you deduct **70¢ per mile** for business driving. MileTrack makes sure you never miss one.",
      bullets: [
        "Average deduction: $2,800/year for regular commuters",
        "Works for freelancers, contractors, delivery drivers",
        "IRS-compliant records — audit-ready in seconds",
      ],
      primaryLabel: "Show Me How",
      primarySystemImage: "arrow.right",
      primaryProminent: true,
      primaryAction: { withAnimation { currentPage = 1 } }
    )
  }

  private var howItWorksPage: some View {
    OnboardingPage(
      systemImage: "arrow.triangle.2.circlepath.circle.fill",
      imageColor: .blue,
      title: "It Works While You Drive",
      subtitle: "No buttons. No check-ins. Just drive.",
      bullets: [
        "MileTrack detects when you start driving automatically",
        "GPS logs your route, distance, and timestamps",
        "Review and confirm trips in seconds from your Inbox",
      ],
      useNumberedBullets: true,
      primaryLabel: "Sounds Good",
      primarySystemImage: "arrow.right",
      primaryProminent: true,
      primaryAction: { withAnimation { currentPage = 2 } }
    )
  }

  private var locationPage: some View {
    OnboardingPage(
      systemImage: "location.fill",
      imageColor: .blue,
      title: "One Permission, All the Power",
      subtitle: "MileTrack needs location access to detect and log your drives. Your data lives only on your device — never sold or shared.",
      bullets: [
        "Background tracking — works even when app is closed",
        "Battery optimized — won't drain your phone",
        "Data stays private — 100% on-device",
      ],
      primaryLabel: permissionRequester.hasRequested ? "Continue" : "Allow Location",
      primarySystemImage: permissionRequester.hasRequested ? "arrow.right" : "location.fill",
      primaryProminent: true,
      primaryAction: {
        if !permissionRequester.hasRequested {
          permissionRequester.request()
        }
        withAnimation { currentPage = 3 }
      },
      secondaryLabel: "Skip for now",
      secondaryAction: { withAnimation { currentPage = 3 } }
    )
  }

  private var readyPage: some View {
    OnboardingPage(
      systemImage: "checkmark.seal.fill",
      imageColor: .green,
      title: "Ready to Track",
      subtitle: "Drive normally. MileTrack logs your trips. At tax time, export a complete IRS-ready report in one tap.",
      bullets: [
        "Review trips in your Inbox — approve or dismiss",
        "Add purpose and client for a clean audit trail",
        "Export PDF or CSV whenever you need it",
      ],
      primaryLabel: "Start Tracking",
      primarySystemImage: "checkmark",
      primaryProminent: true,
      primaryAction: { hasCompletedOnboarding = true }
    )
  }
}

// MARK: - Reusable page layout

private struct OnboardingPage: View {
  let systemImage: String
  let imageColor: Color
  let title: String
  let subtitle: String
  var bullets: [String] = []
  var useNumberedBullets: Bool = false
  let primaryLabel: String
  var primarySystemImage: String? = nil
  var primaryProminent: Bool = false
  let primaryAction: () -> Void
  var secondaryLabel: String? = nil
  var secondaryAction: (() -> Void)? = nil

  @State private var appeared = false

  var body: some View {
    VStack(spacing: 0) {
      Spacer()

      // Hero icon
      ZStack {
        Circle()
          .fill(imageColor.opacity(0.12))
          .frame(width: 140, height: 140)
        Image(systemName: systemImage)
          .font(.system(size: 58, weight: .semibold))
          .foregroundStyle(imageColor)
          .accessibilityHidden(true)
      }
      .scaleEffect(appeared ? 1.0 : 0.8)
      .animation(.spring(response: 0.5, dampingFraction: 0.65), value: appeared)
      .padding(.bottom, 32)

      // Title
      Text(title)
        .font(.title.bold())
        .multilineTextAlignment(.center)
        .padding(.horizontal, 24)
        .padding(.bottom, 12)

      // Subtitle — supports markdown bold via AttributedString
      Text(LocalizedStringKey(subtitle))
        .font(.body)
        .foregroundStyle(.secondary)
        .multilineTextAlignment(.center)
        .padding(.horizontal, 32)

      // Bullets
      if !bullets.isEmpty {
        VStack(alignment: .leading, spacing: 10) {
          ForEach(Array(bullets.enumerated()), id: \.offset) { index, bullet in
            HStack(alignment: .top, spacing: 10) {
              if useNumberedBullets {
                Text("\(index + 1).")
                  .font(.subheadline.bold())
                  .foregroundStyle(imageColor)
                  .frame(minWidth: 20, alignment: .leading)
                  .accessibilityHidden(true)
              } else {
                Image(systemName: "checkmark.circle.fill")
                  .foregroundStyle(imageColor)
                  .font(.body)
                  .accessibilityHidden(true)
              }
              Text(bullet)
                .font(.subheadline)
                .foregroundStyle(.primary)
            }
          }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 40)
        .padding(.top, 24)
      }

      Spacer()
      Spacer()

      // Buttons
      VStack(spacing: 12) {
        PrimaryGlassButton(
          title: primaryLabel,
          systemImage: primarySystemImage,
          isProminent: primaryProminent,
          action: primaryAction
        )
        .padding(.horizontal, 24)

        if let secondaryLabel, let secondaryAction {
          Button(secondaryLabel, action: secondaryAction)
            .font(.subheadline)
            .foregroundStyle(.secondary)
            .padding(.vertical, 4)
            .accessibilityLabel(secondaryLabel)
        }
      }
      .padding(.bottom, 56)
    }
    .frame(maxWidth: DesignConstants.iPadMaxContentWidth)
    .onAppear {
      appeared = false
      // Small delay so the animation fires after the page slides in
      DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
        appeared = true
      }
    }
    .onDisappear {
      appeared = false
    }
  }
}

// MARK: - Location permission helper

private final class LocationPermissionRequester: NSObject, CLLocationManagerDelegate, ObservableObject {
  @Published var hasRequested = false
  private let manager = CLLocationManager()

  override init() {
    super.init()
    manager.delegate = self
  }

  func request() {
    hasRequested = true
    manager.requestAlwaysAuthorization()
  }
}

#Preview {
  OnboardingView()
}
