import SwiftUI
import CoreLocation
import Combine

struct OnboardingView: View {
  @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
  @State private var currentPage = 0
  @StateObject private var permissionRequester = LocationPermissionRequester()

  var body: some View {
    TabView(selection: $currentPage) {
      welcomePage.tag(0)
      locationPage.tag(1)
      readyPage.tag(2)
    }
    .tabViewStyle(.page(indexDisplayMode: .always))
    .ignoresSafeArea(edges: .bottom)
    .background(.background)
  }

  // MARK: - Pages

  private var welcomePage: some View {
    OnboardingPage(
      systemImage: "car.fill",
      imageColor: .accentColor,
      title: "Welcome to MileTrack by Plenitudo",
      subtitle: "The simplest way to log every business mile — automatically. Built for freelancers, contractors, and the self-employed.",
      primaryLabel: "Get Started",
      primarySystemImage: "arrow.right",
      primaryProminent: true,
      primaryAction: { withAnimation { currentPage = 1 } }
    )
  }

  private var locationPage: some View {
    OnboardingPage(
      systemImage: "location.fill",
      imageColor: .blue,
      title: "Track While You Drive",
      subtitle: "MileTrack by Plenitudo detects trips automatically using your location. Your data stays on your device — never sold or shared.",
      bullets: [
        "Detects trip start and end automatically",
        "Works in the background, even when closed",
        "IRS §274(d) compliant mileage logs",
      ],
      primaryLabel: permissionRequester.hasRequested ? "Continue" : "Allow Location Access",
      primarySystemImage: permissionRequester.hasRequested ? "arrow.right" : "location.fill",
      primaryProminent: true,
      primaryAction: {
        if !permissionRequester.hasRequested {
          permissionRequester.request()
        }
        withAnimation { currentPage = 2 }
      },
      secondaryLabel: "Skip for now",
      secondaryAction: { withAnimation { currentPage = 2 } }
    )
  }

  private var readyPage: some View {
    OnboardingPage(
      systemImage: "checkmark.seal.fill",
      imageColor: .green,
      title: "You're All Set",
      subtitle: "Start driving and MileTrack by Plenitudo logs your trips. Review them in Inbox, then export a tax-ready report at any time.",
      bullets: [
        "Swipe to confirm or dismiss trips in Inbox",
        "Add purpose and vehicle for audit trails",
        "Export PDF or CSV when tax time comes",
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
  let primaryLabel: String
  var primarySystemImage: String? = nil
  var primaryProminent: Bool = false
  let primaryAction: () -> Void
  var secondaryLabel: String? = nil
  var secondaryAction: (() -> Void)? = nil

  var body: some View {
    VStack(spacing: 0) {
      Spacer()

      // Hero icon
      ZStack {
        Circle()
          .fill(imageColor.opacity(0.12))
          .frame(width: 120, height: 120)
        Image(systemName: systemImage)
          .font(.system(size: 52, weight: .semibold))
          .foregroundStyle(imageColor)
          .accessibilityHidden(true)
      }
      .padding(.bottom, 32)

      // Title
      Text(title)
        .font(.title.bold())
        .multilineTextAlignment(.center)
        .padding(.horizontal, 24)
        .padding(.bottom, 12)

      // Subtitle text
      Text(subtitle)
        .font(.body)
        .foregroundStyle(.secondary)
        .multilineTextAlignment(.center)
        .padding(.horizontal, 32)

      // Bullets
      if !bullets.isEmpty {
        VStack(alignment: .leading, spacing: 10) {
          ForEach(bullets, id: \.self) { bullet in
            HStack(alignment: .top, spacing: 10) {
              Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(imageColor)
                .font(.body)
                .accessibilityHidden(true)
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

