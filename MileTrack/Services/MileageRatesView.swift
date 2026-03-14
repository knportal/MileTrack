import SwiftUI

/// View for managing mileage rates
struct MileageRatesView: View {
  @ObservedObject var ratesStore: MileageRatesStore
  
  @State private var showAddRate = false
  @State private var editingRate: MileageRate?
  @State private var showResetConfirmation = false
  
  private var activeRates: [MileageRate] {
    ratesStore.activeRates(on: Date()).sorted { $0.name < $1.name }
  }
  
  private var inactiveRates: [MileageRate] {
    ratesStore.rates.filter { !$0.isActive(on: Date()) }.sorted { $0.effectiveFrom > $1.effectiveFrom }
  }
  
  var body: some View {
    List {
      Section {
        ForEach(activeRates) { rate in
          MileageRateRow(rate: rate)
            .onTapGesture {
              editingRate = rate
            }
        }
        .onDelete { indexSet in
          deleteRates(from: activeRates, at: indexSet)
        }
      } header: {
        Text("Active Rates")
      } footer: {
        Text("These rates are currently in effect and will be used for expense calculations.")
      }
      
      if !inactiveRates.isEmpty {
        Section {
          ForEach(inactiveRates) { rate in
            MileageRateRow(rate: rate)
              .onTapGesture {
                editingRate = rate
              }
          }
          .onDelete { indexSet in
            deleteRates(from: inactiveRates, at: indexSet)
          }
        } header: {
          Text("Inactive Rates")
        } footer: {
          Text("Historical rates no longer in effect.")
        }
      }
      
      Section {
        Button(role: .destructive) {
          showResetConfirmation = true
        } label: {
          Label("Reset to IRS Defaults", systemImage: "arrow.counterclockwise")
        }
      }
    }
    .navigationTitle("Mileage Rates")
    .toolbar {
      ToolbarItem(placement: .primaryAction) {
        Button {
          showAddRate = true
        } label: {
          Label("Add Rate", systemImage: "plus")
        }
      }
    }
    .sheet(isPresented: $showAddRate) {
      MileageRateEditSheet(existingRate: nil) { rate in
        ratesStore.add(rate)
      }
    }
    .sheet(item: $editingRate) { rate in
      MileageRateEditSheet(existingRate: rate) { updatedRate in
        _ = ratesStore.update(updatedRate)
      }
    }
    .confirmationDialog("Reset to Default Rates?", isPresented: $showResetConfirmation) {
      Button("Reset", role: .destructive) {
        ratesStore.resetToDefaults()
      }
      Button("Cancel", role: .cancel) { }
    } message: {
      Text("This will replace all your custom rates with the current IRS standard rates.")
    }
  }
  
  private func deleteRates(from rates: [MileageRate], at indexSet: IndexSet) {
    for index in indexSet {
      _ = ratesStore.remove(rates[index])
    }
  }
}

/// Row displaying a mileage rate
struct MileageRateRow: View {
  let rate: MileageRate
  
  private var formattedRate: String {
    let formatter = NumberFormatter()
    formatter.numberStyle = .currency
    formatter.currencyCode = "USD"
    formatter.maximumFractionDigits = 2
    return formatter.string(from: rate.ratePerMile as NSNumber) ?? "$0.00"
  }
  
  private var dateRange: String {
    let formatter = DateFormatter()
    formatter.dateStyle = .short
    
    let start = formatter.string(from: rate.effectiveFrom)
    if let end = rate.effectiveTo {
      return "\(start) – \(formatter.string(from: end))"
    } else {
      return "\(start) – Present"
    }
  }
  
  var body: some View {
    VStack(alignment: .leading, spacing: 6) {
      HStack {
        Text(rate.name)
          .font(.headline)
        
        Spacer()
        
        Text("\(formattedRate)/mi")
          .font(.headline)
          .foregroundStyle(.green)
      }
      
      HStack {
        if let category = rate.category {
          Text(category)
            .font(.caption)
            .padding(.horizontal, 8)
            .padding(.vertical, 2)
            .background {
              Capsule()
                .fill(.blue.opacity(0.2))
            }
        }
        
        Text(dateRange)
          .font(.caption)
          .foregroundStyle(.secondary)
      }
      
      if let notes = rate.notes {
        Text(notes)
          .font(.caption)
          .foregroundStyle(.secondary)
          .lineLimit(2)
      }
    }
    .padding(.vertical, 4)
  }
}

