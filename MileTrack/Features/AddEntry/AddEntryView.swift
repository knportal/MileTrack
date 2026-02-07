import SwiftUI

struct AddEntryView: View {
  @Environment(\.dismiss) private var dismiss

  @ObservedObject var store: MileStore

  @State private var date = Date()
  @State private var milesText = ""
  @State private var note = ""

  @State private var validationMessage: String?

  var body: some View {
    NavigationStack {
      Form {
        Section("Entry") {
          DatePicker("Date", selection: $date, displayedComponents: [.date])
          TextField("Miles", text: $milesText)
            .keyboardType(.decimalPad)
          TextField("Note (optional)", text: $note, axis: .vertical)
            .lineLimit(2...4)
        }

        if let validationMessage {
          Section {
            Text(validationMessage)
              .foregroundStyle(.red)
          }
        }
      }
      .navigationTitle("Add Entry")
      .toolbar {
        ToolbarItem(placement: .cancellationAction) {
          Button("Cancel") { dismiss() }
        }
        ToolbarItem(placement: .confirmationAction) {
          Button("Save") { save() }
        }
      }
    }
  }

  private func save() {
    let trimmed = milesText.trimmingCharacters(in: .whitespacesAndNewlines)
      .replacingOccurrences(of: ",", with: ".")

    guard let miles = Double(trimmed) else {
      validationMessage = "Please enter a valid number of miles."
      return
    }
    guard miles > 0 else {
      validationMessage = "Miles must be greater than 0."
      return
    }

    store.add(date: date, miles: miles, note: note)
    dismiss()
  }
}

#Preview {
  AddEntryView(store: MileStore())
}

