import CoreLocation
import Foundation
import MapKit

/// Reverse geocoding with caching + in-flight de-dupe.
///
/// - Cache key: rounded (3 decimals) lat/lon + locale identifier.
/// - Uses MapKit reverse-geocoding (iOS 26+) to avoid deprecated `CLGeocoder`.
actor ReverseGeocodeService {
  struct CacheKey: Hashable {
    let latRounded: Int
    let lonRounded: Int
    let localeID: String
  }

  private var cache: [CacheKey: String] = [:]
  private var inFlight: [CacheKey: Task<String?, Never>] = [:]
  private var recentFailures: [CacheKey: Date] = [:]

  private enum Reliability {
    static let timeoutSeconds: TimeInterval = 6
    static let failureBackoffSeconds: TimeInterval = 20 * 60 // 20 minutes
  }

  func label(for location: CLLocation, locale: Locale = .current) async -> String? {
    let key = makeKey(location: location, locale: locale)

    if let cached = cache[key] { return cached }
    if let lastFailure = recentFailures[key], Date().timeIntervalSince(lastFailure) < Reliability.failureBackoffSeconds {
      return nil
    }
    if let existing = inFlight[key] { return await existing.value }

    let task = Task<String?, Never> {
#if DEBUG
      print("[ReverseGeocode] request key=\(key.latRounded),\(key.lonRounded) locale=\(key.localeID)")
#endif
      do {
        guard let request = MKReverseGeocodingRequest(location: location) else {
#if DEBUG
          print("[ReverseGeocode] failed to create MKReverseGeocodingRequest")
#endif
          return nil
        }
        request.preferredLocale = locale

        let items: [MKMapItem] = try await Self.getMapItemsWithTimeout(
          request: request,
          timeoutSeconds: Reliability.timeoutSeconds
        )

        let label = Self.format(mapItem: items.first)
#if DEBUG
        if let label {
          print("[ReverseGeocode] resolved \(label)")
        } else {
          print("[ReverseGeocode] resolved nil")
        }
#endif
        return label
      } catch {
#if DEBUG
        print("[ReverseGeocode] failed \(error)")
#endif
        return nil
      }
    }

    inFlight[key] = task
    let result = await task.value
    inFlight[key] = nil

    if let result {
      cache[key] = result
      recentFailures[key] = nil
    } else {
      recentFailures[key] = Date()
    }

    return result
  }

  private func makeKey(location: CLLocation, locale: Locale) -> CacheKey {
    // 3 decimals ~ 110m lat resolution.
    let scale = 1000.0
    let latRounded = Int((location.coordinate.latitude * scale).rounded())
    let lonRounded = Int((location.coordinate.longitude * scale).rounded())
    let localeID = locale.identifier
    return CacheKey(latRounded: latRounded, lonRounded: lonRounded, localeID: localeID)
  }

  private static func format(mapItem: MKMapItem?) -> String? {
    guard let mapItem else { return nil }

    // Prefer "City, ST" (e.g. "Cupertino, CA").
    if let cityWithContext = mapItem.addressRepresentations?.cityWithContext?.trimmingCharacters(in: .whitespacesAndNewlines),
       !cityWithContext.isEmpty
    {
      return cityWithContext
    }

    // Fallback to formatted address strings.
    if let short = mapItem.address?.shortAddress?.trimmingCharacters(in: .whitespacesAndNewlines),
       !short.isEmpty
    {
      return short
    }

    if let full = mapItem.address?.fullAddress.trimmingCharacters(in: .whitespacesAndNewlines),
       !full.isEmpty
    {
      return full
    }

    // Last resort: Map item name (POI name, etc).
    if let name = mapItem.name?.trimmingCharacters(in: .whitespacesAndNewlines), !name.isEmpty {
      return name
    }

    return nil
  }

  private static func getMapItemsWithTimeout(
    request: MKReverseGeocodingRequest,
    timeoutSeconds: TimeInterval
  ) async throws -> [MKMapItem] {
    try await withThrowingTaskGroup(of: [MKMapItem].self) { group in
      group.addTask {
        try await withCheckedThrowingContinuation { continuation in
          request.getMapItems { items, error in
            if let error {
              continuation.resume(throwing: error)
              return
            }
            continuation.resume(returning: items ?? [])
          }
        }
      }
      group.addTask {
        let ns = UInt64(max(0, timeoutSeconds) * 1_000_000_000)
        try await Task.sleep(nanoseconds: ns)
        return []
      }

      let first = try await group.next() ?? []
      group.cancelAll()
      return first
    }
  }
}

