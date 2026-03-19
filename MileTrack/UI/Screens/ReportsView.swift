import SwiftUI
import Charts

struct ReportsView: View {
  @EnvironmentObject private var tripStore: TripStore
  @EnvironmentObject private var subscriptionManager: SubscriptionManager
  @EnvironmentObject private var categoriesStore: CategoriesStore
  @EnvironmentObject private var clientStore: ClientsStore
  @EnvironmentObject private var vehiclesStore: VehiclesStore
  @EnvironmentObject private var mileageRatesStore: MileageRatesStore
  @EnvironmentObject private var receiptsStore: ReceiptsStore

  /// Optional hook for an upgrade flow (no purchases).
  var onUpgradeToPro: (() -> Void)?

  // Date range selection
  enum DateRangeTab: String, CaseIterable {
    case month = "Month"
    case year = "Year"
    case custom = "Custom"
  }
  
  enum MonthOption: Int, CaseIterable, Identifiable {
    case current = 0
    case january = 1
    case february = 2
    case march = 3
    case april = 4
    case may = 5
    case june = 6
    case july = 7
    case august = 8
    case september = 9
    case october = 10
    case november = 11
    case december = 12
    
    var id: Int { rawValue }
    
    var displayName: String {
      switch self {
      case .current: return "Current"
      case .january: return "January"
      case .february: return "February"
      case .march: return "March"
      case .april: return "April"
      case .may: return "May"
      case .june: return "June"
      case .july: return "July"
      case .august: return "August"
      case .september: return "September"
      case .october: return "October"
      case .november: return "November"
      case .december: return "December"
      }
    }
  }

  @State private var selectedDateTab: DateRangeTab = .month
  @State private var selectedMonth: MonthOption = .current
  @State private var selectedYear: Int = Calendar.current.component(.year, from: Date())
  @State private var customRange: ExportDateRange?
  @State private var isPresentingCustomRange: Bool = false

  // Filter selection
  @State private var selectedCategory: String? = nil
  @State private var selectedClient: String? = nil
  @State private var showFilters: Bool = false

  // Charts animation
  @State private var chartsVisible = false

  // Export
  @State private var shareItem: ShareItem?
  @State private var exportErrorMessage: String?
  
  // Edit trip
  @State private var editingTrip: Trip?
  @State private var tripDetailsExpanded = false
  @State private var tripDetailsLimit = 20

  @AppStorage("useMetricUnits") private var useMetricUnits = false

