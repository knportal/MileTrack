import SwiftUI

/// Displays expense calculation for a trip or group of trips
struct ExpenseCalculationView: View {
  let calculation: ExpenseCalculation
  let showBreakdown: Bool
  
  init(calculation: ExpenseCalculation, showBreakdown: Bool = true) {
    self.calculation = calculation
    self.showBreakdown = showBreakdown
  }
  
  var body: some View {
    VStack(alignment: .leading, spacing: 8) {
      if showBreakdown {
        // Mileage calculation
        HStack {
          Label("Mileage", systemImage: "car")
            .font(.subheadline)
          Spacer()
          Text(calculation.formattedMileageAmount())
            .font(.subheadline)
            .foregroundStyle(.secondary)
        }
        
        Text(calculation.mileageFormula)
          .font(.caption)
          .foregroundStyle(.secondary)
          .padding(.leading, 28)
        
        // Receipts total
        if calculation.receiptsAmount > 0 {
          HStack {
            Label("Receipts", systemImage: "doc.text")
              .font(.subheadline)
            Spacer()
            Text(calculation.formattedReceiptsAmount())
              .font(.subheadline)
              .foregroundStyle(.secondary)
          }
          .padding(.top, 4)
        }
        
        Divider()
          .padding(.vertical, 4)
      }
      
      // Total
      HStack {
        Text(showBreakdown ? "Total Deduction" : "Estimated Deduction")
          .font(.headline)
        Spacer()
        Text(calculation.formattedTotal())
          .font(.headline)
          .foregroundStyle(.green)
      }
    }
    .padding()
    .background {
      RoundedRectangle(cornerRadius: 12)
        .fill(.thinMaterial)
    }
  }
}

/// Compact inline display of expense for a single trip
struct TripExpenseInlineView: View {
  let trip: Trip
  let calculation: ExpenseCalculation?
  
  var body: some View {
    if let calculation = calculation {
      HStack(spacing: 4) {
        Image(systemName: "dollarsign.circle.fill")
          .font(.caption)
          .foregroundStyle(.green)
        
        Text(calculation.formattedTotal())
          .font(.caption)
          .foregroundStyle(.secondary)
      }
    } else {
      EmptyView()
    }
  }
}

/// View for displaying expense summary by client
struct ClientExpenseSummaryView: View {
  let expensesByClient: [String: ExpenseCalculation]
  let dateRange: String
  
  var sortedClients: [(String, ExpenseCalculation)] {
    expensesByClient.sorted { $0.value.totalAmount > $1.value.totalAmount }
  }
  
  var totalExpense: Decimal {
    expensesByClient.values.reduce(Decimal(0)) { $0 + $1.totalAmount }
  }
  
  var body: some View {
    List {
      Section {
        VStack(alignment: .leading, spacing: 8) {
          Text("Total Expenses")
            .font(.headline)
          Text(dateRange)
            .font(.caption)
            .foregroundStyle(.secondary)
          
          let formatter = NumberFormatter()
          let _ = { formatter.numberStyle = .currency; formatter.currencyCode = "USD" }()
          
          Text(formatter.string(from: totalExpense as NSNumber) ?? "$0.00")
            .font(.largeTitle.bold())
            .foregroundStyle(.green)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical)
      }
      
      Section {
        ForEach(sortedClients, id: \.0) { client, calculation in
          VStack(alignment: .leading, spacing: 8) {
            HStack {
              Text(client)
                .font(.headline)
              Spacer()
              Text(calculation.formattedTotal())
                .font(.headline)
                .foregroundStyle(.green)
            }
            
            HStack {
              Text("\(Int(calculation.totalMiles)) miles")
                .font(.caption)
              Spacer()
              Text(calculation.mileageFormula)
                .font(.caption)
            }
            .foregroundStyle(.secondary)
            
            if calculation.receiptsAmount > 0 {
              Text("+ \(calculation.formattedReceiptsAmount()) in receipts")
                .font(.caption)
                .foregroundStyle(.secondary)
            }
          }
          .padding(.vertical, 4)
        }
      } header: {
        Text("By Client")
      }
    }
  }
}

#Preview("Expense Calculation") {
  ExpenseCalculationView(
    calculation: ExpenseCalculation(
      totalMiles: 50.5,
      mileageRate: 0.70,
      receiptsAmount: 15.50
    )
  )
  .padding()
}

#Preview("Client Summary") {
  ClientExpenseSummaryView(
    expensesByClient: [
      "Client ABC": ExpenseCalculation(totalMiles: 150.0, mileageRate: 0.70, receiptsAmount: 25.00),
      "Client XYZ": ExpenseCalculation(totalMiles: 75.0, mileageRate: 0.70, receiptsAmount: 10.00),
      "Personal": ExpenseCalculation(totalMiles: 30.0, mileageRate: 0.70)
    ],
    dateRange: "January 2026"
  )
}
