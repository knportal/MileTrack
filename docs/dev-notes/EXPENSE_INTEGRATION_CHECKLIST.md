# Expense Integration Checklist

Use this checklist to integrate expense features into your MileTrack app step by step.

## ✅ Phase 1: Core Setup (15 minutes)

### Add Files to Project
- [ ] Add all 14 new Swift files to your Xcode project
- [ ] Ensure files are added to correct target
- [ ] Build project to check for compilation errors
- [ ] Fix any import or naming conflicts

### Initialize Stores
- [ ] Open your main app file or root view
- [ ] Add `@StateObject` properties:
  ```swift
  @StateObject private var mileageRatesStore = MileageRatesStore()
  @StateObject private var receiptsStore = ReceiptsStore()
  ```
- [ ] Pass stores through environment or as parameters
- [ ] Test that stores initialize with default rates

### Verify Persistence
- [ ] Run app once
- [ ] Check Application Support directory for:
  - [ ] `mileage_rates.json` (should contain IRS defaults)
  - [ ] `receipts.json` (should be empty array)
  - [ ] `Receipts/` folder (should exist)

**✓ Checkpoint:** Stores initialized, files created, no crashes

---

## ✅ Phase 2: Basic Display (30 minutes)

### Add Expense to Trip Detail
- [ ] Find your existing trip detail view
- [ ] Import expense components at top
- [ ] Add expense calculation section:
  ```swift
  Section("Expense") {
      if let calculation = ExpenseCalculator().calculateExpense(
          for: trip,
          rates: ratesStore.rates,
          receipts: receiptsStore.receipts
      ) {
          ExpenseCalculationView(calculation: calculation)
      }
  }
  ```
- [ ] Test with a sample trip
- [ ] Verify calculation displays correctly

### Add Inline Expense Badges
- [ ] Find your trip list/row view
- [ ] Add inline expense display:
  ```swift
  TripExpenseInlineView(trip: trip, calculation: calculation)
  ```
- [ ] Test that badges appear in list
- [ ] Verify amounts are correct

**✓ Checkpoint:** Expense shown in trip detail and list rows

---

## ✅ Phase 3: Receipt Management (45 minutes)

### Add Receipt Link to Trip Detail
- [ ] In trip detail view, add navigation link:
  ```swift
  NavigationLink("Receipts") {
      TripReceiptsView(trip: trip, receiptsStore: receiptsStore)
  }
  ```
- [ ] Test navigation to receipt view
- [ ] Verify empty state shows correctly

### Test Receipt Creation
- [ ] Tap "Add Receipt" button
- [ ] Select a receipt type
- [ ] Enter an amount (e.g., 10.00)
- [ ] Add a photo using PhotosPicker
- [ ] Save receipt
- [ ] Verify receipt appears in list
- [ ] Check thumbnail displays correctly
- [ ] Verify expense calculation updated

### Test Receipt Management
- [ ] Edit an existing receipt
- [ ] Update photo
- [ ] Change amount
- [ ] Save changes
- [ ] Delete a receipt (swipe to delete)
- [ ] Verify image file deleted from disk
- [ ] Verify expense calculation updated

**✓ Checkpoint:** Receipts can be added, viewed, edited, deleted

---

## ✅ Phase 4: Rate Configuration (30 minutes)

### Add Settings Entry
- [ ] Find your settings/preferences view
- [ ] Add navigation link:
  ```swift
  NavigationLink("Mileage Rates") {
      MileageRatesView(ratesStore: ratesStore)
  }
  ```
- [ ] Test navigation

### Verify Default Rates
- [ ] Open Mileage Rates view
- [ ] Confirm 3 IRS rates visible:
  - [ ] Business: $0.70/mi
  - [ ] Medical: $0.21/mi
  - [ ] Charitable: $0.14/mi
- [ ] Check they're in "Active Rates" section

### Test Custom Rate
- [ ] Tap "Add Rate" button
- [ ] Enter custom rate:
  - Name: "Company Rate"
  - Rate: $0.65/mi
  - Category: "Business"
  - Start date: Today
- [ ] Save rate
- [ ] Verify it appears in list
- [ ] Go back to a trip detail
- [ ] Verify calculation uses new rate (if matching)

