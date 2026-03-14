import SwiftUI
import UIKit

#if DEBUG

struct DiagnosticsView: View {
  @EnvironmentObject private var autoModeManager: AutoModeManager
  
  private let logger = DiagnosticsLogger.shared

  @State private var tailText: String = ""
  @State private var isPresentingShare: Bool = false
  @State private var isPresentingClearConfirm: Bool = false

  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 14) {
        testDataCard
        actionsCard
        logPreviewCard
      }
      .padding(.horizontal, 16)
      .padding(.vertical, 12)
    }
    .background(.background)
    .navigationTitle("Diagnostics")
    .navigationBarTitleDisplayMode(.inline)
    .onAppear {
      refreshTail()
    }
    .sheet(isPresented: $isPresentingShare) {
      ActivityShareSheet(items: [logger.logFileURL()])
    }
    .alert("Clear diagnostics log?", isPresented: $isPresentingClearConfirm) {
      Button("Cancel", role: .cancel) {}
      Button("Clear", role: .destructive) {
        logger.clear()
        refreshTail()
      }
    } message: {
      Text("This can’t be undone.")
    }
  }

  private var testDataCard: some View {
    GlassCard {
      VStack(alignment: .leading, spacing: 12) {
        Text("Test Data")
          .font(.headline)

        Text("Add simulated trips for testing without actually driving.")
          .font(.footnote)
          .foregroundStyle(.secondary)

        PrimaryGlassButton(title: "Simulate Short Drive", systemImage: "car") {
          autoModeManager.debugSimulateDrive(distanceMiles: 3.2, durationSeconds: 7 * 60)
          Haptics.success()
        }
        .accessibilityHint("Adds a 3.2 mile, 7 minute simulated trip.")

        PrimaryGlassButton(title: "Simulate Medium Drive", systemImage: "car") {
          autoModeManager.debugSimulateDrive(distanceMiles: 12.5, durationSeconds: 25 * 60)
          Haptics.success()
        }
        .accessibilityHint("Adds a 12.5 mile, 25 minute simulated trip.")

        PrimaryGlassButton(title: "Simulate Long Drive", systemImage: "car") {
          autoModeManager.debugSimulateDrive(distanceMiles: 45.0, durationSeconds: 60 * 60)
          Haptics.success()
        }
        .accessibilityHint("Adds a 45 mile, 1 hour simulated trip.")
      }
    }
  }

  private var actionsCard: some View {
    GlassCard {
      VStack(alignment: .leading, spacing: 12) {
        Text("Diagnostics Log")
          .font(.headline)

        PrimaryGlassButton(title: "Copy Diagnostics", systemImage: "doc.on.doc") {
          UIPasteboard.general.string = logger.readLastLines(300)
        }
        .accessibilityHint("Copies the last 300 lines to the clipboard.")

        PrimaryGlassButton(title: "Share Log", systemImage: "square.and.arrow.up") {
          isPresentingShare = true
        }
        .accessibilityHint("Shares the diagnostics log file.")

        Button(role: .destructive) {
          isPresentingClearConfirm = true
        } label: {
          HStack {
            Image(systemName: "trash")
              .accessibilityHidden(true)
            Text("Clear Log")
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
        .buttonStyle(.plain)
        .accessibilityLabel("Clear Log")

        Button {
          refreshTail()
        } label: {
          HStack {
            Image(systemName: "arrow.clockwise")
              .accessibilityHidden(true)
            Text("Refresh")
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
        .buttonStyle(.plain)
        .accessibilityLabel("Refresh Diagnostics")
      }
    }
  }

  private var logPreviewCard: some View {
    GlassCard {
      VStack(alignment: .leading, spacing: 10) {
        Text("Last 200 lines")
          .font(.headline)

        if tailText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
          Text("No diagnostics yet.")
            .font(.footnote)
            .foregroundStyle(.secondary)
        } else {
          ScrollView(.vertical) {
            Text(tailText)
              .font(.system(.footnote, design: .monospaced))
              .foregroundStyle(.secondary)
              .frame(maxWidth: .infinity, alignment: .leading)
              .textSelection(.enabled)
          }
          .frame(minHeight: 220, maxHeight: 320)
          .accessibilityLabel("Diagnostics log preview")
        }
      }
    }
  }

  private func refreshTail() {
    tailText = logger.readLastLines(200)
  }
}

private struct ActivityShareSheet: UIViewControllerRepresentable {
  let items: [Any]

  func makeUIViewController(context: Context) -> UIActivityViewController {
    UIActivityViewController(activityItems: items, applicationActivities: nil)
  }

  func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

#Preview {
  NavigationStack {
    DiagnosticsView()
      .environmentObject(AutoModeManager(tripStore: TripStore()))
  }
}

#endif

