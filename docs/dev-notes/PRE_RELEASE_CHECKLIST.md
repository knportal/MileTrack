# ✅ Pre-Release Checklist

Use this checklist before releasing the expense features.

## 📋 Setup & Build

- [ ] **Add Photo Library Permission to Info.plist**
  ```xml
  <key>NSPhotoLibraryUsageDescription</key>
  <string>MileTrack uses your photos to attach receipt images to trips for expense tracking</string>
  ```

- [ ] **Add all new Swift files to your Xcode target**
  - Select each file in Project Navigator
  - Check File Inspector → Target Membership
  - Ensure your app target is checked

- [ ] **Clean build folder** (⇧⌘K)

- [ ] **Build successfully** (⌘B) with zero errors

- [ ] **Build for Release** configuration
  - Product → Scheme → Edit Scheme
  - Set Run → Build Configuration → Release
  - Build again

## 🧪 Functional Testing

### Expenses Tab
- [ ] Tap Expenses tab → Opens without crash
- [ ] Shows default state correctly (empty or with trips)
- [ ] Date range picker works (This Month, This Year, etc.)
- [ ] Group by Client toggle works
- [ ] Group by Category toggle works
- [ ] Tapping client/category drills down
- [ ] Back navigation works
- [ ] Numbers look correct

### Settings → Expenses
- [ ] Settings tab → Expenses section visible
- [ ] "Mileage Rates" opens rate configuration
- [ ] "Expense Report" opens same as Expenses tab
- [ ] Default IRS rates visible:
  - [ ] Business: $0.70/mi
  - [ ] Medical: $0.21/mi
  - [ ] Charitable: $0.14/mi
- [ ] Add custom rate works
- [ ] Edit rate works
- [ ] Delete rate works (swipe)
- [ ] Reset to defaults works

### Trip Editing
- [ ] Edit any confirmed trip
- [ ] "Expense Estimate" card shows
- [ ] Calculation displays correctly
- [ ] Formula shows (e.g., "$0.70/mi × 50.0 mi = $35.00")
- [ ] "Receipts" card shows
- [ ] Receipt count badge shows if receipts exist
- [ ] "Manage Receipts" button navigates

### Receipt Management
- [ ] Tap "Manage Receipts" from trip edit
- [ ] Empty state shows correctly
- [ ] Tap "+" to add receipt
- [ ] Receipt type picker works
- [ ] Amount field accepts numbers
- [ ] Photo picker opens
- [ ] Select photo from library works
- [ ] Take new photo works (on device)
- [ ] Save receipt works
- [ ] Receipt appears in list
- [ ] Thumbnail shows correctly
- [ ] Tap receipt to edit
- [ ] Update amount works
- [ ] Change photo works
- [ ] Delete receipt works (swipe)
- [ ] Total amount updates in trip edit

## 🎨 Visual Testing

### Light Mode
- [ ] All new views look good
- [ ] Text is readable
- [ ] Colors are appropriate
- [ ] Icons are visible
- [ ] Cards have proper spacing

### Dark Mode
- [ ] Switch to dark mode (Settings → Display → Dark)
- [ ] All views still look good
- [ ] No white boxes or dark text on dark background
- [ ] Green amounts still visible
- [ ] Receipt photos display correctly

### iPad
- [ ] Run on iPad simulator
- [ ] Layouts adapt to larger screen
- [ ] No stretched or cramped UI
- [ ] Navigation works smoothly

### Landscape
- [ ] Rotate device/simulator to landscape
- [ ] All views still usable
- [ ] No cut-off content
- [ ] Back to portrait works

## 📱 Device Testing

### On Simulator
- [ ] iPhone 15 Pro (or latest)
- [ ] iPhone SE (smaller screen)
- [ ] iPad Pro (tablet size)

### On Physical Device
- [ ] Install via TestFlight or direct install
- [ ] Camera permission works for receipts
- [ ] Photo library permission works
- [ ] Touch interactions smooth
- [ ] No performance issues

## 🔐 Data & Privacy

### Permissions
- [ ] Photo library permission requested when needed
- [ ] Permission request text is clear
- [ ] App works if permission denied (graceful degradation)

### Data Persistence
- [ ] Add some trips and receipts
- [ ] Force quit app (swipe up from app switcher)
- [ ] Reopen app
- [ ] All data still there
- [ ] Receipt images still load

### Data Storage
- [ ] Check Application Support directory exists
- [ ] `mileage_rates.json` present
- [ ] `receipts.json` present
- [ ] `Receipts/` folder present
- [ ] Image files present and valid

## ⚡ Performance

### Speed
- [ ] Expense tab loads quickly (< 1 second)
- [ ] Calculations are instant
- [ ] Scrolling is smooth
- [ ] No lag when switching filters
- [ ] Photo thumbnails load quickly

