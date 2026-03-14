# Expense Integration Quick Reference Card

## 🎯 Core Components at a Glance

### Data Models
```swift
MileageRate       // Rate definition with date ranges
TripReceipt       // Receipt with optional photo
ExpenseCalculation // Calculation result
```

### Stores (Observable)
```swift
MileageRatesStore  // @Published rates: [MileageRate]
ReceiptsStore      // @Published receipts: [TripReceipt]
```

### Calculator
```swift
ExpenseCalculator  // All calculation logic
```

---

## 📖 Common Tasks

### Initialize Stores
```swift
@StateObject private var ratesStore = MileageRatesStore()
@StateObject private var receiptsStore = ReceiptsStore()
```

### Calculate Single Trip Expense
```swift
let calculator = ExpenseCalculator()
let calculation = calculator.calculateExpense(
    for: trip,
    rates: ratesStore.rates,
    receipts: receiptsStore.receipts
)

// Use calculation
Text(calculation?.formattedTotal() ?? "N/A")
Text(calculation?.mileageFormula ?? "")
```

### Calculate Multiple Trips
```swift
let total = calculator.calculateTotalExpense(
    for: trips,
    rates: ratesStore.rates,
    receipts: receiptsStore.receipts
)
```

### Group by Client
```swift
let byClient = calculator.calculateExpensesByClient(
    trips: trips,
    rates: ratesStore.rates,
    receipts: receiptsStore.receipts
)

// Returns: [String: ExpenseCalculation]
// e.g., ["Client A": calculation, "Client B": calculation]
```

### Group by Category
```swift
let byCategory = calculator.calculateExpensesByCategory(
    trips: trips,
    rates: ratesStore.rates,
    receipts: receiptsStore.receipts
)
```

### Add/Remove Receipts
```swift
// Add simple receipt
receiptsStore.add(receipt)

// Add with photo (iOS)
try receiptsStore.add(receipt, image: uiImage)

// Update
_ = receiptsStore.update(receipt)

// Remove
try receiptsStore.remove(receipt)

// Get receipts for trip
let tripReceipts = receiptsStore.receipts(for: trip)

// Get total amount
let total = receiptsStore.totalAmount(for: trip)
```

### Manage Rates
```swift
// Add rate
ratesStore.add(rate)

// Find best rate for trip
let rate = ratesStore.rate(for: trip)

// Get active rates today
let activeRates = ratesStore.activeRates(on: Date())

// Reset to IRS defaults
ratesStore.resetToDefaults()
```

---

## 🎨 UI Components

### Show Expense Calculation
```swift
ExpenseCalculationView(calculation: calculation)
```

### Inline Expense Badge
```swift
TripExpenseInlineView(trip: trip, calculation: calculation)
```

### Receipt Management
```swift
NavigationLink("Receipts") {
    TripReceiptsView(trip: trip, receiptsStore: receiptsStore)
}
```

### Rate Configuration
```swift
NavigationLink("Mileage Rates") {
    MileageRatesView(ratesStore: ratesStore)
}
```

### Full Report
```swift
ExpenseReportView(
    trips: trips,
    ratesStore: ratesStore,
    receiptsStore: receiptsStore
)
```

---

## 🔢 Default Rates (2026)

```swift
MileageRate.irs2026Business    // $0.70/mi
MileageRate.irs2026Medical     // $0.21/mi
MileageRate.irs2026Charitable  // $0.14/mi

// All defaults
MileageRate.defaultRates
```

---

## 💾 Persistence

### Auto-save (450ms debounce)
```swift
// Automatic when modifying @Published properties
ratesStore.rates.append(newRate)
receiptsStore.receipts.append(newReceipt)
```

### Manual save
```swift
ratesStore.saveNow()
receiptsStore.saveNow()
```

### File locations
```
Application Support/
  └── MileTrack/ (or bundle ID)
      ├── mileage_rates.json
      ├── receipts.json
      └── Receipts/
          ├── {uuid}.jpg
          └── {uuid}.jpg
```

---

## 🧮 Calculation Properties

```swift
calculation.totalMiles        // Double
calculation.mileageRate       // Decimal
calculation.mileageAmount     // Decimal
calculation.receiptsAmount    // Decimal
calculation.totalAmount       // Decimal
calculation.currency          // String

// Formatted strings
calculation.mileageFormula           // "$0.70/mi × 50.0 mi = $35.00"
calculation.formattedTotal()         // "$50.50"
calculation.formattedMileageAmount() // "$35.00"
calculation.formattedReceiptsAmount() // "$15.50"
```