/// Sheet for adding/editing a mileage rate
struct MileageRateEditSheet: View {
  @Environment(\.dismiss) private var dismiss
  
  let existingRate: MileageRate?
  let onSave: (MileageRate) -> Void
  
  @State private var name: String
  @State private var ratePerMile: String
  @State private var effectiveFrom: Date
  @State private var hasEndDate: Bool
  @State private var effectiveTo: Date
  @State private var category: String
  @State private var notes: String
  
  @State private var showError = false
  @State private var errorMessage = ""
  
  init(existingRate: MileageRate?, onSave: @escaping (MileageRate) -> Void) {
    self.existingRate = existingRate
    self.onSave = onSave
    
    _name = State(initialValue: existingRate?.name ?? "")
    _ratePerMile = State(initialValue: existingRate != nil ? String(describing: existingRate!.ratePerMile) : "")
    _effectiveFrom = State(initialValue: existingRate?.effectiveFrom ?? Date())
    _hasEndDate = State(initialValue: existingRate?.effectiveTo != nil)
    _effectiveTo = State(initialValue: existingRate?.effectiveTo ?? Date())
    _category = State(initialValue: existingRate?.category ?? "")
    _notes = State(initialValue: existingRate?.notes ?? "")
  }
  
  private var isValid: Bool {
    !name.trimmingCharacters(in: .whitespaces).isEmpty &&
    !ratePerMile.isEmpty &&
    Decimal(string: ratePerMile) != nil
  }
  
  var body: some View {
    NavigationStack {
      Form {
        Section {
          TextField("Rate Name", text: $name)
          
          HStack {
            Text("Rate per Mile")
            Spacer()
            Text("$")
            TextField("0.00", text: $ratePerMile)
              .keyboardType(.decimalPad)
              .multilineTextAlignment(.trailing)
              .frame(maxWidth: 100)
          }
        } header: {
          Text("Basic Information")
        }
        
        Section {
          DatePicker("Start Date", selection: $effectiveFrom, displayedComponents: .date)
          
          Toggle("Has End Date", isOn: $hasEndDate)
          
          if hasEndDate {
            DatePicker("End Date", selection: $effectiveTo, displayedComponents: .date)
          }
        } header: {
          Text("Effective Period")
        } footer: {
          Text("This rate will be applied to trips within this date range.")
        }
        
        Section {
          TextField("Category (optional)", text: $category)
          
          TextField("Notes (optional)", text: $notes, axis: .vertical)
            .lineLimit(3...6)
        } header: {
          Text("Additional Details")
        } footer: {
          Text("Category helps match rates to trip categories (e.g., 'Business', 'Medical').")
        }
      }
      .navigationTitle(existingRate == nil ? "Add Rate" : "Edit Rate")
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .cancellationAction) {
          Button("Cancel") {
            dismiss()
          }
        }
        
        ToolbarItem(placement: .confirmationAction) {
          Button("Save") {
            saveRate()
          }
          .disabled(!isValid)
        }
      }
      .alert("Error", isPresented: $showError) {
        Button("OK") { }
      } message: {
        Text(errorMessage)
      }
    }
  }
  
  private func saveRate() {
    guard let decimalRate = Decimal(string: ratePerMile) else {
      errorMessage = "Please enter a valid rate"
      showError = true
      return
    }
    
    let trimmedName = name.trimmingCharacters(in: .whitespaces)
    let trimmedCategory = category.trimmingCharacters(in: .whitespaces)
    let trimmedNotes = notes.trimmingCharacters(in: .whitespaces)
    
    let rate = MileageRate(
      id: existingRate?.id ?? UUID(),
      name: trimmedName,
      ratePerMile: decimalRate,
      effectiveFrom: effectiveFrom,
      effectiveTo: hasEndDate ? effectiveTo : nil,
      category: trimmedCategory.isEmpty ? nil : trimmedCategory,
      notes: trimmedNotes.isEmpty ? nil : trimmedNotes
    )
    
    onSave(rate)
    dismiss()
  }
}

#Preview("Mileage Rates View") {
  NavigationStack {
    MileageRatesView(ratesStore: MileageRatesStore(rates: MileageRate.defaultRates))
  }
}

#Preview("Add Rate Sheet") {
  MileageRateEditSheet(existingRate: nil) { _ in }
}