  private let exportService = ExportService()
  private let pdfExportService = PDFExportService()
  private let expenseCalculator = ExpenseCalculator()

  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: DesignConstants.Spacing.md) {
        dateRangeTabs
        summaryCards
        milesChartSection
        categoryChartSection
        filterChips
        exportActions
        milesByClientSection
        recentConfirmedSection
      }
      .padding(.horizontal, DesignConstants.Spacing.md)
      .padding(.vertical, DesignConstants.Spacing.sm)
    }
    .background(.background)
    .navigationTitle("Reports")
    .onAppear {
      withAnimation(.easeOut(duration: 0.55).delay(0.1)) {
        chartsVisible = true
      }
    }
    .onChange(of: selectedDateTab) { _, _ in
      chartsVisible = false
      tripDetailsExpanded = false
      tripDetailsLimit = 20
      withAnimation(.easeOut(duration: 0.55).delay(0.15)) {
        chartsVisible = true
      }
    }
    .onChange(of: selectedMonth) { _, _ in
      tripDetailsExpanded = false
      tripDetailsLimit = 20
    }
    .onChange(of: selectedYear) { _, _ in
      tripDetailsExpanded = false
      tripDetailsLimit = 20
    }
    .sheet(item: $shareItem) { item in
      ActivityShareSheet(items: [item.url])
    }
    .sheet(item: $editingTrip) { trip in
      EditTripSheet(tripID: trip.id)
        .environmentObject(tripStore)
        .environmentObject(categoriesStore)
        .environmentObject(clientStore)
    }
    .sheet(isPresented: $isPresentingCustomRange) {
      CustomRangeSheet(
        start: Binding(
          get: { customRange?.start ?? Calendar.current.date(byAdding: .month, value: -1, to: Date()) ?? Date() },
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

  // MARK: - Computed Properties

  private var rangePreset: ExportDateRangePreset {
    switch selectedDateTab {
    case .month: return .monthToDate
    case .year: return .yearToDate
    case .custom: return .custom
    }
  }
  
  private var effectiveDateRange: ExportDateRange {
    switch selectedDateTab {
    case .month:
      return dateRangeForMonth(selectedMonth, year: selectedYear)
    case .year:
      return dateRangeForYear(selectedYear)
    case .custom:
      return customRange ?? exportService.range(for: .custom, custom: nil)
    }
  }

  private var filteredConfirmedTrips: [Trip] {
    return exportService.confirmedTrips(
      in: effectiveDateRange,
      from: tripStore.trips,
      category: selectedCategory,
      client: selectedClient,
      projectCode: nil
    )
  }
  
  private func dateRangeForMonth(_ month: MonthOption, year: Int) -> ExportDateRange {
    let calendar = Calendar.current
    let now = Date()
    
    if month == .current {
      // Month to date
      let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: now)) ?? now
      return ExportDateRange(start: startOfMonth, end: now)
    } else {
      // Specific month
      var components = DateComponents()
      components.year = year
      components.month = month.rawValue
      components.day = 1
      
      guard let startOfMonth = calendar.date(from: components) else {
        return ExportDateRange(start: now, end: now)
      }
      
      guard let endOfMonth = calendar.date(byAdding: DateComponents(month: 1, day: -1), to: startOfMonth) else {
        return ExportDateRange(start: startOfMonth, end: startOfMonth)
      }
      
      // Set end time to end of day
      let endOfDay = calendar.date(bySettingHour: 23, minute: 59, second: 59, of: endOfMonth) ?? endOfMonth
      
      return ExportDateRange(start: startOfMonth, end: endOfDay)
    }
  }
  
  private func dateRangeForYear(_ year: Int) -> ExportDateRange {
    let calendar = Calendar.current
    let now = Date()
    let currentYear = calendar.component(.year, from: now)
    
    if year == currentYear {
      // Year to date
      var components = DateComponents()
      components.year = year
      components.month = 1
      components.day = 1
      
      guard let startOfYear = calendar.date(from: components) else {
        return ExportDateRange(start: now, end: now)
      }
      
      return ExportDateRange(start: startOfYear, end: now)
    } else {
      // Specific year
      var startComponents = DateComponents()
      startComponents.year = year
      startComponents.month = 1
      startComponents.day = 1
      
      var endComponents = DateComponents()
      endComponents.year = year
      endComponents.month = 12
      endComponents.day = 31
      
      guard let startOfYear = calendar.date(from: startComponents),
            let endOfYear = calendar.date(from: endComponents) else {
        return ExportDateRange(start: now, end: now)
      }
      
      let endOfDay = calendar.date(bySettingHour: 23, minute: 59, second: 59, of: endOfYear) ?? endOfYear
      
      return ExportDateRange(start: startOfYear, end: endOfDay)
    }
  }

  private var totalMiles: Double {
    filteredConfirmedTrips.reduce(0) { $0 + $1.distanceMiles }
  }

  private var estimatedValue: Decimal {
    filteredConfirmedTrips.reduce(Decimal(0)) { acc, trip in
      let rate = mileageRatesStore.rate(for: trip)?.ratePerMile ?? Decimal(string: "0.70")!
      return acc + Decimal(trip.distanceMiles) * rate
    }
  }

  /// The effective rate shown in the footnote (first active rate, or fallback).
  private var effectiveRateFootnote: String {
    if let rate = mileageRatesStore.rates.first(where: { $0.isActive(on: Date()) }) {
      let formatted = NumberFormatter()
      formatted.numberStyle = .currency
      formatted.currencyCode = "USD"
      formatted.maximumFractionDigits = 2
      let rateStr = formatted.string(from: rate.ratePerMile as NSNumber) ?? "$0.70"
      return "@ \(rateStr)/mi"
    }
    return "@ $0.70/mi"
  }

  private var tripCount: Int {
    filteredConfirmedTrips.count
  }

  private var hasActiveFilters: Bool {
    selectedCategory != nil || selectedClient != nil
  }

  // MARK: - Charts

  private struct ChartPoint: Identifiable {
    let id: String
    let label: String
    let miles: Double
  }

  private var monthlyChartData: [ChartPoint] {
    let calendar = Calendar.current
    var totals: [Int: Double] = [:]
    for trip in filteredConfirmedTrips {
      let month = calendar.component(.month, from: trip.date)
      totals[month, default: 0] += trip.distanceMiles
    }
    let formatter = DateFormatter()
    formatter.dateFormat = "MMM"
    return (1...12).compactMap { month -> ChartPoint? in
      guard let miles = totals[month] else { return nil }
      var components = DateComponents()
      components.year = 2000
      components.month = month
      components.day = 1
      let label = calendar.date(from: components).map { formatter.string(from: $0) } ?? "\(month)"
      return ChartPoint(id: "\(month)", label: label, miles: miles)
    }
  }

  private var dailyChartData: [ChartPoint] {
    let calendar = Calendar.current
    var totals: [Int: Double] = [:]
    for trip in filteredConfirmedTrips {
      let day = calendar.component(.day, from: trip.date)
      totals[day, default: 0] += trip.distanceMiles
    }
    return totals
      .sorted { $0.key < $1.key }
      .map { ChartPoint(id: "\($0.key)", label: "\($0.key)", miles: $0.value) }
  }

  @ViewBuilder
  private var milesChartSection: some View {
    let data = selectedDateTab == .month ? dailyChartData : monthlyChartData
    if !data.isEmpty {
      VStack(alignment: .leading, spacing: DesignConstants.Spacing.sm) {
        Text(selectedDateTab == .month ? "Daily miles" : "Miles by month")
          .font(.subheadline.weight(.semibold))
          .foregroundStyle(.secondary)

        GlassCard {
          Chart(data) { point in
            BarMark(
              x: .value("Period", point.label),
              y: .value("Miles", chartsVisible ? point.miles : 0)
            )
            .foregroundStyle(Color.accentColor.gradient)
            .cornerRadius(3)
          }
          .animation(.easeOut(duration: 0.55).delay(0.1), value: chartsVisible)
          .frame(height: 150)
          .chartYAxis {
            AxisMarks(position: .leading) { value in
              AxisGridLine()
              AxisValueLabel {
                if let v = value.as(Double.self) {
                  Text(DistanceFormatter.format(v))
                    .font(.caption2)
                }
              }
            }
          }
          .chartXAxis {
            AxisMarks { value in
              AxisValueLabel {
                if let str = value.as(String.self) {
                  Text(str).font(.caption2)
                }
              }
            }
          }
        }
      }
    }
  }

  private var categoryChartData: [ChartPoint] {
    var totals: [String: Double] = [:]
    for trip in filteredConfirmedTrips {
      let cat = trip.category?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
      guard !cat.isEmpty else { continue }
      totals[cat, default: 0] += trip.distanceMiles
    }
    return totals
      .sorted { $0.value > $1.value }
      .prefix(7)
      .map { ChartPoint(id: $0.key, label: $0.key, miles: $0.value) }
  }

  @ViewBuilder
  private var categoryChartSection: some View {
    let data = categoryChartData
    if !data.isEmpty {
      VStack(alignment: .leading, spacing: DesignConstants.Spacing.sm) {
        Text("By category")
          .font(.subheadline.weight(.semibold))
          .foregroundStyle(.secondary)

        GlassCard {
          Chart(data) { point in
            BarMark(
              x: .value("Miles", chartsVisible ? point.miles : 0),
              y: .value("Category", point.label)
            )
            .foregroundStyle(Color.accentColor.gradient)
            .cornerRadius(3)
            .annotation(position: .trailing, alignment: .leading) {
              Text(DistanceFormatter.format(point.miles))
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.secondary)
                .fixedSize()
            }
          }
          .animation(.easeOut(duration: 0.55).delay(0.1), value: chartsVisible)
          .frame(height: CGFloat(max(80, data.count * 36)))
          .chartXAxis(.hidden)
          .chartYAxis {
            AxisMarks { value in
              AxisValueLabel {
                if let str = value.as(String.self) {
                  Text(str).font(.caption2)
                }
              }
            }
          }
        }
      }
    }
  }

  // MARK: - Date Range Tabs

  private var dateRangeTabs: some View {
    VStack(alignment: .leading, spacing: DesignConstants.Spacing.sm) {
      Text("Date Range")
        .font(.subheadline.weight(.semibold))
        .foregroundStyle(.secondary)

      HStack(spacing: DesignConstants.Spacing.xs) {
        ForEach(DateRangeTab.allCases, id: \.self) { tab in
          dateTabButton(tab)
        }
      }

      if selectedDateTab == .month {
        monthYearPickers
      } else if selectedDateTab == .year {
        yearPickerOnly
      } else if selectedDateTab == .custom {
        customRangeDisplay
      }
    }
  }
  
  private var monthYearPickers: some View {
    HStack(spacing: 12) {
      Menu {
        Picker("Month", selection: $selectedMonth) {
          ForEach(MonthOption.allCases) { month in
            Text(month.displayName).tag(month)
          }
        }
        .pickerStyle(.inline)
      } label: {
        HStack {
          Text(selectedMonth.displayName)
            .font(.subheadline.weight(.medium))
          Spacer()
          Image(systemName: "chevron.down")
            .font(.caption2)
        }
        .foregroundStyle(.primary)
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(.quaternary.opacity(0.5), in: RoundedRectangle(cornerRadius: 10))
      }
      .buttonStyle(.plain)
      
      Menu {
        Picker("Year", selection: $selectedYear) {
          ForEach(availableYears, id: \.self) { year in
            Text(String(year)).tag(year)
          }
        }
        .pickerStyle(.inline)
      } label: {
        HStack {
          Text(String(selectedYear))
            .font(.subheadline.weight(.medium))
          Spacer()
          Image(systemName: "chevron.down")
            .font(.caption2)
        }
        .foregroundStyle(.primary)
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(.quaternary.opacity(0.5), in: RoundedRectangle(cornerRadius: 10))
      }
      .buttonStyle(.plain)
    }
  }
  
  private var yearPickerOnly: some View {
    Menu {
      Picker("Year", selection: $selectedYear) {
        ForEach(availableYears, id: \.self) { year in
          Text(String(year)).tag(year)
        }
      }
      .pickerStyle(.inline)
    } label: {
      HStack {
        Text(String(selectedYear))
          .font(.subheadline.weight(.medium))
        Spacer()
        Image(systemName: "chevron.down")
          .font(.caption2)
      }
      .foregroundStyle(.primary)
      .padding(.horizontal, 12)
      .padding(.vertical, 10)
      .background(.quaternary.opacity(0.5), in: RoundedRectangle(cornerRadius: 10))
    }
    .buttonStyle(.plain)
  }
  
  private var availableYears: [Int] {
    let currentYear = Calendar.current.component(.year, from: Date())
    // Show last 5 years plus current year
    return Array((currentYear - 5)...currentYear).reversed()
  }

  private func dateTabButton(_ tab: DateRangeTab) -> some View {
    let isSelected = selectedDateTab == tab
    let needsPro = tab == .custom && !subscriptionManager.canAccessAdvancedReports

    return Button {
      if needsPro {
        onUpgradeToPro?()
      } else {
        withAnimation(.easeInOut(duration: 0.2)) {
          selectedDateTab = tab
        }
        if tab == .custom && customRange == nil {
          let now = Date()
          customRange = ExportDateRange(
            start: Calendar.current.date(byAdding: .month, value: -1, to: now) ?? now,
            end: now
          )
          isPresentingCustomRange = true
        }
      }
    } label: {
      HStack(spacing: 4) {
        Text(tab.rawValue)
          .font(.subheadline.weight(isSelected ? .semibold : .medium))
        if needsPro {
          Image(systemName: "lock.fill")
            .font(.caption2)
        }
      }
      .padding(.horizontal, 16)
      .padding(.vertical, 10)
      .frame(maxWidth: .infinity)
      .foregroundStyle(isSelected ? .primary : .secondary)
      .modifier(DateRangeTabGlassModifier(isSelected: isSelected))
    }
    .buttonStyle(.plain)
    .accessibilityLabel("\(tab.rawValue)\(needsPro ? ", requires Pro" : "")")
  }

  private var customRangeDisplay: some View {
    Button {
      isPresentingCustomRange = true
    } label: {
      HStack {
        if let customRange {
          Text("\(customRange.start.formatted(date: .abbreviated, time: .omitted)) → \(customRange.end.formatted(date: .abbreviated, time: .omitted))")
            .font(.footnote.weight(.medium))
        } else {
          Text("Select dates")
            .font(.footnote.weight(.medium))
        }
        Spacer()
        Image(systemName: "calendar")
          .font(.footnote)
      }
      .foregroundStyle(.secondary)
      .padding(.horizontal, 12)
      .padding(.vertical, 8)
      .background(.quaternary.opacity(0.5), in: RoundedRectangle(cornerRadius: 10))
    }
    .buttonStyle(.plain)
  }

  // MARK: - Summary Cards

  private var summaryCards: some View {
    HStack(spacing: DesignConstants.Spacing.sm) {
      MetricTile(
        title: "Distance",
        value: milesFormatted(totalMiles),
        systemImage: "gauge.with.needle",
        footnote: "\(tripCount) trips"
      )
      MetricTile(
        title: "Est. Value",
        value: currencyFormatted(estimatedValue),
        systemImage: "dollarsign.circle",
        footnote: effectiveRateFootnote
      )
    }
  }

  // MARK: - Filter Chips

  private var filterChips: some View {
    VStack(alignment: .leading, spacing: DesignConstants.Spacing.sm) {
      HStack {
        Text("Filters")
          .font(.subheadline.weight(.semibold))
          .foregroundStyle(.secondary)

        Spacer()

        if hasActiveFilters {
          Button("Clear") {
            withAnimation {
              selectedCategory = nil
              selectedClient = nil
            }
          }
          .font(.caption.weight(.medium))
          .foregroundStyle(.secondary)
        }
      }

      ScrollView(.horizontal, showsIndicators: false) {
        HStack(spacing: DesignConstants.Spacing.xs) {
          // Category filter
          filterMenu(
            title: selectedCategory ?? "Category",
            isActive: selectedCategory != nil,
            options: categoriesStore.categories,
            selection: $selectedCategory
          )

          // Client filter
          filterMenu(
            title: selectedClient ?? "Client",
            isActive: selectedClient != nil,
            options: clientStore.clients,
            selection: $selectedClient
          )
        }
      }
    }
  }

  private func filterMenu(
    title: String,
    isActive: Bool,
    options: [String],
    selection: Binding<String?>
  ) -> some View {
    Menu {
      Button("All") {
        selection.wrappedValue = nil
      }
      Divider()
      ForEach(options, id: \.self) { option in
        Button(option) {
          selection.wrappedValue = option
        }
      }
    } label: {
      HStack(spacing: 6) {
        Text(title)
          .font(.subheadline.weight(.medium))
          .lineLimit(1)
        Image(systemName: "chevron.down")
          .font(.caption2.weight(.semibold))
      }
      .padding(.horizontal, 14)
      .padding(.vertical, 9)
      .foregroundStyle(isActive ? .primary : .secondary)
      .modifier(MonthButtonGlassModifier(isActive: isActive))
    }
    .buttonStyle(.plain)
  }

  // MARK: - Export Actions

  private var exportActions: some View {
    VStack(spacing: DesignConstants.Spacing.sm) {
      HStack(spacing: DesignConstants.Spacing.sm) {
        exportButton(title: "CSV", icon: "doc.text", action: exportCSV)
        exportButton(title: "PDF", icon: "doc.richtext", isPro: !subscriptionManager.canExportPDF, action: exportPDF)
      }

      if let exportErrorMessage {
        Text(exportErrorMessage)
          .font(.caption)
          .foregroundStyle(.red)
      }
    }
  }

  private func exportButton(title: String, icon: String, isPro: Bool = false, action: @escaping () -> Void) -> some View {
    Button {
      if isPro {
        onUpgradeToPro?()
      } else {
        action()
      }
    } label: {
      HStack(spacing: 8) {
        Image(systemName: icon)
          .font(.subheadline)
        Text(title)
          .font(.subheadline.weight(.semibold))
        if isPro {
          ProBadge()
        }
      }
      .frame(maxWidth: .infinity)
      .padding(.vertical, 12)
      .modifier(ExportButtonGlassModifier())
    }
    .buttonStyle(.plain)
    .opacity(isPro ? 0.7 : 1)
  }

  // MARK: - Miles by Client

  private var milesByClientSection: some View {
    let rows = milesByClientRows(trips: filteredConfirmedTrips)

    return VStack(alignment: .leading, spacing: DesignConstants.Spacing.sm) {
      HStack(spacing: 8) {
        Text("By Client")
          .font(.subheadline.weight(.semibold))
          .foregroundStyle(.secondary)
        if !subscriptionManager.canAccessAdvancedReports {
          ProBadge()
        }
      }

      if subscriptionManager.canAccessAdvancedReports {
        if rows.isEmpty {
          Text("No client-attributed miles")
            .font(.footnote)
            .foregroundStyle(.tertiary)
            .padding(.vertical, 8)
        } else {
          GlassCard {
            VStack(spacing: 12) {
              ForEach(rows, id: \.client) { row in
                HStack {
                  Text(row.client)
                    .font(.subheadline)
                    .lineLimit(1)
                  Spacer(minLength: 0)
                  Text(milesFormatted(row.miles))
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)
                }
              }
            }
          }
        }
      } else {
        Button {
          onUpgradeToPro?()
        } label: {
          HStack {
            Text("Upgrade to see breakdown")
              .font(.footnote)
            Spacer()
            Image(systemName: "chevron.right")
              .font(.caption)
          }
          .foregroundStyle(.secondary)
          .padding(12)
          .modifier(UpgradePromptGlassModifier())
        }
        .buttonStyle(.plain)
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

  // MARK: - Recent Confirmed

  private var recentConfirmedSection: some View {
    VStack(alignment: .leading, spacing: DesignConstants.Spacing.sm) {
      Button {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
          tripDetailsExpanded.toggle()
          if tripDetailsExpanded {
            tripDetailsLimit = 20
          }
        }
      } label: {
        HStack {
          Text("Trip Details")
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(.secondary)
          Spacer()
          Text("\(filteredConfirmedTrips.count) trips")
            .font(.caption.weight(.medium))
            .foregroundStyle(.tertiary)
          Image(systemName: "chevron.right")
            .font(.caption.weight(.semibold))
            .foregroundStyle(.tertiary)
            .rotationEffect(.degrees(tripDetailsExpanded ? 90 : 0))
        }
      }
      .buttonStyle(.plain)

      if filteredConfirmedTrips.isEmpty {
        EmptyStateView(
          systemImage: "chart.bar",
          title: "No trips",
          subtitle: "Confirm trips in Inbox to see reports."
        )
      } else if tripDetailsExpanded {
        let trips = filteredConfirmedTrips
        let visible = Array(trips.prefix(tripDetailsLimit))
        let remaining = trips.count - visible.count

        VStack(spacing: DesignConstants.Spacing.sm) {
          ForEach(visible, id: \.id) { trip in
            tripRow(trip)
          }

          if remaining > 0 {
            Button {
              withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                tripDetailsLimit += 20
              }
            } label: {
              Text("Show more (\(remaining) remaining)")
                .font(.subheadline.weight(.medium))
                .foregroundStyle(Color.accentColor)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
            }
            .buttonStyle(.plain)
          }
        }
      }
    }
  }

  private func tripRow(_ trip: Trip) -> some View {
    Button {
      editingTrip = trip
    } label: {
      GlassCard {
        VStack(alignment: .leading, spacing: 10) {
          // Header: Date and Mileage
          HStack(alignment: .firstTextBaseline) {
            Text(trip.date, format: .dateTime.month().day().year())
              .font(.subheadline.weight(.semibold))
            
            Spacer(minLength: 0)
            
            Text(milesFormatted(trip.distanceMiles))
              .font(.subheadline.weight(.bold))
              .foregroundStyle(.secondary)
          }
          
          // Route — addresses when available, label chain as fallback
          tripRouteView(trip)
          
          // Expense Calculation
          if let calculation = expenseCalculator.calculateExpense(
            for: trip,
            rates: mileageRatesStore.rates,
            receipts: receiptsStore.receipts
          ) {
            Divider()
              .padding(.vertical, 4)
            
            VStack(alignment: .leading, spacing: 6) {
              // Mileage expense
              HStack(spacing: 4) {
                Image(systemName: "car.fill")
                  .font(.caption2)
                  .foregroundStyle(.secondary)
                  .frame(width: 14)
                Text("Mileage")
                  .font(.caption)
                  .foregroundStyle(.secondary)
                Spacer()
                Text(calculation.mileageFormula)
                  .font(.caption2.weight(.medium))
                  .foregroundStyle(.secondary)
              }
              
              // Receipts breakdown
              let tripReceipts = receiptsStore.receipts.filter { $0.tripId == trip.id }
              if !tripReceipts.isEmpty {
                ForEach(tripReceipts) { receipt in
                  HStack(spacing: 4) {
                    Image(systemName: receipt.type.systemImage)
                      .font(.caption2)
                      .foregroundStyle(.secondary)
                      .frame(width: 14)
                    Text(receipt.type.displayName)
                      .font(.caption)
                      .foregroundStyle(.secondary)
                    Spacer()
                    if let amount = receipt.amount {
                      Text(formatCurrency(amount))
                        .font(.caption2.weight(.medium))
                        .foregroundStyle(.secondary)
                    }
                  }
                }
              }
              
              // Total
              Divider()
                .padding(.vertical, 2)
              
              HStack(spacing: 4) {
                Text("Total")
                  .font(.caption.weight(.bold))
                  .foregroundStyle(.primary)
                Spacer()
                Text(calculation.formattedTotal())
                  .font(.caption.weight(.bold))
                  .foregroundStyle(.green)
              }
            }
            .padding(.top, 4)
          }
          
          // Category and metadata
          HStack(spacing: 8) {
            if let category = trip.category, !category.isEmpty {
              HStack(spacing: 4) {
                Image(systemName: "tag.fill")
                  .font(.caption2)
                Text(category)
                  .font(.caption.weight(.medium))
              }
              .foregroundStyle(Color.accentColor)
            }
            
            if let client = trip.clientOrOrg, !client.isEmpty {
              HStack(spacing: 4) {
                Image(systemName: "building.2.fill")
                  .font(.caption2)
                Text(client)
                  .font(.caption.weight(.medium))
              }
              .foregroundStyle(.secondary)
            }
            
            Spacer(minLength: 0)
            
            Image(systemName: "chevron.right")
              .font(.caption2)
              .foregroundStyle(.tertiary)
          }
        }
      }
    }
    .buttonStyle(.plain)
    .accessibilityLabel("Trip on \(trip.date.formatted(date: .long, time: .omitted)), \(trip.routeLabel), \(milesFormatted(trip.distanceMiles))")
    .accessibilityHint("Tap to edit trip details.")
  }

  // MARK: - Helpers

  private func milesFormatted(_ miles: Double) -> String {
    DistanceFormatter.format(miles)
  }

  private func currencyFormatted(_ value: Decimal) -> String {
    let formatter = NumberFormatter()
    formatter.numberStyle = .currency
    formatter.currencyCode = Locale.current.currency?.identifier ?? "USD"
    formatter.maximumFractionDigits = 0
    return formatter.string(from: value as NSNumber) ?? "$0"
  }

  private func routeLabel(_ trip: Trip) -> String {
    trip.routeLabel
  }

  /// Two-line address view with colored dots, or single-line label route as fallback.
  @ViewBuilder
  private func tripRouteView(_ trip: Trip) -> some View {
    let startAddr = trip.startAddress?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
    let endAddr   = trip.endAddress?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""

    if !startAddr.isEmpty && !endAddr.isEmpty {
      VStack(alignment: .leading, spacing: 4) {
        tripLocationLine(startAddr, isStart: true)
        if let stops = trip.waypoints?.filter({ !$0.isEmpty }), !stops.isEmpty {
          ForEach(stops, id: \.self) { stop in
            HStack(alignment: .top, spacing: 8) {
              Circle()
                .fill(Color.secondary.opacity(0.35))
                .frame(width: 6, height: 6)
                .padding(.top, 4)
                .padding(.leading, 1)
              Text(stop)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(1)
            }
          }
        }
        tripLocationLine(endAddr, isStart: false)
      }
    } else {
      Text(trip.routeLabel)
        .font(.subheadline.weight(.semibold))
        .lineLimit(2)
    }
  }

  private func tripLocationLine(_ text: String, isStart: Bool) -> some View {
    HStack(alignment: .top, spacing: 8) {
      Circle()
        .fill(isStart ? Color.green : Color.red)
        .frame(width: 7, height: 7)
        .padding(.top, 4)
      Text(text)
        .font(.subheadline.weight(.medium))
        .lineLimit(2)
    }
  }
  
  private func formatCurrency(_ amount: Decimal) -> String {
    let formatter = NumberFormatter()
    formatter.numberStyle = .currency
    formatter.currencyCode = "USD"
    return formatter.string(from: amount as NSNumber) ?? "$0.00"
  }

  // MARK: - Export Functions

  private func exportFilename() -> String {
    let df = DateFormatter()
    df.locale = Locale(identifier: "en_US_POSIX")
    df.dateFormat = "yyyy-MM-dd"
    let range = effectiveDateRange
    let from = df.string(from: range.start)
    let to = df.string(from: range.end)
    return "Mileage_Report_\(from)_to_\(to)"
  }

  private func exportCSV() {
    exportErrorMessage = nil
    let trips = filteredConfirmedTrips

    guard !trips.isEmpty else {
      exportErrorMessage = "No trips to export."
      return
    }

    let csv = exportService.makeCSV(
      trips: trips,
      vehicles: vehiclesStore.vehicles,
      rates: mileageRatesStore.rates,
      receipts: receiptsStore.receipts
    )
    let filename = exportFilename()

    do {
      let url = try exportService.writeCSVToTemporaryFile(csv: csv, filename: filename)
      shareItem = ShareItem(url: url)
    } catch {
      exportErrorMessage = "Export failed."
    }
  }

  private func exportPDF() {
    guard subscriptionManager.canExportPDF else {
      onUpgradeToPro?()
      return
    }

    exportErrorMessage = nil
    let trips = filteredConfirmedTrips

    guard !trips.isEmpty else {
      exportErrorMessage = "No trips to export."
      return
    }

    let range = exportService.range(for: rangePreset, custom: customRange)

    let filename = exportFilename()

    do {
      let url = try pdfExportService.writeSummaryPDFToTemporaryFile(
        trips: trips,
        range: range,
        includeClientBreakdown: subscriptionManager.canAccessAdvancedReports,
        vehicles: vehiclesStore.vehicles,
        rates: mileageRatesStore.rates,
        receipts: receiptsStore.receipts,
        filename: filename
      )
      shareItem = ShareItem(url: url)
    } catch {
      exportErrorMessage = "PDF export failed."
    }
  }
}

