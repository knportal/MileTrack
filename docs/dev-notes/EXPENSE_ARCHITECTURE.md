# Expense Integration Architecture

## 🏗️ System Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                         SwiftUI Views                            │
├─────────────────────────────────────────────────────────────────┤
│                                                                   │
│  ExpenseReportView          TripReceiptsView                     │
│  ├─ Date range filters      ├─ Receipt list                      │
│  ├─ Client grouping         ├─ Add/edit receipts                 │
│  ├─ Category grouping       ├─ Photo picker                      │
│  └─ Drill-down detail       └─ Swipe to delete                   │
│                                                                   │
│  MileageRatesView           ExpenseCalculationView               │
│  ├─ Rate configuration      ├─ Mileage formula                   │
│  ├─ Active/inactive         ├─ Receipt totals                    │
│  ├─ Add/edit rates          └─ Combined total                    │
│  └─ Reset to defaults                                            │
│                                                                   │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                      Observable Stores                           │
├─────────────────────────────────────────────────────────────────┤
│                                                                   │
│  MileageRatesStore (@MainActor)                                  │
│  ├─ @Published rates: [MileageRate]                              │
│  ├─ rate(for trip) → MileageRate?                                │
│  ├─ activeRates(on date) → [MileageRate]                         │
│  ├─ add/update/remove                                            │
│  └─ Auto-save with 450ms debounce                                │
│                                                                   │
│  ReceiptsStore (@MainActor)                                      │
│  ├─ @Published receipts: [TripReceipt]                           │
│  ├─ receipts(for trip) → [TripReceipt]                           │
│  ├─ totalAmount(for trip) → Decimal                              │
│  ├─ add/update/remove (with image support)                       │
│  ├─ loadImage(for receipt) → UIImage?                            │
│  └─ Auto-save with 450ms debounce                                │
│                                                                   │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                      Business Logic                              │
├─────────────────────────────────────────────────────────────────┤
│                                                                   │
│  ExpenseCalculator                                               │
│  ├─ calculateExpense(trip) → ExpenseCalculation?                 │
│  ├─ calculateTotalExpense(trips) → ExpenseCalculation            │
│  ├─ calculateExpensesByClient(trips) → [String: ExpenseCalc]     │
│  ├─ calculateExpensesByCategory(trips) → [String: ExpenseCalc]   │
│  └─ Rate matching logic                                          │
│      1. Category + date match                                    │
│      2. Date match only                                          │
│      3. Fallback to first available                              │
│                                                                   │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                      Persistence Layer                           │
├─────────────────────────────────────────────────────────────────┤
│                                                                   │
│  MileageRatesPersistenceStore                                    │
│  ├─ loadRates() → [MileageRate]                                  │
│  ├─ saveRates([MileageRate])                                     │
│  └─ Storage: mileage_rates.json                                  │
│                                                                   │
│  ReceiptsPersistenceStore                                        │
│  ├─ loadReceipts() → [TripReceipt]                               │
│  ├─ saveReceipts([TripReceipt])                                  │
│  ├─ saveImage(Data, fileName) → String                           │
│  ├─ loadImage(fileName) → Data                                   │
│  ├─ deleteImage(fileName)                                        │
│  ├─ Storage: receipts.json                                       │
│  └─ Images: Receipts/{uuid}.jpg                                  │
│                                                                   │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                         File System                              │
├─────────────────────────────────────────────────────────────────┤
│                                                                   │
│  Application Support/MileTrack/                                  │
│  ├─ mileage_rates.json                                           │
│  ├─ receipts.json                                                │
│  └─ Receipts/                                                    │
│      ├─ {uuid-1}.jpg                                             │
│      ├─ {uuid-2}.jpg                                             │
│      └─ {uuid-3}.jpg                                             │
│                                                                   │
└─────────────────────────────────────────────────────────────────┘
```

## 🔄 Data Flow Examples

### Example 1: Calculate Trip Expense

```
User opens trip detail
        │
        ▼
View calls ExpenseCalculator.calculateExpense(
    trip: trip,
    rates: ratesStore.rates,
    receipts: receiptsStore.receipts
)
        │
        ▼
Calculator finds applicable rate:
  1. Check category + date match
  2. Check date match
  3. Use first available
        │
        ▼
Calculator sums receipts for trip
        │
        ▼
