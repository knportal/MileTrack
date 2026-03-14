import MapKit
import SwiftUI

struct AddressAutocompleteField: View {
  let placeholder: String
  @Binding var text: String
  let accessibilityLabel: String

  @StateObject private var autocomplete = AddressAutocompleteService()
  @FocusState private var isFocused: Bool
  @State private var showSuggestions: Bool = false

  var body: some View {
    VStack(alignment: .leading, spacing: 0) {
      TextField(placeholder, text: $text)
        .textInputAutocapitalization(.words)
        .focused($isFocused)
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay {
          RoundedRectangle(cornerRadius: 12, style: .continuous)
            .strokeBorder(Color.primary.opacity(0.08), lineWidth: 1)
        }
        .accessibilityLabel(accessibilityLabel)
        .onChange(of: text) { _, newValue in
          if isFocused {
            autocomplete.search(query: newValue)
            showSuggestions = true
          }
        }
        .onChange(of: isFocused) { _, focused in
          if !focused {
            // Delay hiding suggestions to allow tap to register
            Task {
              try? await Task.sleep(for: .milliseconds(200))
              showSuggestions = false
              autocomplete.cancel()
            }
          } else if !text.isEmpty {
            autocomplete.search(query: text)
            showSuggestions = true
          }
        }

      if showSuggestions && !autocomplete.suggestions.isEmpty {
        suggestionsOverlay
      }
    }
  }

  private var suggestionsOverlay: some View {
    VStack(alignment: .leading, spacing: 0) {
      ForEach(autocomplete.suggestions.prefix(5), id: \.self) { suggestion in
        Button {
          selectSuggestion(suggestion)
        } label: {
          suggestionRow(suggestion)
        }
        .buttonStyle(.plain)

        if suggestion != autocomplete.suggestions.prefix(5).last {
          Divider()
            .padding(.leading, 12)
        }
      }
    }
    .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
    .overlay {
      RoundedRectangle(cornerRadius: 12, style: .continuous)
        .strokeBorder(Color.primary.opacity(0.08), lineWidth: 1)
    }
    .padding(.top, 4)
  }

  private func suggestionRow(_ suggestion: MKLocalSearchCompletion) -> some View {
    HStack(spacing: 10) {
      Image(systemName: "mappin.circle.fill")
        .font(.body)
        .foregroundStyle(.secondary)

      VStack(alignment: .leading, spacing: 2) {
        Text(suggestion.title)
          .font(.subheadline)
          .foregroundStyle(.primary)
          .lineLimit(1)

        if !suggestion.subtitle.isEmpty {
          Text(suggestion.subtitle)
            .font(.caption)
            .foregroundStyle(.secondary)
            .lineLimit(1)
        }
      }

      Spacer(minLength: 0)
    }
    .padding(.horizontal, 12)
    .padding(.vertical, 10)
    .contentShape(Rectangle())
  }

  private func selectSuggestion(_ suggestion: MKLocalSearchCompletion) {
    Task {
      if let fullAddress = await autocomplete.getFullAddress(for: suggestion) {
        text = fullAddress
      } else {
        // Fallback to title + subtitle
        if suggestion.subtitle.isEmpty {
          text = suggestion.title
        } else {
          text = "\(suggestion.title), \(suggestion.subtitle)"
        }
      }
      showSuggestions = false
      autocomplete.cancel()
      isFocused = false
    }
  }
}

#Preview {
  VStack {
    AddressAutocompleteField(
      placeholder: "Start location",
      text: .constant(""),
      accessibilityLabel: "Start location"
    )
    .padding()
  }
}
