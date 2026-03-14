import SwiftUI

struct UnitsSettingsView: View {
    @AppStorage("useMetricUnits") private var useMetricUnits = false
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                unitsSection
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .background(.background)
        .navigationTitle("Units & Display")
    }
    
    // MARK: - Units Section
    private var unitsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Distance Units")
                .font(.title2.weight(.semibold))
                .foregroundStyle(.primary)
            
            GlassCard {
                VStack(alignment: .leading, spacing: 12) {
                    Toggle(isOn: $useMetricUnits) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Use Metric Units")
                                .font(.subheadline.weight(.semibold))
                            Text(useMetricUnits ? "Distances shown in kilometers (km)" : "Distances shown in miles (mi)")
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .tint(.accentColor)
                    .accessibilityLabel("Use Metric Units")
                    .accessibilityHint("Toggle between kilometers and miles")
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        UnitsSettingsView()
    }
}
