import SwiftUI

struct ContentView: View {
  @ObservedObject var store: MileStore

  @State private var isPresentingAdd = false

  var body: some View {
    NavigationStack {
      List {
        if store.entries.isEmpty {
          ContentUnavailableView(
            "No mileage yet",
            systemImage: "car",
            description: Text("Add your first entry to start tracking.")
          )
        } else {
          Section {
            ForEach(store.entries) { entry in
              VStack(alignment: .leading, spacing: 4) {
                HStack {
                  Text(entry.milesFormatted)
                    .font(.headline)
                  Spacer()
                  Text(entry.date, format: .dateTime.year().month().day())
                    .foregroundStyle(.secondary)
                }
                if let note = entry.note, !note.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                  Text(note)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                }
              }
              .accessibilityElement(children: .combine)
              .accessibilityLabel("\(entry.milesFormatted), \(entry.date.formatted(date: .abbreviated, time: .omitted))")
            }
            .onDelete(perform: store.delete)
          } header: {
            HStack {
              Text("Entries")
              Spacer()
              Text(store.totalMilesFormatted)
                .foregroundStyle(.secondary)
            }
          }
        }
      }
      .navigationTitle("MileTrack")
      .toolbar {
        ToolbarItem(placement: .topBarTrailing) {
          Button {
            isPresentingAdd = true
          } label: {
            Label("Add Entry", systemImage: "plus")
          }
        }
      }
      .sheet(isPresented: $isPresentingAdd) {
        AddEntryView(store: store)
      }
    }
  }
}

#Preview {
  ContentView(store: {
    let store = MileStore()
    store.entries = [
      MileEntry(date: Date().addingTimeInterval(-86_400), miles: 12.4, note: "Client visit"),
      MileEntry(date: Date(), miles: 3.1, note: "Errands"),
    ]
    return store
  }())
}