### Test Rate Editing
- [ ] Edit an existing rate
- [ ] Change rate amount
- [ ] Save changes
- [ ] Verify trips update with new calculation

**✓ Checkpoint:** Custom rates work, calculations update

---

## ✅ Phase 5: Expense Reports (45 minutes)

### Add Report Navigation
- [ ] Choose where to add report (tab, settings, or main nav)
- [ ] Add navigation entry:
  ```swift
  NavigationStack {
      ExpenseReportView(
          trips: tripsStore.trips,
          ratesStore: ratesStore,
          receiptsStore: receiptsStore
      )
  }
  ```
- [ ] Test navigation

### Test Date Filtering
- [ ] Open expense report
- [ ] Change date range to "This Month"
- [ ] Verify trips filtered correctly
- [ ] Try "Last Month" - should show different trips
- [ ] Try "All Time" - should show all confirmed trips

### Test Client Grouping
- [ ] Ensure some trips have client names
- [ ] Select "Group By: Client"
- [ ] Verify trips grouped by client
- [ ] Check amounts calculated correctly
- [ ] Tap into a client detail
- [ ] Verify individual trips listed

### Test Category Grouping
- [ ] Select "Group By: Category"
- [ ] Verify trips grouped by category
- [ ] Check Business trips use $0.70/mi rate
- [ ] Check Medical trips use $0.21/mi rate
- [ ] Tap into a category detail
- [ ] Verify individual trips listed

### Test Sorting
- [ ] Verify clients/categories sorted by total amount
- [ ] Highest amounts should appear first

**✓ Checkpoint:** Reports work, filtering correct, grouping accurate

---

## ✅ Phase 6: Polish & Edge Cases (30 minutes)

### Test Edge Cases

#### No Rates
- [ ] Delete all rates temporarily
- [ ] Check trip detail shows graceful fallback
- [ ] Restore rates

#### No Receipts
- [ ] View trip with no receipts
- [ ] Verify expense shows only mileage
- [ ] Check empty state in receipts view

#### Missing Trip Data
- [ ] Test trip without category
- [ ] Test trip without client
- [ ] Verify grouping handles "Uncategorized"/"Unassigned"

#### Large Numbers
- [ ] Create trip with 500 miles
- [ ] Verify calculation displays correctly
- [ ] Check formatting (commas, etc.)

#### Multiple Receipts
- [ ] Add 5+ receipts to one trip
- [ ] Verify total calculated correctly
- [ ] Check all images load properly

### UI/UX Checks
- [ ] Dark mode: Check all views
- [ ] Accessibility: Test with VoiceOver
- [ ] iPad: Verify layouts adapt
- [ ] Landscape: Check all views rotate correctly
- [ ] Long text: Enter very long notes/names
- [ ] Special characters: Test in text fields

**✓ Checkpoint:** Edge cases handled, UI polished

---

## ✅ Phase 7: Performance & Optimization (20 minutes)

### Performance Tests
- [ ] Create 100+ trips
- [ ] Open expense report
- [ ] Change filters - should be instant
- [ ] Scroll trip list with inline expenses - should be smooth
- [ ] Check memory usage in Instruments

