import SwiftUI

/// Main expense report view showing summaries and breakdowns
struct ExpenseReportView: View {
  let trips: [Trip]
  @ObservedObject var ratesStore: MileageRatesStore
  @ObservedObject var receiptsStore: ReceiptsStore
  
  @State private var selectedDateRange: DateRangeOption = .thisMonth
  @State private var groupBy: GroupingOption = .client
  
  private let calculator = ExpenseCalculator()
  
  private var filteredTrips: [Trip] {
    trips.filter { trip in
      trip.state == .confirmed &&
      selectedDateRange.contains(trip.date)
    }
  }
  
  private var totalExpense: ExpenseCalculation {
    calculator.calculateTotalExpense(
      for: filteredTrips,
      rates: ratesStore.rates,
      receipts: receiptsStore.receipts
    )
  }
  
  var body: some View {
    List {
      // Date range picker
      Section {
        Picker("Period", selection: $selectedDateRange) {
          ForEach(DateRangeOption.allCases, id: \.self) { option in
            Text(option.displayName)
              .tag(option)
          }
        }
        .pickerStyle(.menu)
      }
      
      // Total summary
      Section {
        VStack(alignment: .leading, spacing: 16) {
          VStack(alignment: .leading, spacing: 4) {
            Text("Total Deduction")
              .font(.subheadline)
              .foregroundStyle(.secondary)
            
            Text(totalExpense.formattedTotal())
              .font(.system(size: 42, weight: .bold))
              .foregroundStyle(.green)
          }
          
          HStack(spacing: 24) {
            StatLabel(
              title: "Trips",
              value: "\(filteredTrips.count)",
              systemImage: "car"
            )
            
            StatLabel(
              title: "Miles",
              value: String(format: "%.1f", totalExpense.totalMiles),
              systemImage: "road.lanes"
            )
            
            if totalExpense.receiptsAmount > 0 {
              StatLabel(
                title: "Receipts",
                value: totalExpense.formattedReceiptsAmount(),
                systemImage: "doc.text"
              )
            }
          }
        }
        .padding(.vertical, 8)
      }
      
      // Grouping picker
      Section {
        Picker("Group By", selection: $groupBy) {
          ForEach(GroupingOption.allCases, id: \.self) { option in
            Label(option.displayName, systemImage: option.systemImage)
              .tag(option)
          }
        }
        .pickerStyle(.segmented)
      }
      
      // Grouped expenses
      switch groupBy {
      case .client:
        ClientGroupingSection(
          trips: filteredTrips,
          calculator: calculator,
          ratesStore: ratesStore,
          receiptsStore: receiptsStore
        )
        
      case .category:
        CategoryGroupingSection(
          trips: filteredTrips,
          calculator: calculator,
          ratesStore: ratesStore,
          receiptsStore: receiptsStore
        )
      }
      
      // Export section
      Section {
        Button {
          exportReport()
        } label: {
          Label("Export Report", systemImage: "square.and.arrow.up")
        }
      }
    }
    .navigationTitle("Expense Report")
  }
  
  private func exportReport() {
    // TODO: Implement export functionality (CSV, PDF, etc.)
    print("Export report")
  }
}

// MARK: - Supporting Views

struct StatLabel: View {
  let title: String
  let value: String
  let systemImage: String
  
  var body: some View {
    VStack(alignment: .leading, spacing: 2) {
      Label(title, systemImage: systemImage)
        .font(.caption2)
        .foregroundStyle(.secondary)
      
      Text(value)
        .font(.headline)
    }
  }
}

struct ClientGroupingSection: View {
  let trips: [Trip]
  let calculator: ExpenseCalculator
  let ratesStore: MileageRatesStore
  let receiptsStore: ReceiptsStore
  
  private var expensesByClient: [(String, ExpenseCalculation)] {
    let grouped = calculator.calculateExpensesByClient(
      trips: trips,
      rates: ratesStore.rates,
      receipts: receiptsStore.receipts
    )
    return grouped.sorted { $0.value.totalAmount > $1.value.totalAmount }
  }
  
