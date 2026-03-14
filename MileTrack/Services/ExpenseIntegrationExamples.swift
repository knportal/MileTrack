import SwiftUI

// MARK: - Example Integration

/// Example showing how to integrate expense features into your main app structure
struct ExpenseIntegrationExample: View {
  // Your existing stores
  @StateObject private var locationsStore = LocationsStore()
  @StateObject private var vehiclesStore = VehiclesStore()
  
  // New expense stores
  @StateObject private var mileageRatesStore = MileageRatesStore()
  @StateObject private var receiptsStore = ReceiptsStore()
  
  var body: some View {
    TabView {
      // Your existing tabs...
      
      // New Expenses tab
      NavigationStack {
        ExpenseReportView(
          trips: sampleTrips,
          ratesStore: mileageRatesStore,
          receiptsStore: receiptsStore
        )
      }
      .tabItem {
        Label("Expenses", systemImage: "dollarsign.circle")
      }
    }
  }
  
  // Sample data for preview
  private var sampleTrips: [Trip] {
    [
      Trip(date: Date(), distanceMiles: 50.0, source: .manual, state: .confirmed, category: "Business", clientOrOrg: "Client A"),
      Trip(date: Date(), distanceMiles: 30.0, source: .manual, state: .confirmed, category: "Business", clientOrOrg: "Client B")
    ]
  }
}

// MARK: - Enhanced Trip Detail with Expenses

struct TripDetailWithExpenses: View {
  let trip: Trip
  @ObservedObject var ratesStore: MileageRatesStore
  @ObservedObject var receiptsStore: ReceiptsStore
  
  private let calculator = ExpenseCalculator()
  
  private var expenseCalculation: ExpenseCalculation? {
    calculator.calculateExpense(
      for: trip,
      rates: ratesStore.rates,
      receipts: receiptsStore.receipts
    )
  }
  
  private var tripReceipts: [TripReceipt] {
    receiptsStore.receipts(for: trip)
  }
  
  var body: some View {
    List {
      // Trip details section
      Section("Trip Details") {
        LabeledContent("Date") {
          Text(trip.date, style: .date)
        }
        
        LabeledContent("Distance") {
          Text("\(String(format: "%.1f", trip.distanceMiles)) mi")
        }
        
        if let start = trip.startLabel {
          LabeledContent("From") {
            Text(start)
          }
        }
        
        if let end = trip.endLabel {
          LabeledContent("To") {
            Text(end)
          }
        }
        
        if let category = trip.category {
          LabeledContent("Category") {
            Text(category)
          }
        }
        
        if let client = trip.clientOrOrg {
          LabeledContent("Client") {
            Text(client)
          }
        }
      }
      
      // Expense calculation
      if let calculation = expenseCalculation {
        Section("Expense Calculation") {
          ExpenseCalculationView(calculation: calculation)
        }
      }
      
      // Receipts section
      Section {
        NavigationLink {
          TripReceiptsView(trip: trip, receiptsStore: receiptsStore)
        } label: {
          HStack {
            Label("Receipts", systemImage: "doc.text")
            Spacer()
            if !tripReceipts.isEmpty {
              Text("\(tripReceipts.count)")
                .foregroundStyle(.secondary)
            }
            if receiptsStore.totalAmount(for: trip) > 0 {
              let formatter = NumberFormatter()
              let _ = { formatter.numberStyle = .currency; formatter.currencyCode = "USD" }()
              Text(formatter.string(from: receiptsStore.totalAmount(for: trip) as NSNumber) ?? "")
                .foregroundStyle(.green)
            }
          }
        }
      }
    }
    .navigationTitle("Trip Details")
  }
}

// MARK: - Trip Row with Inline Expense

struct TripRowWithExpense: View {
  let trip: Trip
  let ratesStore: MileageRatesStore
  let receiptsStore: ReceiptsStore
  
  private let calculator = ExpenseCalculator()
  
  private var calculation: ExpenseCalculation? {
    calculator.calculateExpense(
      for: trip,
      rates: ratesStore.rates,
      receipts: receiptsStore.receipts
    )
  }
  