Returns ExpenseCalculation(
    totalMiles: 50.0,
    mileageRate: 0.70,
    mileageAmount: 35.0,
    receiptsAmount: 15.5,
    totalAmount: 50.5
)
        │
        ▼
View displays: "$50.50"
```

### Example 2: Add Receipt with Photo

```
User taps "Add Receipt"
        │
        ▼
ReceiptEditSheet presented
        │
        ▼
User selects photo from PhotosPicker
        │
        ▼
User enters amount and details
        │
        ▼
User taps "Save"
        │
        ▼
receiptsStore.add(receipt, image: uiImage)
        │
        ├─► Compress image to JPEG (80%)
        │
        ├─► Save to Receipts/{uuid}.jpg
        │
        ├─► Update receipt with fileName
        │
        └─► Add to receipts array
                │
                ▼
        @Published triggers
                │
                ▼
        450ms debounce timer
                │
                ▼
        persistence.saveReceipts([receipts])
                │
                ▼
        Write to receipts.json
```

### Example 3: Generate Client Report

```
User opens ExpenseReportView
        │
        ▼
User selects date range: "This Month"
        │
        ▼
View filters trips by date and state
        │
        ▼
calculator.calculateExpensesByClient(
    trips: filteredTrips,
    rates: ratesStore.rates,
    receipts: receiptsStore.receipts
)
        │
        ├─► Group trips by clientOrOrg
        │
        ├─► For each client:
        │   ├─► Calculate total miles
        │   ├─► Find applicable rates
        │   ├─► Sum receipt amounts
        │   └─► Return ExpenseCalculation
        │
        └─► Return ["Client A": calc1, "Client B": calc2]
                │
                ▼
        View displays sorted by total amount
        
        Client A    $450.00
        150 miles   $0.70/mi × 150 = $105.00
        
        Client B    $210.00
        75 miles    $0.70/mi × 75 = $52.50
```

## 🧩 Component Relationships

```
┌──────────────────┐
│   Trip.swift     │  Existing model
└────────┬─────────┘
         │ references
         ▼
┌──────────────────┐      ┌──────────────────┐
│ MileageRate      │      │  TripReceipt     │
│ ├─ id            │      │  ├─ id           │
│ ├─ ratePerMile   │◄─────┤  ├─ tripId       │
│ ├─ effectiveFrom │ uses │  ├─ type         │
│ ├─ effectiveTo   │      │  ├─ amount       │
│ └─ category      │      │  └─ imageFileName│
└──────────────────┘      └──────────────────┘
         │                         │
         │    inputs to            │
         └────────┬────────────────┘
                  ▼
         ┌──────────────────┐
         │ ExpenseCalculator│
         │ ├─ calculateExpense()
         │ ├─ calculateTotal()
         │ └─ groupBy...()
         └────────┬─────────┘
                  │ produces
                  ▼
         ┌──────────────────┐
         │ExpenseCalculation│
         │ ├─ totalMiles    │
         │ ├─ mileageRate   │
         │ ├─ mileageAmount │
         │ ├─ receiptsAmount│
         │ └─ totalAmount   │
         └──────────────────┘
```

## 🎯 Integration Points

```
Your Existing App
├─ Trip Model ────────────────┐
│  └─ id, date, miles, etc    │
│                              │
├─ TripsStore ────────────┐   │
│  └─ trips: [Trip]       │   │
│                         │   │
└─ Trip Views            │   │
   ├─ Trip List          │   │
   └─ Trip Detail        │   │
                         │   │
                         ▼   ▼
            ┌────────────────────────┐
            │  Expense Integration   │
            │  ├─ MileageRatesStore  │◄─ Initialize
            │  ├─ ReceiptsStore      │◄─ Initialize
            │  └─ ExpenseCalculator  │◄─ Use in views
            └────────────────────────┘
                         │
                         ▼
            Enhanced Trip Views
            ├─ Show expense in rows
            ├─ Display calculation in detail
            └─ Link to receipt management
                         │
                         ▼
            New Expense Features
            ├─ Expense Report (tab/nav)
            ├─ Receipt Management (per trip)
            └─ Rate Configuration (settings)
```

## 📊 State Management Flow

```
User Action
    │
    ▼