---

## 🏷️ Receipt Types

```swift
enum ReceiptType {
    case parking      // 🅿️ parkingsign.circle
    case toll         // 🛣️ road.lanes
    case fuel         // ⛽ fuelpump
    case maintenance  // 🔧 wrench.and.screwdriver
    case other        // 📄 doc.text
}

receipt.type.displayName   // "Parking"
receipt.type.systemImage   // "parkingsign.circle"
```

---

## 📅 Date Ranges

```swift
enum DateRangeOption {
    case thisWeek
    case thisMonth
    case lastMonth
    case thisYear
    case lastYear
    case allTime
}

dateRange.contains(trip.date) // Bool
```

---

## 🎛️ Grouping Options

```swift
enum GroupingOption {
    case client    // person.crop.circle
    case category  // tag
}
```

---

## ✅ Type Checks

```swift
// Check if rate is active
rate.isActive(on: date) // Bool

// Check calculation exists
if let calculation = calculator.calculateExpense(...) {
    // Use calculation
}
```

---

## 🧪 Testing Helpers

```swift
// Create test data
let testRate = MileageRate(
    name: "Test",
    ratePerMile: 0.70,
    effectiveFrom: Date()
)

let testReceipt = TripReceipt(
    tripId: trip.id,
    type: .parking,
    amount: 10.00
)

// Use in tests
let store = MileageRatesStore(rates: [testRate])
let calculation = calculator.calculateExpense(...)

#expect(calculation?.totalAmount == expectedAmount)
```

---

## 🚦 Common Patterns

### Trip Row with Expense
```swift
HStack {
    VStack(alignment: .leading) {
        Text(trip.description)
        Text("\(trip.distanceMiles) mi")
    }
    Spacer()
    if let calc = calculator.calculateExpense(...) {
        Text(calc.formattedTotal())
            .foregroundStyle(.green)
    }
}
```

### Settings Section
```swift
Section("Expenses") {
    NavigationLink("Rates") {
        MileageRatesView(ratesStore: ratesStore)
    }
    
    LabeledContent("Active Rate") {
        if let rate = ratesStore.activeRates(on: .now).first {
            Text("$\(rate.ratePerMile)/mi")
        }
    }
}
```

### Dashboard Widget
```swift
VStack {
    Text("This Month")
    Text(monthlyExpense.formattedTotal())
        .font(.largeTitle)
    HStack {
        Text("\(trips.count) trips")
        Text("\(Int(totalMiles)) miles")
    }
}
```

---

## 💡 Pro Tips

1. **Reuse Calculator** - Create once per view, not per cell
2. **Cache Calculations** - Store in `@State` for lists
3. **Filter Confirmed Only** - `trips.filter { $0.state == .confirmed }`
4. **Handle Nil Gracefully** - Not all trips may have rates
5. **Save on Background** - Call `.saveNow()` in scenePhase changes

---

## 🔗 File Quick Links

| File | Purpose |
|------|---------|
| `MileageRate.swift` | Rate model + defaults |
| `TripReceipt.swift` | Receipt model |
| `ExpenseCalculator.swift` | All calculations |
| `MileageRatesStore.swift` | Rate management |
| `ReceiptsStore.swift` | Receipt management |
| `ExpenseCalculationView.swift` | Display calculations |
| `TripReceiptsView.swift` | Receipt UI |
| `MileageRatesView.swift` | Rate configuration |
| `ExpenseReportView.swift` | Reporting interface |
| `ExpenseIntegrationExamples.swift` | Copy-paste examples |
| `ExpenseTests.swift` | Test suite |

---

## ⚡ One-Liners

```swift
// Get trip expense
calculator.calculateExpense(for: trip, rates: rates, receipts: receipts)

// Format as string
calculation.mileageFormula

// Total for client
calculator.calculateExpensesByClient(trips: trips, rates: rates, receipts: receipts)["Client A"]

// Active rate
ratesStore.rate(for: trip)

// Receipt count
receiptsStore.receipts(for: trip).count

// Reset rates
ratesStore.resetToDefaults()
```

---

📘 **Full Docs**: `EXPENSE_INTEGRATION_GUIDE.md`
📝 **Examples**: `ExpenseIntegrationExamples.swift`
🧪 **Tests**: `ExpenseTests.swift`
