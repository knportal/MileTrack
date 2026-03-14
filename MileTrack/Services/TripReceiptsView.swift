import SwiftUI
import PhotosUI

/// Sheet for adding/editing a receipt for a trip
struct ReceiptEditSheet: View {
  @Environment(\.dismiss) private var dismiss
  
  let trip: Trip
  let existingReceipt: TripReceipt?
  let onSave: (TripReceipt, UIImage?) -> Void
  
  @State private var receiptType: ReceiptType
  @State private var amount: String
  @State private var notes: String
  @State private var selectedImage: PhotosPickerItem?
  @State private var receiptImage: UIImage?
  @State private var showError = false
  @State private var errorMessage = ""
  
  init(trip: Trip, existingReceipt: TripReceipt? = nil, onSave: @escaping (TripReceipt, UIImage?) -> Void) {
    self.trip = trip
    self.existingReceipt = existingReceipt
    self.onSave = onSave
    
    _receiptType = State(initialValue: existingReceipt?.type ?? .parking)
    
    if let existingAmount = existingReceipt?.amount {
      _amount = State(initialValue: String(describing: existingAmount))
    } else {
      _amount = State(initialValue: "")
    }
    
    _notes = State(initialValue: existingReceipt?.notes ?? "")
  }
  
  private var isValid: Bool {
    !amount.isEmpty && Decimal(string: amount) != nil
  }
  
  var body: some View {
    NavigationStack {
      Form {
        Section {
          Picker("Type", selection: $receiptType) {
            ForEach(ReceiptType.allCases, id: \.self) { type in
              Label(type.displayName, systemImage: type.systemImage)
                .tag(type)
            }
          }
          
          HStack {
            Text("Amount")
            Spacer()
            TextField("0.00", text: $amount)
              .keyboardType(.decimalPad)
              .multilineTextAlignment(.trailing)
          }
          
          TextField("Notes (optional)", text: $notes, axis: .vertical)
            .lineLimit(3...6)
        } header: {
          Text("Receipt Details")
        }
        
        Section {
          PhotosPicker(selection: $selectedImage, matching: .images) {
            if let receiptImage {
              VStack {
                Image(uiImage: receiptImage)
                  .resizable()
                  .scaledToFit()
                  .frame(maxHeight: 200)
                  .clipShape(RoundedRectangle(cornerRadius: 8))
                
                Label("Change Photo", systemImage: "photo")
                  .font(.caption)
              }
            } else {
              Label("Add Photo", systemImage: "camera")
            }
          }
        } header: {
          Text("Receipt Image")
        } footer: {
          Text("Optional: Attach a photo of your receipt")
        }
        
        Section {
          LabeledContent("Trip") {
            VStack(alignment: .trailing) {
              if let start = trip.startLabel {
                Text(start)
                  .font(.caption)
              }
              if let end = trip.endLabel {
                Text("→ \(end)")
                  .font(.caption)
              }
              Text(trip.date, style: .date)
                .font(.caption2)
                .foregroundStyle(.secondary)
            }
          }
        }
      }
      .navigationTitle(existingReceipt == nil ? "Add Receipt" : "Edit Receipt")
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .cancellationAction) {
          Button("Cancel") {
            dismiss()
          }
        }
        
        ToolbarItem(placement: .confirmationAction) {
          Button("Save") {
            saveReceipt()
          }
          .disabled(!isValid)
        }
      }
      .alert("Error", isPresented: $showError) {
        Button("OK") { }
      } message: {
        Text(errorMessage)
      }
      .onChange(of: selectedImage) { oldValue, newValue in
        Task {
          if let data = try? await newValue?.loadTransferable(type: Data.self),
             let image = UIImage(data: data) {
            receiptImage = image
          }
        }
      }
    }
  }
  
  private func saveReceipt() {
    guard let decimalAmount = Decimal(string: amount) else {
      errorMessage = "Please enter a valid amount"
      showError = true
      return
    }
    
    let receipt = TripReceipt(
      id: existingReceipt?.id ?? UUID(),
      tripId: trip.id,
      type: receiptType,
      amount: decimalAmount,
      currency: "USD",
      date: trip.date,
      notes: notes.isEmpty ? nil : notes,
      imageFileName: existingReceipt?.imageFileName
    )
    
    onSave(receipt, receiptImage)
    dismiss()
  }
}

/// Displays receipts for a trip
struct TripReceiptsView: View {
  let trip: Trip
  @ObservedObject var receiptsStore: ReceiptsStore
  