  var body: some View {
    VStack(alignment: .leading, spacing: 6) {
      // Trip description
      HStack {
        VStack(alignment: .leading, spacing: 2) {
          if let start = trip.startLabel, let end = trip.endLabel {
            Text("\(start) → \(end)")
              .font(.headline)
          } else {
            Text("Trip")
              .font(.headline)
          }
          
          HStack(spacing: 8) {
            Text(trip.date, style: .date)
              .font(.caption)
              .foregroundStyle(.secondary)
            
            Text("•")
              .foregroundStyle(.secondary)
            
            Text("\(String(format: "%.1f", trip.distanceMiles)) mi")
              .font(.caption)
              .foregroundStyle(.secondary)
          }
        }
        
        Spacer()
        
        // Expense badge
        if let calculation {
          VStack(alignment: .trailing, spacing: 2) {
            Text(calculation.formattedTotal())
              .font(.subheadline.bold())
              .foregroundStyle(.green)
            
            Image(systemName: "dollarsign.circle.fill")
              .font(.caption2)
              .foregroundStyle(.green.opacity(0.6))
          }
        }
      }
      
      // Category and client badges
      HStack(spacing: 8) {
        if let category = trip.category {
          CategoryBadge(category: category)
        }
        
        if let client = trip.clientOrOrg {
          Text(client)
            .font(.caption2)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background {
              Capsule()
                .fill(.blue.opacity(0.1))
            }
            .foregroundStyle(.blue)
        }
        
        // Receipt indicator
        let receiptCount = receiptsStore.receipts(for: trip).count
        if receiptCount > 0 {
          HStack(spacing: 2) {
            Image(systemName: "doc.text.fill")
              .font(.caption2)
            Text("\(receiptCount)")
              .font(.caption2)
          }
          .foregroundStyle(.secondary)
        }
      }
    }
    .padding(.vertical, 4)
  }
}

struct CategoryBadge: View {
  let category: String
  
  var body: some View {
    Text(category)
      .font(.caption2)
      .padding(.horizontal, 6)
      .padding(.vertical, 2)
      .background {
        Capsule()
          .fill(.green.opacity(0.1))
      }
      .foregroundStyle(.green)
  }
}

// MARK: - Settings Integration

struct SettingsViewWithExpenses: View {
  @ObservedObject var ratesStore: MileageRatesStore
  @ObservedObject var receiptsStore: ReceiptsStore
  
  var body: some View {
    List {
      // Your existing settings sections...
      
      // Expense settings
      Section("Expenses") {
        NavigationLink {
          MileageRatesView(ratesStore: ratesStore)
        } label: {
          Label("Mileage Rates", systemImage: "dollarsign.circle")
        }
        
        LabeledContent("Active Rate", value: {
          if let rate = ratesStore.activeRates(on: Date()).first {
            let formatter = NumberFormatter()
            formatter.numberStyle = .currency
            formatter.currencyCode = "USD"
            return "\(formatter.string(from: rate.ratePerMile as NSNumber) ?? "")/mi"
          } else {
            return "Not set"
          }
        }() as String)
      }
      
      Section {
        LabeledContent("Total Receipts") {
          Text("\(receiptsStore.receipts.count)")
            .foregroundStyle(.secondary)
        }
      }
    }
    .navigationTitle("Settings")
  }
}

// MARK: - Quick Add Trip with Expense Preview

struct QuickAddTripWithExpense: View {
  @ObservedObject var ratesStore: MileageRatesStore
  
  @State private var distance: String = ""
  @State private var category: String = "Business"
  @State private var client: String = ""
  
  private var estimatedExpense: String {
    guard let miles = Double(distance),
          let rate = ratesStore.activeRates(on: Date()).first else {
      return "$0.00"
    }
    
    let calculation = ExpenseCalculation(
      totalMiles: miles,
      mileageRate: rate.ratePerMile
    )
    
    return calculation.formattedTotal()
  }
  