// MARK: - Supporting Views

private struct CustomRangeSheet: View {
  @Environment(\.dismiss) private var dismiss
  @Binding var start: Date
  @Binding var end: Date

  private var isInvalidRange: Bool {
    start > end
  }

  var body: some View {
    NavigationStack {
      Form {
        Section("Start Date") {
          DatePicker("Start", selection: $start, in: ...end, displayedComponents: [.date])
            .labelsHidden()
        }
        Section("End Date") {
          DatePicker("End", selection: $end, in: start..., displayedComponents: [.date])
            .labelsHidden()
        }

        if isInvalidRange {
          Section {
            Text("Start date must be before end date")
              .font(.footnote)
              .foregroundStyle(.red)
          }
        }
      }
      .navigationTitle("Custom Range")
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .confirmationAction) {
          Button("Done") { dismiss() }
            .disabled(isInvalidRange)
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

// MARK: - Glass Effect Modifiers with iOS 26 Availability

private struct DateRangeTabGlassModifier: ViewModifier {
  let isSelected: Bool
  
  func body(content: Content) -> some View {
    if #available(iOS 26.0, *) {
      content
        .glassEffect(
          isSelected ? .regular.tint(.accentColor).interactive() : .regular.interactive(),
          in: .rect(cornerRadius: 14)
        )
    } else {
      content
        .background {
          RoundedRectangle(cornerRadius: 14)
            .fill(isSelected ? Color.accentColor.opacity(0.2) : .clear)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 14))
        }
    }
  }
}