  var body: some View {
    Section {
      if expensesByClient.isEmpty {
        ContentUnavailableView {
          Label("No Data", systemImage: "chart.bar")
        } description: {
          Text("No confirmed trips in this period")
        }
      } else {
        ForEach(expensesByClient, id: \.0) { client, calculation in
          NavigationLink {
            ClientDetailView(
              client: client,
              trips: trips.filter { ($0.clientOrOrg ?? "Unassigned") == client },
              calculation: calculation,
              ratesStore: ratesStore,
              receiptsStore: receiptsStore
            )
          } label: {
            ExpenseGroupRow(
              title: client,
              calculation: calculation,
              icon: "person.crop.circle"
            )
          }
        }
      }
    } header: {
      Text("By Client")
    }
  }
}

struct CategoryGroupingSection: View {
  let trips: [Trip]
  let calculator: ExpenseCalculator
  let ratesStore: MileageRatesStore
  let receiptsStore: ReceiptsStore
  
  private var expensesByCategory: [(String, ExpenseCalculation)] {
    let grouped = calculator.calculateExpensesByCategory(
      trips: trips,
      rates: ratesStore.rates,
      receipts: receiptsStore.receipts
    )
    return grouped.sorted { $0.value.totalAmount > $1.value.totalAmount }
  }
  
  var body: some View {
    Section {
      if expensesByCategory.isEmpty {
        ContentUnavailableView {
          Label("No Data", systemImage: "chart.bar")
        } description: {
          Text("No confirmed trips in this period")
        }
      } else {
        ForEach(expensesByCategory, id: \.0) { category, calculation in
          NavigationLink {
            CategoryDetailView(
              category: category,
              trips: trips.filter { ($0.category ?? "Uncategorized") == category },
              calculation: calculation,
              ratesStore: ratesStore,
              receiptsStore: receiptsStore
            )
          } label: {
            ExpenseGroupRow(
              title: category,
              calculation: calculation,
              icon: "tag"
            )
          }
        }
      }
    } header: {
      Text("By Category")
    }
  }
}

struct ExpenseGroupRow: View {
  let title: String
  let calculation: ExpenseCalculation
  let icon: String
  
  var body: some View {
    HStack {
      Image(systemName: icon)
        .foregroundStyle(.blue)
      
      VStack(alignment: .leading, spacing: 4) {
        Text(title)
          .font(.headline)
        
        HStack {
          Text("\(Int(calculation.totalMiles)) miles")
            .font(.caption)
            .foregroundStyle(.secondary)
          
          Text("•")
            .foregroundStyle(.secondary)
          
          Text(calculation.mileageFormula)
            .font(.caption)
            .foregroundStyle(.secondary)
        }
      }
      
      Spacer()
      
      Text(calculation.formattedTotal())
        .font(.headline)
        .foregroundStyle(.green)
    }
  }
}

// MARK: - Detail Views

struct ClientDetailView: View {
  let client: String
  let trips: [Trip]
  let calculation: ExpenseCalculation
  let ratesStore: MileageRatesStore
  let receiptsStore: ReceiptsStore
  
  private let calculator = ExpenseCalculator()
  
  var body: some View {
    List {
      Section {
        ExpenseCalculationView(calculation: calculation)
      }
      
      Section {
        ForEach(trips) { trip in
          TripExpenseRow(
            trip: trip,
            calculator: calculator,
            ratesStore: ratesStore,
            receiptsStore: receiptsStore
          )
        }
      } header: {
        Text("Trips (\(trips.count))")
      }
    }
    .navigationTitle(client)
    .navigationBarTitleDisplayMode(.inline)
  }
}

struct CategoryDetailView: View {
  let category: String
  let trips: [Trip]
  let calculation: ExpenseCalculation
  let ratesStore: MileageRatesStore
  let receiptsStore: ReceiptsStore
  
  private let calculator = ExpenseCalculator()
  
  var body: some View {
    List {
      Section {
        ExpenseCalculationView(calculation: calculation)
      }
      
      Section {
        ForEach(trips) { trip in
          TripExpenseRow(
            trip: trip,
            calculator: calculator,
            ratesStore: ratesStore,
            receiptsStore: receiptsStore
          )
        }
      } header: {
        Text("Trips (\(trips.count))")
      }
    }
    .navigationTitle(category)
    .navigationBarTitleDisplayMode(.inline)
  }
}