  var body: some View {
    Form {
      Section {
        TextField("Distance (miles)", text: $distance)
          .keyboardType(.decimalPad)
        
        TextField("Category", text: $category)
        
        TextField("Client", text: $client)
      }
      
      Section {
        HStack {
          Text("Estimated Deduction")
            .font(.headline)
          Spacer()
          Text(estimatedExpense)
            .font(.headline)
            .foregroundStyle(.green)
        }
        
        if let rate = ratesStore.activeRates(on: Date()).first {
          Text("Using \(rate.name) rate")
            .font(.caption)
            .foregroundStyle(.secondary)
        }
      }
      
      Section {
        Button("Add Trip") {
          // Handle trip creation
        }
        .frame(maxWidth: .infinity)
      }
    }
    .navigationTitle("Add Trip")
  }
}

// MARK: - Dashboard Widget with Expense Summary

struct ExpenseDashboardWidget: View {
  let trips: [Trip]
  let ratesStore: MileageRatesStore
  let receiptsStore: ReceiptsStore
  
  private let calculator = ExpenseCalculator()
  
  private var thisMonthTrips: [Trip] {
    let calendar = Calendar.current
    let now = Date()
    return trips.filter { trip in
      trip.state == .confirmed &&
      calendar.isDate(trip.date, equalTo: now, toGranularity: .month)
    }
  }
  
  private var monthlyExpense: ExpenseCalculation {
    calculator.calculateTotalExpense(
      for: thisMonthTrips,
      rates: ratesStore.rates,
      receipts: receiptsStore.receipts
    )
  }
  
  var body: some View {
    VStack(alignment: .leading, spacing: 12) {
      HStack {
        Text("This Month")
          .font(.headline)
        Spacer()
        Image(systemName: "dollarsign.circle.fill")
          .foregroundStyle(.green)
      }
      
      Text(monthlyExpense.formattedTotal())
        .font(.system(size: 32, weight: .bold))
        .foregroundStyle(.green)
      
      HStack(spacing: 16) {
        VStack(alignment: .leading) {
          Text("\(thisMonthTrips.count)")
            .font(.title3.bold())
          Text("Trips")
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        
        Divider()
          .frame(height: 30)
        
        VStack(alignment: .leading) {
          Text("\(Int(monthlyExpense.totalMiles))")
            .font(.title3.bold())
          Text("Miles")
            .font(.caption)
            .foregroundStyle(.secondary)
        }
      }
    }
    .padding()
    .background {
      RoundedRectangle(cornerRadius: 12)
        .fill(.thinMaterial)
    }
  }
}

// MARK: - Previews

#Preview("Trip Detail with Expenses") {
  NavigationStack {
    TripDetailWithExpenses(
      trip: Trip(
        date: Date(),
        distanceMiles: 50.5,
        startLabel: "Home",
        endLabel: "Client Office",
        source: .manual,
        state: .confirmed,
        category: "Business",
        clientOrOrg: "ABC Corp"
      ),
      ratesStore: MileageRatesStore(rates: MileageRate.defaultRates),
      receiptsStore: ReceiptsStore(receipts: [])
    )
  }
}

#Preview("Trip Row with Expense") {
  List {
    TripRowWithExpense(
      trip: Trip(
        date: Date(),
        distanceMiles: 50.5,
        startLabel: "Home",
        endLabel: "Client Office",
        source: .manual,
        state: .confirmed,
        category: "Business",
        clientOrOrg: "ABC Corp"
      ),
      ratesStore: MileageRatesStore(rates: MileageRate.defaultRates),
      receiptsStore: ReceiptsStore(receipts: [])
    )
  }
}

#Preview("Dashboard Widget") {
  ExpenseDashboardWidget(
    trips: [
      Trip(date: Date(), distanceMiles: 50.0, source: .manual, state: .confirmed, category: "Business"),
      Trip(date: Date(), distanceMiles: 30.0, source: .manual, state: .confirmed, category: "Business")
    ],
    ratesStore: MileageRatesStore(rates: MileageRate.defaultRates),
    receiptsStore: ReceiptsStore(receipts: [])
  )
  .padding()
}