┌─────────────────────┐
│   @StateObject      │
│   Store             │
│   ├─ @Published     │◄──── Auto-save
│   └─ ObservableObject│      (450ms debounce)
└─────────────────────┘
    │                          │
    │ injects into             ▼
    ▼                   ┌─────────────────┐
┌─────────────────────┐│  Persistence    │
│   View              ││  Store          │
│   @ObservedObject   ││  ├─ encode      │
│   └─ reacts to      ││  └─ write       │
│      changes        │└─────────────────┘
└─────────────────────┘         │
    │                           ▼
    │                    ┌─────────────────┐
    ▼                    │   File System   │
Calls calculator         │   .json + images│
    │                    └─────────────────┘
    ▼
┌─────────────────────┐
│  ExpenseCalculator  │
│  (stateless)        │
│  Pure functions     │
└─────────────────────┘
    │
    ▼
Returns result
    │
    ▼
View displays
```

## 🔐 Type Safety

```
Strong Typing Throughout
├─ MileageRate: Identifiable, Codable, Equatable
├─ TripReceipt: Identifiable, Codable, Equatable
├─ ExpenseCalculation: Struct (value type)
├─ ReceiptType: enum (all cases)
├─ DateRangeOption: enum (all cases)
└─ GroupingOption: enum (all cases)

Decimal for Money
├─ All currency amounts use Decimal
├─ Precise calculations
├─ No floating-point errors
└─ Safe for financial data

Optional Handling
├─ Rate may not exist → ExpenseCalculation?
├─ Receipt amount optional
├─ Image file optional
└─ Graceful degradation
```

## 🎨 View Hierarchy

```
TabView or NavigationStack
├─ ExpenseReportView
│  ├─ Date range picker
│  ├─ Total summary card
│  ├─ Grouping picker (Client/Category)
│  ├─ List of groups
│  │  └─ NavigationLink →
│  │     ClientDetailView / CategoryDetailView
│  │     ├─ ExpenseCalculationView
│  │     └─ List of trips
│  │        └─ TripExpenseRow
│  └─ Export button
│
├─ Trip Detail View (your existing)
│  ├─ Trip info
│  ├─ ExpenseCalculationView ◄── Add this
│  └─ NavigationLink →
│     TripReceiptsView ◄────────── Add this
│     ├─ Total amount
│     ├─ List of receipts
│     │  └─ ReceiptRow
│     │     ├─ Thumbnail
│     │     ├─ Type & amount
│     │     └─ Notes
│     └─ Add receipt button →
│        ReceiptEditSheet
│        ├─ Type picker
│        ├─ Amount field
│        ├─ Notes field
│        └─ PhotosPicker
│
└─ Settings View
   └─ NavigationLink →
      MileageRatesView
      ├─ Active rates section
      ├─ Inactive rates section
      └─ Add rate button →
         MileageRateEditSheet
         ├─ Name field
         ├─ Rate field
         ├─ Date pickers
         ├─ Category field
         └─ Notes field
```

## 🚀 Performance Considerations

```
Optimized for Large Data Sets

Calculator (Stateless)
├─ Instantiate once per view
├─ No state retention
└─ Fast pure functions

Store Updates (Debounced)
├─ @Published changes batched
├─ 450ms debounce
└─ Prevents excessive writes

Image Storage (Compressed)
├─ JPEG at 80% quality
├─ Reduces disk usage
└─ Fast loading

Filtering (In-Memory)
├─ Filter trips in view
├─ Dictionary grouping
└─ O(n) operations

Caching Strategies
├─ Cache calculations in @State
├─ Lazy evaluation in views
└─ Computed properties
```

## 🧪 Testing Strategy

```
Unit Tests
├─ ExpenseCalculator logic
│  ├─ Single trip calculations
│  ├─ Multiple trip aggregations
│  ├─ Rate matching
│  └─ Grouping functions
│
├─ MileageRate validation
│  ├─ Date range checks
│  └─ Active/inactive logic
│
└─ Store operations
   ├─ Filtering
   ├─ Amount calculations
   └─ CRUD operations

Integration Tests
├─ Persistence round-trips
├─ Image save/load
└─ Store auto-save

UI Tests
├─ Receipt photo flow
├─ Report filtering
└─ Navigation
```

---

**This architecture provides:**
- ✅ Clean separation of concerns
- ✅ Testable components
- ✅ SwiftUI best practices
- ✅ Type safety
- ✅ Performance optimization
- ✅ Easy to extend
