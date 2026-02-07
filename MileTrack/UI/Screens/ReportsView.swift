import SwiftUI

struct ReportsView: View {
  @EnvironmentObject private var tripStore: TripStore
  @EnvironmentObject private var subscriptionManager: SubscriptionManager
  @EnvironmentObject private var categoriesStore: CategoriesStore
  @EnvironmentObject private var clientStore: ClientStore

  /// Optional hook for an upgrade flow (no purchases).
  var onUpgradeToPro: (() -> Void)?

  @State private var rangePreset: ExportDateRangePreset = .monthToDate
  @State private var customRange: ExportDateRange?
  @State private var isPresentingCustomRange: Bool = false
  @State private var selectedCategory: String? = nil
  @State private var selectedClient: String? = nil
  @State private var selectedProject: String? = nil
  @State private var filtersMessage: String?
  @State private var shareItem: ShareItem?
  @State private var exportErrorMessage: String?

  private let exportService = ExportService()
  private let pdfExportService = PDFExportService()

  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 14) {
        exportCard
        summaryCards
        milesByClientSection
        advancedReportsSection
        recentConfirmedSection
      }
      .padding(.horizontal, DesignConstants.Spacing.md)
      .padding(.vertical, DesignConstants.Spacing.sm)
    }
    .background(.background)
    .navigationTitle("Reports")
    .sheet(item: $shareItem) { item in
      ActivityShareSheet(items: [item.url])
    }
    .sheet(isPresented: $isPresentingCustomRange) {
      CustomRangeSheet(
        start: Binding(
          get: { customRange?.start ?? Date() },
          set: { newValue in
            let end = customRange?.end ?? Date()
            customRange = ExportDateRange(start: newValue, end: end)
          }
        ),
        end: Binding(
          get: { customRange?.end ?? Date() },
          set: { newValue in
            let start = customRange?.start ?? Date()
            customRange = ExportDateRange(start: start, end: newValue)
          }
        )
      )
      .presentationDetents([.medium])
    }
  }

  private var confirmedTrips: [Trip] {
    tripStore.confirmedTrips
  }

  private var filteredConfirmedTrips: [Trip] {
    let range = exportService.range(for: rangePreset, custom: customRange)
    return exportService.confirmedTrips(
      in: range,
      from: tripStore.trips,
      category: selectedCategory,
      client: selectedClient,
      projectCode: selectedProject
    )
  }

  private var totalMiles: Double {
    filteredConfirmedTrips.reduce(0) { $0 + $1.distanceMiles }
  }

  private var estimatedValue: Double {
    // Simple estimate for personal planning (not tax/legal advice).
    totalMiles * 0.60
  }

  private var exportCard: some View {
    GlassCard {
      VStack(alignment: .leading, spacing: 12) {
        Text("Export")
          .font(.headline)

        VStack(alignment: .leading, spacing: 10) {
          Picker("Date Range", selection: $rangePreset) {
            Text(ExportDateRangePreset.monthToDate.rawValue).tag(ExportDateRangePreset.monthToDate)
            Text(ExportDateRangePreset.yearToDate.rawValue).tag(ExportDateRangePreset.yearToDate)
            Text(ExportDateRangePreset.year.rawValue).tag(ExportDateRangePreset.year)
            Text(ExportDateRangePreset.custom.rawValue).tag(ExportDateRangePreset.custom)
          }
          .pickerStyle(.menu)
          .accessibilityLabel("Date range")
          .onChange(of: rangePreset) { _, newValue in
            if newValue == .custom {
              // Optional gating: Custom range requires Pro.
              if subscriptionManager.canAccessAdvancedReports {
                filtersMessage = nil
                if customRange == nil {
                  let now = Date()
                  customRange = ExportDateRange(start: now, end: now)
                }
                isPresentingCustomRange = true
              } else {
                filtersMessage = "Custom date range requires Pro."
                rangePreset = .monthToDate
              }
            }
          }

          if rangePreset == .custom, let customRange {
            Text("Custom: \(customRange.start.formatted(date: .abbreviated, time: .omitted)) → \(customRange.end.formatted(date: .abbreviated, time: .omitted))")
              .font(.footnote)
              .foregroundStyle(.secondary)
          } else if rangePreset == .custom {
            // When Pro-gated, we revert selection; this is a defensive fallback.
            EmptyView()
          }
        }

        DisclosureGroup("Filters") {
          VStack(alignment: .leading, spacing: DesignConstants.Spacing.xs) {
            Picker("Category", selection: Binding(
              get: { selectedCategory ?? "" },
              set: { selectedCategory = $0.isEmpty ? nil : $0 }
            )) {
              Text("All").tag("")
              ForEach(categoriesStore.categories, id: \.self) { cat in
                Text(cat).tag(cat)
              }
            }
            .pickerStyle(.menu)

            Picker("Client", selection: Binding(
              get: { selectedClient ?? "" },
              set: { selectedClient = $0.isEmpty ? nil : $0 }
            )) {
              Text("All").tag("")
              ForEach(clientStore.clients, id: \.self) { client in
                Text(client).tag(client)
              }
            }
            .pickerStyle(.menu)

            Picker("Project", selection: Binding(
              get: { selectedProject ?? "" },
              set: { selectedProject = $0.isEmpty ? nil : $0 }
            )) {
              Text("All").tag("")
              ForEach(projectCodesInScope, id: \.self) { code in
                Text(code).tag(code)
              }
            }
            .pickerStyle(.menu)

            if let filtersMessage {
              HStack(spacing: 8) {
                Text(filtersMessage)
                  .font(.footnote)
                  .foregroundStyle(.secondary)
                ProBadge()
                  .accessibilityHidden(true)
              }
            }
          }
          .padding(.top, 8)
        }
        .font(.subheadline.weight(.semibold))
        .accessibilityLabel("Filters")

        PrimaryGlassButton(title: "Export CSV", systemImage: "square.and.arrow.up") {
          exportCSV()
        }
        .accessibilityHint("Exports confirmed trips as a CSV file.")

        if subscriptionManager.canExportPDF {
          PrimaryGlassButton(title: "Export PDF", systemImage: "doc.richtext") {
            exportPDF()
          }
          .accessibilityHint("Exports a PDF summary for the selected range.")
        } else {
          ZStack {
            GlassCard {
              VStack(alignment: .leading, spacing: 8) {
                Text("Export PDF")
                  .font(.subheadline.weight(.semibold))
                Text("Upgrade to Pro to export a PDF summary.")
                  .font(.footnote)
                  .foregroundStyle(.secondary)
              }
            }
            LockedOverlay(message: "Export PDF")
              .padding(6)
          }

          PrimaryGlassButton(title: "Upgrade to Pro", systemImage: "sparkles") {
            if let onUpgradeToPro {
              onUpgradeToPro()
            } else {
              // Future: Wire to Settings tab selection for upgrade prompts.
            }
          }
          .accessibilityHint("Shows upgrade options in Settings (no purchases).")
        }

        if let exportErrorMessage {
          Text(exportErrorMessage)
            .font(.footnote)
            .foregroundStyle(.red)
        } else {
          Text("Exports confirmed trips only. Pending Inbox items are excluded.")
            .font(.footnote)
            .foregroundStyle(.secondary)
        }
      }
    }
  }

  private var projectCodesInScope: [String] {
    let codes = filteredConfirmedTrips.compactMap { trip in
      let trimmed = (trip.projectCode ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
      return trimmed.isEmpty ? nil : trimmed
    }
    return Array(Set(codes)).sorted()
  }

  private var summaryCards: some View {
    HStack(spacing: 12) {
      MetricTile(
        title: "Total Miles",
        value: milesFormatted(totalMiles),
        systemImage: "gauge",
        footnote: "Confirmed only"
      )
      MetricTile(
        title: "Estimated Value",
        value: currencyFormatted(estimatedValue),
        systemImage: "dollarsign.circle",
        footnote: "Estimate"
      )
    }
  }

  private var milesByClientSection: some View {
    let rows = milesByClientRows(trips: filteredConfirmedTrips)

    return VStack(alignment: .leading, spacing: 10) {
      HStack(spacing: 8) {
        Text("Miles by Client")
          .font(.headline)
        if subscriptionManager.status.tier == .free {
          ProBadge()
        }
      }

      if subscriptionManager.canAccessAdvancedReports {
        if rows.isEmpty {
          GlassCard {
            Text("No client-attributed miles in this range.")
              .font(.footnote)
              .foregroundStyle(.secondary)
          }
        } else {
          GlassCard {
            VStack(spacing: 10) {
              ForEach(rows, id: \.client) { row in
                HStack {
                  Text(row.client)
                    .font(.subheadline.weight(.semibold))
                    .lineLimit(1)
                  Spacer(minLength: 0)
                  Text(milesFormatted(row.miles))
                    .font(.subheadline.weight(.semibold))
                }
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("\(row.client), \(milesFormatted(row.miles))")
              }
            }
          }
        }
      } else {
        ZStack {
          GlassCard {
            VStack(alignment: .leading, spacing: 8) {
              Text("Client breakdown")
                .font(.subheadline.weight(.semibold))
              Text("Upgrade to see miles grouped by client.")
                .font(.footnote)
                .foregroundStyle(.secondary)
            }
          }
          LockedOverlay(message: "Client breakdown")
            .padding(6)
        }
      }
    }
  }

  private struct MilesByClientRow {
    let client: String
    let miles: Double
  }

  private func milesByClientRows(trips: [Trip]) -> [MilesByClientRow] {
    var totals: [String: Double] = [:]
    for trip in trips where trip.state == .confirmed {
      let client = trip.clientOrOrg?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
      guard !client.isEmpty else { continue }
      totals[client, default: 0] += trip.distanceMiles
    }
    return totals
      .map { MilesByClientRow(client: $0.key, miles: $0.value) }
      .sorted { $0.miles > $1.miles }
  }

  private var advancedReportsSection: some View {
    VStack(alignment: .leading, spacing: 10) {
      HStack(spacing: 8) {
        Text("Advanced Reports")
          .font(.headline)
        if subscriptionManager.status.tier == .free {
          ProBadge()
        }
      }

      if subscriptionManager.canAccessAdvancedReports {
        GlassCard {
          VStack(alignment: .leading, spacing: 10) {
            Text("Advanced reports")
              .font(.subheadline.weight(.semibold))
            Text("More breakdowns and export options appear here with Pro.")
              .font(.footnote)
              .foregroundStyle(.secondary)
          }
        }
      } else {
        ZStack {
          GlassCard {
            VStack(alignment: .leading, spacing: 10) {
              Text("Advanced sections")
                .font(.subheadline.weight(.semibold))
              Text("Upgrade to unlock deeper breakdowns and additional exports.")
                .font(.footnote)
                .foregroundStyle(.secondary)
            }
          }
          LockedOverlay(message: "Advanced Reports")
            .padding(6)
        }

        PrimaryGlassButton(title: "Upgrade to Pro", systemImage: "sparkles") {
          if let onUpgradeToPro {
            onUpgradeToPro()
          } else {
            // Future: Wire to Settings tab selection for upgrade prompts.
          }
        }
        .accessibilityHint("Shows upgrade options in Settings (no purchases).")
      }
    }
  }

  private var recentConfirmedSection: some View {
    VStack(alignment: .leading, spacing: 10) {
      Text("Recent Confirmed")
        .font(.headline)

      if filteredConfirmedTrips.isEmpty {
        EmptyStateView(
          systemImage: "chart.bar",
          title: "No confirmed trips",
          subtitle: "Confirm trips in Inbox to see reports."
        )
      } else {
        VStack(spacing: 10) {
          ForEach(Array(filteredConfirmedTrips.prefix(5)), id: \.id) { trip in
            GlassCard {
              HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 6) {
                  Text(routeLabel(trip))
                    .font(.subheadline.weight(.semibold))
                    .lineLimit(2)
                    .minimumScaleFactor(0.85)

                  HStack(spacing: 10) {
                    Text(trip.date, format: .dateTime.month().day())
                      .foregroundStyle(.secondary)
                    if let category = trip.category, !category.isEmpty {
                      Text(category)
                        .foregroundStyle(.secondary)
                    }
                  }
                  .font(.footnote)
                }

                Spacer(minLength: 0)

                Text(milesFormatted(trip.distanceMiles))
                  .font(.subheadline.weight(.semibold))
              }
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Trip, \(routeLabel(trip)), \(milesFormatted(trip.distanceMiles))")
          }
        }
      }
    }
  }

  private func milesFormatted(_ miles: Double) -> String {
    let number = miles.formatted(.number.precision(.fractionLength(0...1)))
    return "\(number) mi"
  }

  private func currencyFormatted(_ value: Double) -> String {
    value.formatted(.currency(code: Locale.current.currency?.identifier ?? "USD"))
  }

  private func routeLabel(_ trip: Trip) -> String {
    let start = trip.startLabel?.trimmingCharacters(in: .whitespacesAndNewlines)
    let end = trip.endLabel?.trimmingCharacters(in: .whitespacesAndNewlines)
    if let start, !start.isEmpty, let end, !end.isEmpty { return "\(start) → \(end)" }
    if let start, !start.isEmpty { return start }
    if let end, !end.isEmpty { return end }
    return "Trip"
  }

  private func exportCSV() {
    exportErrorMessage = nil

    let trips = filteredConfirmedTrips

    guard !trips.isEmpty else {
      exportErrorMessage = "No confirmed trips in the selected range."
      return
    }

    let csv = exportService.makeCSV(trips: trips)
    let df = DateFormatter()
    df.locale = Locale(identifier: "en_US_POSIX")
    df.dateFormat = "yyyy-MM-dd_HHmm"
    let stamp = df.string(from: Date())
    let filename = "MileTrack_ConfirmedTrips_\(rangePreset.rawValue)_\(stamp)"

    do {
      let url = try exportService.writeCSVToTemporaryFile(csv: csv, filename: filename)
      shareItem = ShareItem(url: url)
    } catch {
      exportErrorMessage = "Export failed. Please try again."
    }
  }

  private func exportPDF() {
    exportErrorMessage = nil

    let trips = filteredConfirmedTrips
    guard !trips.isEmpty else {
      exportErrorMessage = "No confirmed trips in the selected range."
      return
    }

    let range = exportService.range(for: rangePreset, custom: customRange)

    let df = DateFormatter()
    df.locale = Locale(identifier: "en_US_POSIX")
    df.dateFormat = "yyyy-MM-dd_HHmm"
    let stamp = df.string(from: Date())
    let filename = "MileTrack_Summary_\(rangePreset.rawValue)_\(stamp)"

    do {
      let url = try pdfExportService.writeSummaryPDFToTemporaryFile(
        trips: trips,
        range: range,
        includeClientBreakdown: subscriptionManager.canAccessAdvancedReports,
        filename: filename
      )
      shareItem = ShareItem(url: url)
    } catch {
      exportErrorMessage = "PDF export failed. Please try again."
    }
  }
}

private struct CustomRangeSheet: View {
  @Environment(\.dismiss) private var dismiss
  @Binding var start: Date
  @Binding var end: Date

  var body: some View {
    NavigationStack {
      Form {
        Section("Start") {
          DatePicker("Start Date", selection: $start, displayedComponents: [.date])
        }
        Section("End") {
          DatePicker("End Date", selection: $end, displayedComponents: [.date])
        }
        Section {
          Text("Exports confirmed trips only.")
            .font(.footnote)
            .foregroundStyle(.secondary)
        }
      }
      .navigationTitle("Custom Range")
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .cancellationAction) {
          Button("Done") { dismiss() }
        }
      }
    }
  }
}

private struct ShareItem: Identifiable {
  let id = UUID()
  let url: URL
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
    ReportsView(onUpgradeToPro: {})
  }
  .environmentObject(TripStore())
  .environmentObject(SubscriptionManager())
  .environmentObject(CategoriesStore())
  .environmentObject(ClientStore())
  .environmentObject(RulesStore())
}