struct TripExpenseRow: View {
  let trip: Trip
  let calculator: ExpenseCalculator
  let ratesStore: MileageRatesStore
  let receiptsStore: ReceiptsStore
  
  private var calculation: ExpenseCalculation? {
    calculator.calculateExpense(
      for: trip,
      rates: ratesStore.rates,
      receipts: receiptsStore.receipts
    )
  }
  
  var body: some View {
    VStack(alignment: .leading, spacing: 6) {
      HStack {
        VStack(alignment: .leading, spacing: 2) {
          if let start = trip.startLabel, let end = trip.endLabel {
            Text("\(start) → \(end)")
              .font(.subheadline)
          } else {
            Text("Trip")
              .font(.subheadline)
          }
          
          Text(trip.date, style: .date)
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        
        Spacer()
        
        if let calculation {
          VStack(alignment: .trailing, spacing: 2) {
            Text(calculation.formattedTotal())
              .font(.headline)
              .foregroundStyle(.green)
            
            Text("\(String(format: "%.1f", trip.distanceMiles)) mi")
              .font(.caption)
              .foregroundStyle(.secondary)
          }
        }
      }
      
      if let calculation, calculation.receiptsAmount > 0 {
        HStack {
          Image(systemName: "doc.text")
            .font(.caption2)
            .foregroundStyle(.secondary)
          
          Text("\(calculation.formattedReceiptsAmount()) in receipts")
            .font(.caption)
            .foregroundStyle(.secondary)
        }
      }
    }
    .padding(.vertical, 2)
  }
}

// MARK: - Supporting Types

enum DateRangeOption: CaseIterable {
  case thisWeek
  case thisMonth
  case lastMonth
  case thisYear
  case lastYear
  case allTime
  
  var displayName: String {
    switch self {
    case .thisWeek: return "This Week"
    case .thisMonth: return "This Month"
    case .lastMonth: return "Last Month"
    case .thisYear: return "This Year"
    case .lastYear: return "Last Year"
    case .allTime: return "All Time"
    }
  }
  
  func contains(_ date: Date) -> Bool {
    let calendar = Calendar.current
    let now = Date()
    
    switch self {
    case .thisWeek:
      return calendar.isDate(date, equalTo: now, toGranularity: .weekOfYear)
    case .thisMonth:
      return calendar.isDate(date, equalTo: now, toGranularity: .month)
    case .lastMonth:
      guard let lastMonth = calendar.date(byAdding: .month, value: -1, to: now) else {
        return false
      }
      return calendar.isDate(date, equalTo: lastMonth, toGranularity: .month)
    case .thisYear:
      return calendar.isDate(date, equalTo: now, toGranularity: .year)
    case .lastYear:
      guard let lastYear = calendar.date(byAdding: .year, value: -1, to: now) else {
        return false
      }
      return calendar.isDate(date, equalTo: lastYear, toGranularity: .year)
    case .allTime:
      return true
    }
  }
}

enum GroupingOption: String, CaseIterable {
  case client
  case category
  
  var displayName: String {
    switch self {
    case .client: return "Client"
    case .category: return "Category"
    }
  }
  
  var systemImage: String {
    switch self {
    case .client: return "person.crop.circle"
    case .category: return "tag"
    }
  }
}

#Preview("Expense Report") {
  NavigationStack {
    ExpenseReportView(
      trips: [
        Trip(date: Date(), distanceMiles: 50.0, source: .manual, state: .confirmed, category: "Business", clientOrOrg: "Client A"),
        Trip(date: Date(), distanceMiles: 30.0, source: .manual, state: .confirmed, category: "Business", clientOrOrg: "Client B"),
        Trip(date: Date(), distanceMiles: 20.0, source: .manual, state: .confirmed, category: "Medical")
      ],
      ratesStore: MileageRatesStore(rates: MileageRate.defaultRates),
      receiptsStore: ReceiptsStore(receipts: [])
    )
  }
}
