# Expense Integration Implementation Guide

## Overview

This implementation adds comprehensive expense tracking and calculation features to MileTrack, including:

1. **Mileage Rate Calculator** - Real-time IRS/custom rate calculations
2. **Receipt Attachments** - Photo attachments for parking, tolls, and other expenses
3. **Expense Totals by Client** - Detailed breakdowns and reporting

## Files Created

### Core Models
- `MileageRate.swift` - Represents mileage reimbursement rates with date ranges
- `TripReceipt.swift` - Receipt model with photo attachment support
- `ExpenseCalculator.swift` - Service for calculating trip expenses and aggregations

### Persistence Layer
- `MileageRatesPersistenceStore.swift` - Stores mileage rates to disk
- `ReceiptsPersistenceStore.swift` - Stores receipt metadata and images
- `MileageRatesStore.swift` - Observable store for mileage rates
- `ReceiptsStore.swift` - Observable store for receipts with image management

### UI Components
- `ExpenseCalculationView.swift` - Displays expense calculations with breakdowns
- `TripReceiptsView.swift` - Manage receipts for individual trips
- `MileageRatesView.swift` - Configure custom mileage rates
- `ExpenseReportView.swift` - Comprehensive expense reports with grouping

## Integration Steps

### 1. Add Store Initialization

In your main app file or root view, initialize the new stores:

```swift
@StateObject private var mileageRatesStore = MileageRatesStore()
@StateObject private var receiptsStore = ReceiptsStore()
```

Then pass these through your view hierarchy using `.environmentObject()` or explicit parameters.

### 2. Update Trip Detail Views

Add expense display to your trip detail views:

```swift
// In your trip detail view
Section {
    if let calculation = ExpenseCalculator().calculateExpense(
        for: trip,
        rates: ratesStore.rates,
        receipts: receiptsStore.receipts
    ) {
        ExpenseCalculationView(calculation: calculation)
    }
}

Section {
    NavigationLink("Receipts (\(receiptsStore.receipts(for: trip).count))") {
        TripReceiptsView(trip: trip, receiptsStore: receiptsStore)
    }
}
```

### 3. Add Inline Expense Display

Show quick expense previews in trip lists:

```swift
// In your trip row view
VStack(alignment: .leading) {
    Text(tripDescription)
    
    HStack {
        TripExpenseInlineView(
            trip: trip,
            calculation: ExpenseCalculator().calculateExpense(
                for: trip,
                rates: ratesStore.rates,
                receipts: receiptsStore.receipts
            )
        )
    }
}
```

### 4. Add Settings/Configuration

Add navigation links in your settings view:

```swift
Section("Expenses") {
    NavigationLink("Mileage Rates") {
        MileageRatesView(ratesStore: ratesStore)
    }
    
    NavigationLink("Expense Report") {
        ExpenseReportView(
            trips: allTrips,
            ratesStore: ratesStore,
            receiptsStore: receiptsStore
        )
    }
}
```

### 5. Add Tab or Navigation Entry Point

Consider adding a dedicated "Expenses" tab:

```swift
TabView {
    // ... existing tabs
    
    NavigationStack {
        ExpenseReportView(
            trips: tripsStore.trips,
            ratesStore: ratesStore,
            receiptsStore: receiptsStore
        )
    }
    .tabItem {
        Label("Expenses", systemImage: "dollarsign.circle")
    }
}
```

## Features

### Mileage Rate Calculator

**Default Rates Included:**
- IRS 2026 Business: $0.70/mile
- IRS 2026 Medical: $0.21/mile  
- IRS 2026 Charitable: $0.14/mile

**Features:**
- Automatic rate matching by category and date
- Historical rate support with effective date ranges
- Custom rate creation
- Per-category rate configuration

**Display Format:**
```
$0.67/mi × 50.0 mi = $33.50
```

### Receipt Attachments

**Receipt Types:**
- Parking
- Tolls
- Fuel
- Maintenance
- Other