private struct MonthButtonGlassModifier: ViewModifier {
  let isActive: Bool
  
  func body(content: Content) -> some View {
    if #available(iOS 26.0, *) {
      content
        .glassEffect(
          isActive ? .regular.tint(.accentColor) : .regular,
          in: .capsule
        )
    } else {
      content
        .background {
          Capsule()
            .fill(isActive ? Color.accentColor.opacity(0.2) : .clear)
            .background(.ultraThinMaterial)
            .clipShape(Capsule())
        }
    }
  }
}

private struct ExportButtonGlassModifier: ViewModifier {
  func body(content: Content) -> some View {
    if #available(iOS 26.0, *) {
      content
        .glassEffect(.regular.interactive(), in: .rect(cornerRadius: 14))
    } else {
      content
        .background {
          RoundedRectangle(cornerRadius: 14)
            .fill(.ultraThinMaterial)
        }
    }
  }
}

private struct UpgradePromptGlassModifier: ViewModifier {
  func body(content: Content) -> some View {
    if #available(iOS 26.0, *) {
      content
        .glassEffect(.regular, in: .rect(cornerRadius: 12))
    } else {
      content
        .background {
          RoundedRectangle(cornerRadius: 12)
            .fill(.ultraThinMaterial)
        }
    }
  }
}

#Preview {
  NavigationStack {
    ReportsView(onUpgradeToPro: {})
  }
  .environmentObject(TripStore())
  .environmentObject(SubscriptionManager())
  .environmentObject(CategoriesStore())
  .environmentObject(ClientsStore())
  .environmentObject(VehiclesStore())
  .environmentObject(RulesStore())
  .environmentObject(MileageRatesStore())
  .environmentObject(ReceiptsStore())
}
