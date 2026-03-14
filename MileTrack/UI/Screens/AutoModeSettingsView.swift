import SwiftUI
import CoreLocation
import CoreMotion

struct AutoModeSettingsView: View {
    @Environment(\.openURL) private var openURL
    @EnvironmentObject private var autoModeManager: AutoModeManager
    @EnvironmentObject private var subscriptionManager: SubscriptionManager
    
    @AppStorage("autoModeEnabled") private var autoModeEnabled = true
    @AppStorage("useMotionDetection") private var useMotionDetection = true
    @State private var motionDeniedMessage: String?
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                trackingSection
                statusSection
                requirementsSection
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .background(.background)
        .navigationTitle("Auto Mode & Tracking")
    }
    
    // MARK: - Tracking Section
    private var trackingSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Automatic Tracking")
                .font(.title2.weight(.semibold))
                .foregroundStyle(.primary)
            
            GlassCard {
                VStack(alignment: .leading, spacing: 16) {
                    Toggle(isOn: autoModeToggleBinding) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Auto Mode")
                                .font(.subheadline.weight(.semibold))
                            Text("Detect drives and send them to Inbox as pending trips.")
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .tint(.accentColor)
                    .accessibilityLabel("Auto Mode")
                    .accessibilityHint(autoModeToggleHint)
                    
                    Divider()
                    
                    // NEW: Motion Detection Toggle
                    Toggle(isOn: $useMotionDetection) {
                        VStack(alignment: .leading, spacing: 4) {
                            HStack(spacing: 6) {
                                Text("Use Motion Detection")
                                    .font(.subheadline.weight(.semibold))
                                Image(systemName: "flask")
                                    .font(.caption)
                                    .foregroundStyle(.orange)
                                    .accessibilityLabel("Experimental feature")
                            }
                            Text("Uses motion sensors to filter GPS noise and reduce false trips. Fallback to GPS-only if disabled.")
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .tint(.accentColor)
                    .disabled(!autoModeEnabled)
                    .opacity(autoModeEnabled ? 1.0 : 0.5)
                    .accessibilityLabel("Use Motion Detection")
                    .accessibilityHint("Enables motion sensors to improve trip detection accuracy.")
                    
                    if let motionDeniedMessage {
                        Text(motionDeniedMessage)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                        
                        openSettingsButton
                    }
                    
                    if subscriptionManager.canUseUnlimitedAutoMode {
                        HStack(spacing: 8) {
                            Image(systemName: "sparkles")
                                .foregroundStyle(.secondary)
                                .accessibilityHidden(true)
                            Text("Unlimited Auto Mode included with Pro.")
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                        }
                    } else {
                        HStack(spacing: 8) {
                            Image(systemName: "lock.fill")
                                .foregroundStyle(.secondary)
                                .accessibilityHidden(true)
                            Text("Free tier may be limited.")
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                            ProBadge()
                                .accessibilityHidden(true)
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Status Section
    private var statusSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Tracking Status")
                .font(.title2.weight(.semibold))
                .foregroundStyle(.primary)
            
            GlassCard {
                VStack(alignment: .leading, spacing: 12) {
                    HStack(spacing: 8) {
                        Circle()
                            .fill(trackingHealthColor)
                            .frame(width: 10, height: 10)
                        Text(trackingHealthTitle)
                            .font(.subheadline.weight(.semibold))
                    }
                    
                    Text(trackingHealthExplanation)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .accessibilityLabel("Tracking status")
                        .accessibilityValue(trackingHealthExplanation)
                    
                    if autoModeEnabled {
                        Text(autoModeStatusLine)
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                            .accessibilityLabel("Technical details")
                            .accessibilityValue(autoModeStatusLine)
                    }
                    
                    // Location permission actions
                    if autoModeEnabled {
                        locationPermissionActions
                    }
                }
            }
        }
    }
    
    // MARK: - Requirements Section
    private var requirementsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Requirements")
                .font(.title2.weight(.semibold))
                .foregroundStyle(.primary)
            
            GlassCard {
                VStack(alignment: .leading, spacing: 12) {
                    Text(backgroundLocationCopy)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                    
                    openSettingsButton
                }
            }
        }
    }
    
    // MARK: - Helper Views
    @ViewBuilder
    private var locationPermissionActions: some View {
        let status = autoModeManager.status
        
        if status.locationAuthorization == .notDetermined {
            Button {
                autoModeManager.requestWhenInUseLocation()
            } label: {
                settingsButtonLabel(
                    icon: "location",
                    text: "Enable Location (When In Use)"
                )
            }
            .buttonStyle(.plain)
            .accessibilityHint("Requests location permission.")
        } else if status.locationAuthorization == .denied || status.locationAuthorization == .restricted {
            Text("Location access is blocked. You can update permissions in iOS Settings.")
                .font(.footnote)
                .foregroundStyle(.secondary)
            
            openSettingsButton
        }
    }
    
    private var openSettingsButton: some View {
        Button {
            if let url = URL(string: UIApplication.openSettingsURLString) {
                openURL(url)
            }
        } label: {
            settingsButtonLabel(
                icon: "gearshape",
                text: "Open iOS Settings"
            )
        }
        .buttonStyle(.plain)
        .accessibilityHint("Opens iOS Settings for MileTrack.")
    }
    
    private func settingsButtonLabel(icon: String, text: String) -> some View {
        HStack {
            Image(systemName: icon)
                .accessibilityHidden(true)
            Text(text)
                .font(.subheadline.weight(.semibold))
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(Color.primary.opacity(0.10), lineWidth: 1)
        }
    }
    
    // MARK: - Computed Properties
    private var autoModeToggleBinding: Binding<Bool> {
        Binding(
            get: { autoModeEnabled },
            set: { newValue in
                if newValue, isMotionDeniedOrRestricted {
                    autoModeEnabled = false
                    motionDeniedMessage = "Motion permission is denied. Enable Motion & Fitness for MileTrack in iOS Settings to use Auto Mode."
                    autoModeManager.setEnabled(false)
                    return
                }
                autoModeEnabled = newValue
                autoModeManager.setEnabled(newValue)
            }
        )
    }
    
    private var isMotionDeniedOrRestricted: Bool {
        autoModeManager.status.motionAuthorization == .denied || autoModeManager.status.motionAuthorization == .restricted
    }
    
    private var autoModeToggleHint: String {
        if isMotionDeniedOrRestricted {
            return "Motion permission is required for Auto Mode."
        }
        return "Toggles Auto Mode for drive detection."
    }
    
    private var trackingHealthColor: Color {
        switch autoModeManager.trackingHealth {
        case .green: return .green
        case .orange: return .orange
        case .red: return .red
        }
    }
    
    private var trackingHealthTitle: String {
        switch autoModeManager.trackingHealth {
        case .green: return "Ready"
        case .orange: return "Needs Attention"
        case .red: return "Issue Detected"
        }
    }
    
    private var trackingHealthExplanation: String {
        let health = autoModeManager.trackingHealth
        let s = autoModeManager.status
        
        switch health {
        case .green:
            if s.isDriving {
                return "Currently tracking a drive. Distance will be recorded when you stop."
            } else if s.locationAuthorization == .authorizedAlways {
                return "Ready to detect drives automatically, even in the background."
            } else {
                return "Ready to detect drives while the app is open. For background detection, set Location to \"Always\" in iOS Settings."
            }
            
        case .orange:
            if !autoModeEnabled {
                return "Auto Mode is turned off. Enable it above to automatically detect and log your drives."
            } else if s.locationAuthorization == .notDetermined {
                return "Location permission needed. Tap the button below to enable location access."
            } else {
                return "Auto Mode needs attention. Check the settings below."
            }
            
        case .red:
            if s.locationAuthorization == .denied || s.locationAuthorization == .restricted {
                return "Location access is blocked. Open iOS Settings and allow location access for MileTrack to track drives."
            } else if s.motionAuthorization == .denied || s.motionAuthorization == .restricted {
                return "Motion access is blocked. Open iOS Settings and enable Motion & Fitness for MileTrack."
            } else {
                return "There's an issue preventing tracking. Check permissions in iOS Settings."
            }
        }
    }
    
    private var backgroundLocationCopy: String {
        let base = "Auto Mode uses background location to detect drives and prevent missed mileage."
        switch autoModeManager.status.locationAuthorization {
        case .authorizedAlways:
            return base + " Location is used to estimate distance and create trips for your Inbox."
        case .authorizedWhenInUse:
            return "Needs Always Location for background drive detection. " + base + " You can still capture drives while the app is open."
        case .notDetermined:
            return base + " You can enable Location access to estimate mileage during drives."
        case .denied, .restricted:
            return "Needs Location permission. " + base + " Location access is currently blocked."
        @unknown default:
            return base
        }
    }
    
    private var autoModeStatusLine: String {
        let s = autoModeManager.status
        
        let location: String = {
            switch s.locationAuthorization {
            case .authorizedAlways: return "Location: Always"
            case .authorizedWhenInUse: return "Location: When In Use"
            case .denied: return "Location: Denied"
            case .restricted: return "Location: Restricted"
            case .notDetermined: return "Location: Not Determined"
            @unknown default: return "Location: Unknown"
            }
        }()
        
        let motion: String = {
            switch s.motionAuthorization {
            case .authorized: return "Motion: Allowed"
            case .denied: return "Motion: Denied"
            case .restricted: return "Motion: Restricted"
            case .notDetermined: return "Motion: Not Determined"
            @unknown default: return "Motion: Unknown"
            }
        }()
        
        let drive = s.isDriving ? "Driving: Yes" : "Driving: No"
        let tracking = s.isLocationTrackingActive ? "GPS: On" : "GPS: Off"
        let miles = (s.distanceMeters / 1609.344).formatted(.number.precision(.fractionLength(0...2)))
        let distance = "Distance: \(miles) mi"
        
        let last = s.lastEvent.map { "Last: \($0)" } ?? "Last: —"
        return [location, motion, drive, tracking, distance, last].joined(separator: " • ")
    }
}

#Preview {
    NavigationStack {
        AutoModeSettingsView()
    }
    .environmentObject(AutoModeManager(tripStore: TripStore()))
    .environmentObject(SubscriptionManager())
}
