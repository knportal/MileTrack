import SwiftUI

struct ManageCategoriesView: View {
  @EnvironmentObject private var categoriesStore: CategoriesStore
  @EnvironmentObject private var tripStore: TripStore

  @State private var isPresentingAdd: Bool = false
  @State private var addName: String = ""

  @State private var renamingCategory: String?
  @State private var renameName: String = ""

  @State private var deletingCategory: String?

  @State private var message: String?

  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 14) {
        headerCard
        listCard
        if let message {
          Text(message)
            .font(.footnote)
            .foregroundStyle(.secondary)
            .padding(.horizontal, 4)
        }
      }
      .padding(.horizontal, 16)
      .padding(.vertical, 12)
    }
    .background(.background)
    .navigationTitle("Categories")
    .toolbar {
      ToolbarItem(placement: .topBarTrailing) {
        Button {
          addName = ""
          isPresentingAdd = true
        } label: {
          Image(systemName: "plus")
        }
        .accessibilityLabel("Add category")
      }
    }
    .alert("Add Category", isPresented: $isPresentingAdd) {
      TextField("Category name", text: $addName)
      Button("Add") { addCategory() }
      Button("Cancel", role: .cancel) {}
    } message: {
      Text("Names can’t be empty or duplicates.")
    }
    .alert("Rename Category", isPresented: Binding(
      get: { renamingCategory != nil },
      set: { if !$0 { renamingCategory = nil } }
    )) {
      TextField("New name", text: $renameName)
      Button("Save") { renameCategory() }
      Button("Cancel", role: .cancel) { renamingCategory = nil }
    } message: {
      Text("Renaming updates existing trips that use the category.")
    }
    .confirmationDialog(
      "Delete Category?",
      isPresented: Binding(
        get: { deletingCategory != nil },
        set: { if !$0 { deletingCategory = nil } }
      ),
      titleVisibility: .visible
    ) {
      Button("Delete", role: .destructive) {
        deleteCategory()
      }
      Button("Cancel", role: .cancel) {
        deletingCategory = nil
      }
    } message: {
      Text("Trips using this category will be moved back to Inbox (category cleared).")
    }
  }

  private var headerCard: some View {
    GlassCard {
      VStack(alignment: .leading, spacing: 8) {
        Text("Manage Categories")
          .font(.headline)
        Text("Categories are used to confirm trips. Deleting a category will un-confirm affected trips.")
          .font(.footnote)
          .foregroundStyle(.secondary)
      }
    }
  }

  private var listCard: some View {
    GlassCard {
      VStack(alignment: .leading, spacing: 10) {
        HStack {
          Text("Categories")
            .font(.headline)
          Spacer(minLength: 0)
          Text("\(categoriesStore.categories.count)")
            .foregroundStyle(.secondary)
            .font(.subheadline)
            .accessibilityHidden(true)
        }

        if categoriesStore.categories.isEmpty {
          EmptyStateView(
            systemImage: "tag",
            title: "No categories yet",
            subtitle: "Add a category to confirm trips from Inbox.",
            actionTitle: "Add Category",
            action: {
              addName = ""
              isPresentingAdd = true
            }
          )
        } else {
          VStack(spacing: 10) {
            ForEach(categoriesStore.categories, id: \.self) { category in
              categoryRow(category)
            }
          }
        }
      }
    }
  }

  private func categoryRow(_ category: String) -> some View {
    HStack(spacing: 10) {
      Text(category)
        .font(.subheadline.weight(.semibold))
        .lineLimit(1)

      Spacer(minLength: 0)

      Button {
        renamingCategory = category
        renameName = category
      } label: {
        Image(systemName: "pencil")
          .font(.footnote.weight(.semibold))
          .padding(8)
          .background(.thinMaterial, in: Circle())
          .overlay {
            Circle()
              .strokeBorder(Color.primary.opacity(0.10), lineWidth: 1)
          }
      }
      .buttonStyle(.plain)
      .accessibilityLabel("Rename \(category)")

      Button(role: .destructive) {
        if categoriesStore.categories.count <= 1 {
          message = "You can’t delete the last category."
          return
        }
        deletingCategory = category
      } label: {
        Image(systemName: "trash")
          .font(.footnote.weight(.semibold))
          .padding(8)
          .background(.thinMaterial, in: Circle())
          .overlay {
            Circle()
              .strokeBorder(Color.primary.opacity(0.10), lineWidth: 1)
          }
      }
      .buttonStyle(.plain)
      .accessibilityLabel("Delete \(category)")
    }
    .accessibilityElement(children: .combine)
  }

  private func addCategory() {
    let trimmed = addName.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !trimmed.isEmpty else {
      message = "Please enter a category name."
      return
    }
    if categoriesStore.add(trimmed) {
      message = nil
    } else {
      message = "That category already exists."
    }
  }

  private func renameCategory() {
    guard let old = renamingCategory else { return }
    let trimmed = renameName.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !trimmed.isEmpty else {
      message = "Name can’t be empty."
      return
    }

    if categoriesStore.rename(from: old, to: trimmed) {
      updateTripsRenamingCategory(from: old, to: trimmed)
      message = nil
      renamingCategory = nil
    } else {
      message = "Rename failed (duplicate or missing)."
    }
  }

  private func deleteCategory() {
    guard let toDelete = deletingCategory else { return }
    deletingCategory = nil

    if categoriesStore.categories.count <= 1 {
      message = "You can’t delete the last category."
      return
    }

    if categoriesStore.remove(toDelete) {
      updateTripsDeletingCategory(toDelete)
      message = nil
    } else {
      message = "Delete failed."
    }
  }

  private func updateTripsRenamingCategory(from old: String, to new: String) {
    for idx in tripStore.trips.indices {
      let current = tripStore.trips[idx].category?.trimmingCharacters(in: .whitespacesAndNewlines)
      guard let current, !current.isEmpty else { continue }
      if current.caseInsensitiveCompare(old) == .orderedSame {
        tripStore.trips[idx].category = new
      }
    }
  }

  private func updateTripsDeletingCategory(_ name: String) {
    for idx in tripStore.trips.indices {
      let current = tripStore.trips[idx].category?.trimmingCharacters(in: .whitespacesAndNewlines)
      guard let current, !current.isEmpty else { continue }
      if current.caseInsensitiveCompare(name) == .orderedSame {
        tripStore.trips[idx].category = nil
        if tripStore.trips[idx].state == .confirmed {
          tripStore.trips[idx].state = .pendingCategory
        }
      }
    }
  }
}

#Preview {
  NavigationStack {
    ManageCategoriesView()
  }
  .environmentObject(CategoriesStore())
  .environmentObject(TripStore())
}