**Features:**
- Photo attachment via Photos picker
- Amount tracking with currency support
- Date and notes
- Automatic image storage and management
- Swipe to delete

### Expense Reports

**Grouping Options:**
- By Client/Organization
- By Category

**Date Range Filters:**
- This Week
- This Month
- Last Month
- This Year
- Last Year
- All Time

**Report Shows:**
- Total mileage deduction
- Receipt expenses
- Combined total
- Trip count and mile totals
- Drill-down to individual trips
- Export capability (placeholder)

## Best Practices

### Performance

The `ExpenseCalculator` is designed to be lightweight and can be instantiated as needed. For large trip lists, consider:

1. Caching calculations for visible rows
2. Using `@State` or `@StateObject` to hold calculator instances
3. Debouncing recalculations when filters change

Example:
```swift
@State private var calculator = ExpenseCalculator()
```

### Data Persistence

Both stores automatically save changes with a 450ms debounce. For critical operations (like app backgrounding), call:

```swift
ratesStore.saveNow()
receiptsStore.saveNow()
```

### Image Storage

Receipt images are stored in the app's Application Support directory under `Receipts/`. Images are:
- Compressed as JPEG at 80% quality
- Named by receipt UUID
- Automatically cleaned up when receipts are deleted

### Rate Matching Logic

The expense calculator uses this priority for matching rates to trips:

1. **Category + Date Match** - Rate with matching category that's active on trip date
2. **Date Match** - Any rate active on trip date
3. **Fallback** - Most recent rate by effective date

## Customization Options

### Currency Support

To add support for other currencies, update:

1. `TripReceipt.currency` default value
2. Number formatter currency codes in views
3. Add currency picker to receipt edit sheet

### Export Formats

The export button in `ExpenseReportView` is a placeholder. Implement by:

1. Generating CSV/PDF using trip data
2. Using `ShareLink` or `UIActivityViewController`
3. Creating formatted reports with expense breakdowns

Example CSV export:
```swift
private func exportToCSV() -> String {
    var csv = "Date,Client,Category,Miles,Rate,Mileage Amount,Receipts,Total\n"
    
    for trip in filteredTrips {
        if let calc = calculator.calculateExpense(for: trip, rates: ratesStore.rates, receipts: receiptsStore.receipts) {
            csv += "\(trip.date),\(trip.clientOrOrg ?? ""),\(trip.category ?? ""),\(trip.distanceMiles),\(calc.mileageRate),\(calc.mileageAmount),\(calc.receiptsAmount),\(calc.totalAmount)\n"
        }
    }
    
    return csv
}
```

### Additional Receipt Fields

To add more receipt fields (vendor, receipt number, etc.):

1. Update `TripReceipt` model
2. Add form fields to `ReceiptEditSheet`
3. Display in `ReceiptRow`

## Testing Considerations

### Unit Tests

Key areas to test:
- Rate matching logic in `ExpenseCalculator`
- Date range calculations
- Decimal arithmetic precision
- Persistence layer encoding/decoding

### UI Tests

Consider testing:
- Receipt photo attachment flow
- Expense calculation display accuracy
- Date range filtering
- Client/category grouping

### Edge Cases

Handle these scenarios:
- No rates defined
- Rate gaps (no rate for trip date)
- Multiple overlapping rates
- Very large expense amounts
- Missing trip data (nil category, client)

## Future Enhancements

Potential additions:
- Export to PDF with formatted reports
- Recurring rate updates (annual IRS rate imports)
- Receipt OCR for automatic amount extraction
- Expense approval workflow
- Multi-currency support
- Mileage vs actual expense comparison
- Tax year summaries
- Integration with accounting software

## Requirements

- iOS 17.0+ (for PhotosPicker)
- Swift 5.9+
- Foundation, SwiftUI, PhotosUI frameworks

## Migration Notes

When adding to existing app:
- No migration needed for existing trip data
- Default IRS rates automatically populated on first launch
- Receipt storage directory created automatically
- All expense features are additive and don't affect existing functionality