### Persistence Tests
- [ ] Make changes to rates and receipts
- [ ] Force quit app (don't just background)
- [ ] Relaunch app
- [ ] Verify all changes persisted

### Background Save
- [ ] Add scene phase observer if not present:
  ```swift
  .onChange(of: scenePhase) { oldPhase, newPhase in
      if newPhase == .background {
          ratesStore.saveNow()
          receiptsStore.saveNow()
      }
  }
  ```
- [ ] Test backgrounding saves data

**✓ Checkpoint:** App is performant, data persists reliably

---

## ✅ Phase 8: Testing (30 minutes)

### Run Unit Tests
- [ ] Open Test Navigator (⌘6)
- [ ] Run `ExpenseTests.swift` (⌘U)
- [ ] Verify all tests pass
- [ ] Fix any failing tests

### Manual Testing Scenarios

#### Scenario 1: Business Trip with Receipt
- [ ] Create manual trip: Home → Client Office, 25 mi, Business
- [ ] Add parking receipt: $10
- [ ] Verify shows: $0.70/mi × 25 mi = $17.50
- [ ] Verify total: $27.50 (mileage + parking)

#### Scenario 2: Medical Trip
- [ ] Create trip: 15 mi, Medical category
- [ ] Verify uses $0.21/mi rate
- [ ] Check calculation: $3.15

#### Scenario 3: Monthly Report
- [ ] Create 5 trips for different clients this month
- [ ] Add receipts to some trips
- [ ] Open expense report
- [ ] Select "This Month"
- [ ] Group by Client
- [ ] Verify totals match individual calculations

### Regression Testing
- [ ] Verify existing features still work:
  - [ ] Creating trips
  - [ ] Editing trips
  - [ ] Deleting trips
  - [ ] Auto tracking (if implemented)
- [ ] No new crashes introduced
- [ ] No memory leaks

**✓ Checkpoint:** All tests pass, no regressions

---

## ✅ Phase 9: Documentation (15 minutes)

### Code Documentation
- [ ] Add comments to your integration points
- [ ] Document any custom modifications
- [ ] Note any configuration decisions

### User Documentation
- [ ] Create help text or tutorial for:
  - [ ] Adding receipts
  - [ ] Configuring rates
  - [ ] Understanding reports
- [ ] Add to in-app help or onboarding

### Team Handoff
- [ ] Share implementation with team
- [ ] Document known limitations
- [ ] Note future enhancement ideas

**✓ Checkpoint:** Code documented, team informed

---

## ✅ Phase 10: Final Checks (15 minutes)

### Pre-Release Checklist
- [ ] All compilation warnings resolved
- [ ] No force unwraps in production code
- [ ] Error handling in place
- [ ] No hardcoded test data
- [ ] Default rates up to date (IRS 2026)
- [ ] Image compression appropriate
- [ ] File permissions correct

### Privacy & Security
- [ ] Photo library permission in Info.plist:
  ```xml
  <key>NSPhotoLibraryUsageDescription</key>
  <string>To attach receipt photos to trips</string>
  ```
- [ ] Data stored securely (Application Support)
- [ ] No sensitive data logged

### Build & Archive
- [ ] Clean build folder (⇧⌘K)
- [ ] Build for release
- [ ] Run on physical device
- [ ] Test on oldest supported iOS version
- [ ] Archive for submission (if ready)

**✓ Checkpoint:** Ready for release!

---

## 📋 Quick Reference

### Critical Files to Integrate
```
Your App
├─ Add stores to main app/root view
├─ Update trip detail view
├─ Update trip row view
└─ Add settings entries

Expense Files (all 14)
├─ Models (3)
├─ Persistence (4)
├─ Views (4)
└─ Docs (3)
```

### Minimum Integration
If you're short on time, do these first:
1. ✅ Initialize stores
2. ✅ Add `ExpenseCalculationView` to trip detail
3. ✅ Add `TripReceiptsView` link
4. ✅ Add `MileageRatesView` to settings

Everything else is polish and enhancements.

---

## 🎯 Completion Criteria

You're done when:
- [x] All 10 phases checked off
- [x] App compiles without errors
- [x] All tests pass
- [x] Manual testing complete
- [x] No crashes in production scenarios
- [x] Expense calculations accurate
- [x] Data persists across launches
- [x] UI looks good in light/dark mode
- [x] Team/documentation updated

---

## 🆘 Troubleshooting

### Issue: Rates not showing
- Check `MileageRatesStore` initialized
- Verify default rates loaded
- Check file permissions

### Issue: Receipts not saving
- Verify `ReceiptsStore` initialized
- Check Application Support directory exists
- Verify PhotosPicker permission granted

### Issue: Calculations wrong
- Verify rate matching logic
- Check trip dates vs rate effective dates
- Ensure using Decimal not Double for money

### Issue: Images not loading
- Check Receipts folder exists
- Verify file names match
- Check JPEG compression success

### Issue: Performance slow
- Cache calculator instance
- Use @State for calculations in lists
- Check for retain cycles

---

## 📞 Support

If you get stuck:
1. Check `EXPENSE_INTEGRATION_GUIDE.md`
2. Review `ExpenseIntegrationExamples.swift`
3. Consult `EXPENSE_QUICK_REFERENCE.md`
4. Look at `EXPENSE_ARCHITECTURE.md`
5. Review test cases in `ExpenseTests.swift`

---

**Estimated Total Time: 4-5 hours**

Good luck! 🚀
