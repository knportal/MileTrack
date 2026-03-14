import Combine
import Contacts
import MapKit

@MainActor
final class AddressAutocompleteService: NSObject, ObservableObject {
  @Published var suggestions: [MKLocalSearchCompletion] = []
  @Published var isSearching: Bool = false

  private let completer: MKLocalSearchCompleter
  private var debounceTask: Task<Void, Never>?

  override init() {
    completer = MKLocalSearchCompleter()
    completer.resultTypes = [.address, .pointOfInterest]
    super.init()
    completer.delegate = self
  }

  func search(query: String) {
    debounceTask?.cancel()

    let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !trimmed.isEmpty else {
      suggestions = []
      isSearching = false
      return
    }

    isSearching = true

    debounceTask = Task {
      try? await Task.sleep(nanoseconds: 300_000_000) // 300ms
      guard !Task.isCancelled else { return }
      completer.queryFragment = trimmed
    }
  }

  func cancel() {
    debounceTask?.cancel()
    completer.cancel()
    suggestions = []
    isSearching = false
  }

  func getFullAddress(for completion: MKLocalSearchCompletion) async -> String? {
    let request = MKLocalSearch.Request(completion: completion)
    let search = MKLocalSearch(request: request)

    do {
      let response = try await search.start()
      if let mapItem = response.mapItems.first {
        return formatAddress(from: mapItem)
      }
    } catch {
      // Fall back to completion title + subtitle
    }

    // Fallback: combine title and subtitle
    let title = completion.title
    let subtitle = completion.subtitle
    if subtitle.isEmpty {
      return title
    }
    return "\(title), \(subtitle)"
  }

  private func formatAddress(from mapItem: MKMapItem) -> String {
    // Use iOS 26+ address API when available
    if #available(iOS 26.0, *) {
      // Prefer the full formatted address
      if let fullAddress = mapItem.address?.fullAddress.trimmingCharacters(in: .whitespacesAndNewlines),
         !fullAddress.isEmpty
      {
        return fullAddress
      }
      
      // Fallback to short address
      if let shortAddress = mapItem.address?.shortAddress?.trimmingCharacters(in: .whitespacesAndNewlines),
         !shortAddress.isEmpty
      {
        return shortAddress
      }
    }
    
    // For older iOS versions, use placemark
    if let placemark = mapItem.placemark.postalAddress {
      let formatter = CNPostalAddressFormatter()
      let formattedAddress = formatter.string(from: placemark)
      if !formattedAddress.isEmpty {
        return formattedAddress
      }
    }

    // Fallback: use name if available
    if let name = mapItem.name, !name.isEmpty {
      return name
    }

    // Final fallback to location coordinates
    if let location = mapItem.placemark.location {
      return String(format: "%.4f, %.4f", 
                   location.coordinate.latitude, 
                   location.coordinate.longitude)
    }
    
    return "Unknown Location"
  }
}

extension AddressAutocompleteService: MKLocalSearchCompleterDelegate {
  nonisolated func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
    Task { @MainActor in
      self.suggestions = completer.results
      self.isSearching = false
    }
  }

  nonisolated func completer(_ completer: MKLocalSearchCompleter, didFailWithError error: Error) {
    Task { @MainActor in
      self.suggestions = []
      self.isSearching = false
    }
  }
}
