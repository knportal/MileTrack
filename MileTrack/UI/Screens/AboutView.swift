import SwiftUI

struct AboutView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                appInfoSection
                versionSection
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .background(.background)
        .navigationTitle("About")
    }
    
    // MARK: - App Info Section
    private var appInfoSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("MileTrack by Plenitudo")
                .font(.title2.weight(.semibold))
                .foregroundStyle(.primary)

            GlassCard {
                VStack(alignment: .leading, spacing: 12) {
                    Text("MileTrack by Plenitudo helps you automatically track and log your business mileage for tax deductions and expense reports.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    
                    Text("Features include automatic drive detection, custom categories, rule-based trip classification, and detailed reports.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }
    
    // MARK: - Version Section
    private var versionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Version")
                .font(.title2.weight(.semibold))
                .foregroundStyle(.primary)
            
            GlassCard {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("App Version")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text(appVersion)
                            .font(.subheadline.monospaced())
                            .foregroundStyle(.primary)
                    }
                    
                    Divider()
                    
                    HStack {
                        Text("Build")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text(buildNumber)
                            .font(.subheadline.monospaced())
                            .foregroundStyle(.primary)
                    }
                }
            }
        }
    }
    
    // MARK: - Computed Properties
    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    }
    
    private var buildNumber: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
    }
}

#Preview {
    NavigationStack {
        AboutView()
    }
}