  @State private var showAddReceipt = false
  @State private var editingReceipt: TripReceipt?
  
  private var tripReceipts: [TripReceipt] {
    receiptsStore.receipts(for: trip)
  }
  
  private var totalAmount: Decimal {
    receiptsStore.totalAmount(for: trip)
  }
  
  var body: some View {
    List {
      if !tripReceipts.isEmpty {
        Section {
          HStack {
            Text("Total")
              .font(.headline)
            Spacer()
            let formatter = NumberFormatter()
            let _ = { formatter.numberStyle = .currency; formatter.currencyCode = "USD" }()
            Text(formatter.string(from: totalAmount as NSNumber) ?? "$0.00")
              .font(.headline)
              .foregroundStyle(.green)
          }
        }
      }
      
      Section {
        ForEach(tripReceipts) { receipt in
          ReceiptRow(receipt: receipt, receiptsStore: receiptsStore)
            .onTapGesture {
              editingReceipt = receipt
            }
        }
        .onDelete { indexSet in
          deleteReceipts(at: indexSet)
        }
      } header: {
        Text("Receipts")
      }
      
      if tripReceipts.isEmpty {
        Section {
          ContentUnavailableView {
            Label("No Receipts", systemImage: "doc.text")
          } description: {
            Text("Add parking, tolls, and other expenses")
          } actions: {
            Button("Add Receipt") {
              showAddReceipt = true
            }
          }
        }
      }
    }
    .navigationTitle("Trip Receipts")
    .navigationBarTitleDisplayMode(.inline)
    .toolbar {
      ToolbarItem(placement: .primaryAction) {
        Button {
          showAddReceipt = true
        } label: {
          Label("Add Receipt", systemImage: "plus")
        }
      }
    }
    .sheet(isPresented: $showAddReceipt) {
      ReceiptEditSheet(trip: trip) { receipt, image in
        do {
          if let image {
            try receiptsStore.add(receipt, image: image)
          } else {
            receiptsStore.add(receipt)
          }
        } catch {
          print("Error adding receipt: \(error)")
        }
      }
    }
    .sheet(item: $editingReceipt) { receipt in
      ReceiptEditSheet(trip: trip, existingReceipt: receipt) { updatedReceipt, image in
        do {
          _ = try receiptsStore.update(updatedReceipt, image: image)
        } catch {
          print("Error updating receipt: \(error)")
        }
      }
    }
  }
  
  private func deleteReceipts(at indexSet: IndexSet) {
    for index in indexSet {
      let receipt = tripReceipts[index]
      try? receiptsStore.remove(receipt)
    }
  }
}

/// Row view for a single receipt
struct ReceiptRow: View {
  let receipt: TripReceipt
  let receiptsStore: ReceiptsStore
  
  private var formattedAmount: String {
    let formatter = NumberFormatter()
    formatter.numberStyle = .currency
    formatter.currencyCode = receipt.currency
    return formatter.string(from: (receipt.amount ?? 0) as NSNumber) ?? "$0.00"
  }
  
  var body: some View {
    HStack(spacing: 12) {
      // Thumbnail
      if let image = receiptsStore.loadImage(for: receipt) {
        Image(uiImage: image)
          .resizable()
          .scaledToFill()
          .frame(width: 50, height: 50)
          .clipShape(RoundedRectangle(cornerRadius: 6))
      } else {
        Image(systemName: receipt.type.systemImage)
          .font(.title2)
          .foregroundStyle(.secondary)
          .frame(width: 50, height: 50)
          .background {
            RoundedRectangle(cornerRadius: 6)
              .fill(.secondary.opacity(0.1))
          }
      }
      
      VStack(alignment: .leading, spacing: 4) {
        Text(receipt.type.displayName)
          .font(.headline)
        
        if let notes = receipt.notes {
          Text(notes)
            .font(.caption)
            .foregroundStyle(.secondary)
            .lineLimit(1)
        }
      }
      
      Spacer()
      
      Text(formattedAmount)
        .font(.subheadline.bold())
    }
  }
}

#Preview("Receipt Edit Sheet") {
  ReceiptEditSheet(
    trip: Trip(
      date: Date(),
      distanceMiles: 25.5,
      startLabel: "Home",
      endLabel: "Office",
      source: .manual,
      state: .confirmed,
      category: "Business"
    )
  ) { _, _ in }
}