### Memory
- [ ] Open Instruments → Allocations
- [ ] Use app normally for 5 minutes
- [ ] Memory usage is reasonable
- [ ] No obvious leaks

### Battery
- [ ] Use app for 10 minutes
- [ ] Battery drain is normal
- [ ] No excessive CPU usage

## 🧩 Integration

### With Existing Features
- [ ] Creating trips still works
- [ ] Editing trips still works
- [ ] Deleting trips still works
- [ ] Reports tab unchanged
- [ ] Categories work with expenses
- [ ] Clients work with expense grouping
- [ ] No regressions in existing features

### Auto-Save
- [ ] Modify a rate
- [ ] Add a receipt
- [ ] Background app (home button)
- [ ] Reopen app
- [ ] Changes persisted

## 📊 Data Accuracy

### Calculations
- [ ] Create trip: 50 miles, Business category
- [ ] Should show: $0.70 × 50 = $35.00
- [ ] Add parking receipt: $10.00
- [ ] Should show total: $45.00
- [ ] Verify in expense report matches

### Rate Matching
- [ ] Create Business trip → Uses Business rate ($0.70)
- [ ] Create Medical trip → Uses Medical rate ($0.21)
- [ ] Create trip without category → Uses any available rate
- [ ] Create trip with past date → Uses rate active on that date

### Grouping
- [ ] Create 3 trips for "Client A"
- [ ] Create 2 trips for "Client B"
- [ ] Group by Client in expense report
- [ ] Verify Client A shows 3 trips
- [ ] Verify Client B shows 2 trips
- [ ] Verify totals are correct

## 🌐 Edge Cases

### Empty States
- [ ] New user with no trips → Friendly empty state
- [ ] No receipts for trip → Shows empty state
- [ ] No rates defined → Handle gracefully
- [ ] No trips in date range → Show message

### Unusual Data
- [ ] Trip with 0 miles → Handles correctly
- [ ] Trip with 999 miles → Displays correctly
- [ ] Receipt with $0.01 → Works fine
- [ ] Receipt with $9999.99 → Displays properly
- [ ] Very long client name → Doesn't overflow
- [ ] Special characters in notes → Saved correctly

### User Errors
- [ ] Try to add receipt without amount → Validation works
- [ ] Try to add rate without name → Validation works
- [ ] Delete all rates → App doesn't crash
- [ ] Add overlapping rate dates → Works fine

## ♿ Accessibility

### VoiceOver
- [ ] Enable VoiceOver (Settings → Accessibility)
- [ ] Navigate Expenses tab
- [ ] All buttons are labeled
- [ ] All amounts are readable
- [ ] Form fields are accessible
- [ ] Navigation is logical

### Dynamic Type
- [ ] Settings → Display → Text Size → Largest
- [ ] All text scales appropriately
- [ ] No truncation of important info
- [ ] Layout adapts
- [ ] Still usable at largest size

### High Contrast
- [ ] Settings → Accessibility → Increase Contrast
- [ ] All UI elements visible
- [ ] Text is readable

## 📝 Documentation

### In-App
- [ ] Settings links work
- [ ] Help text is clear
- [ ] Error messages are helpful

### External
- [ ] Update App Store description (mention expenses)
- [ ] Update screenshots if needed
- [ ] Update What's New notes
- [ ] Update privacy policy if needed

## 🚀 Pre-Release

### Code Quality
- [ ] No force unwraps in production code
- [ ] No `print()` statements left in
- [ ] No TODO/FIXME in critical paths
- [ ] Error handling in place
- [ ] Consistent code style

### App Store
- [ ] Version number incremented
- [ ] Build number incremented
- [ ] App Store Connect info updated
- [ ] Screenshots include new features
- [ ] Release notes mention expenses

### Testing
- [ ] Beta testers invited (if using TestFlight)
- [ ] Feedback collected
- [ ] Critical bugs fixed
- [ ] Minor bugs documented

## ✅ Final Checks

- [ ] All items above checked
- [ ] Team has approved
- [ ] Ready to submit/release
- [ ] Celebration planned! 🎉

## 🎊 Ready to Ship!

When all boxes are checked, you're ready to release the expense features to your users!

**Estimated time to complete checklist: 2-3 hours**

---

## 📞 Quick Reference

**Files Modified:**
- ContentView.swift
- SettingsView.swift  
- MainTabView.swift
- EditTripSheet.swift

**Files Added:** 
- 10 implementation files
- 5 documentation files

**Key Features:**
- Mileage rate calculator
- Receipt photo attachments  
- Expense reports by client/category

**Support Docs:**
- QUICK_START.md
- INTEGRATION_COMPLETE.md
- EXPENSE_INTEGRATION_GUIDE.md
- EXPENSE_QUICK_REFERENCE.md
