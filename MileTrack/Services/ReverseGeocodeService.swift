import CoreLocation
import Foundation
import MapKit

/// Reverse geocoding with caching + in-flight de-dupe.
///
/// - Cache key: rounded (3 decimals) lat/lon + locale identifier.
/// - Uses MapKit reverse-geocoding (iOS 26+) when available, falls back to `CLGeocoder` on earlier versions.
actor ReverseGeocodeService {
  struct CacheKey: Hashable {
    let latRounded: Int
    let lonRounded: Int
    let localeID: String
  }
  
  struct AddressResult {
    let shortLabel: String
    let fullAddress: String?
  }

  private var cache: [CacheKey: AddressResult] = [:]
  private var inFlight: [CacheKey: Task<AddressResult?, Never>] = [:]
  private var recentFailures: [CacheKey: Date] = [:]

  private enum Reliability {
    static let timeoutSeconds: TimeInterval = 6
    static let failureBackoffSeconds: TimeInterval = 20 * 60 // 20 minutes
  }
  
  func addresses(for location: CLLocation, locale: Locale = .current) async -> AddressResult? {
    let key = makeKey(location: location, locale: locale)

    if let cached = cache[key] { return cached }
    if let lastFailure = recentFailures[key], Date().timeIntervalSince(lastFailure) < Reliability.failureBackoffSeconds {
      return nil
    }
    if let existing = inFlight[key] { return await existing.value }

    let task = Task<AddressResult?, Never> {
#if DEBUG
      print("[ReverseGeocode] request key=\(key.latRounded),\(key.lonRounded) locale=\(key.localeID)")
#endif
      do {
        if #available(iOS 26.0, *) {
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

          let result = Self.formatBoth(mapItem: items.first)
#if DEBUG
          if let result {
            print("[ReverseGeocode] resolved label=\(result.shortLabel) address=\(result.fullAddress ?? "nil")")
          } else {
            print("[ReverseGeocode] resolved nil")
          }
#endif
          return result
        } else {
          // Fallback to CLGeocoder for iOS < 26
          let placemarks = try await Self.getCLGeocoderPlacemarks(
            location: location,
            locale: locale,
            timeoutSeconds: Reliability.timeoutSeconds
          )
          
          let result = Self.formatCLPlacemark(placemarks.first)
#if DEBUG
          if let result {
            print("[ReverseGeocode] resolved label=\(result.shortLabel) address=\(result.fullAddress ?? "nil")")
          } else {
            print("[ReverseGeocode] resolved nil")
          }
#endif
          return result
        }
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

  func label(for location: CLLocation, locale: Locale = .current) async -> String? {
    let result = await addresses(for: location, locale: locale)
    return result?.shortLabel
  }

  private func makeKey(location: CLLocation, locale: Locale) -> CacheKey {
    // 3 decimals ~ 110m lat resolution.
    let scale = 1000.0
    let latRounded = Int((location.coordinate.latitude * scale).rounded())
    let lonRounded = Int((location.coordinate.longitude * scale).rounded())
    let localeID = locale.identifier
    return CacheKey(latRounded: latRounded, lonRounded: lonRounded, localeID: localeID)
  }

  @available(iOS 26.0, *)
  private static func formatBoth(mapItem: MKMapItem?) -> AddressResult? {
    guard let mapItem else { return nil }

    var shortLabel: String?
    var fullAddress: String?
    
    // Get full address first
    if let full = mapItem.address?.fullAddress.trimmingCharacters(in: .whitespacesAndNewlines),
       !full.isEmpty
    {
      fullAddress = full
    }
    
    // Prefer "City, ST" (e.g. "Cupertino, CA") for short label.
    if let cityWithContext = mapItem.addressRepresentations?.cityWithContext?.trimmingCharacters(in: .whitespacesAndNewlines),
       !cityWithContext.isEmpty
    {
      shortLabel = cityWithContext
    }

    // Fallback to formatted address strings for short label.
    if shortLabel == nil {
      if let short = mapItem.address?.shortAddress?.trimmingCharacters(in: .whitespacesAndNewlines),
         !short.isEmpty
      {
        shortLabel = short
      }
    }

    if shortLabel == nil, let full = fullAddress {
      shortLabel = full
    }

    // Last resort: Map item name (POI name, etc).
    if shortLabel == nil {
      if let name = mapItem.name?.trimmingCharacters(in: .whitespacesAndNewlines), !name.isEmpty {
        shortLabel = name
      }
    }

    guard let shortLabel else { return nil }
    return AddressResult(shortLabel: shortLabel, fullAddress: fullAddress)
  }
  
  private static func formatCLPlacemark(_ placemark: CLPlacemark?) -> AddressResult? {
    guard let placemark else { return nil }
    
    var shortLabel: String?
    var fullAddress: String?
    
    // Build full address from CLPlacemark components
    var addressComponents: [String] = []
    if let subThoroughfare = placemark.subThoroughfare {
      addressComponents.append(subThoroughfare)
    }
    if let thoroughfare = placemark.thoroughfare {
      addressComponents.append(thoroughfare)
    }
    if let locality = placemark.locality {
      addressComponents.append(locality)
    }
    if let administrativeArea = placemark.administrativeArea {
      addressComponents.append(administrativeArea)
    }
    if let postalCode = placemark.postalCode {
      addressComponents.append(postalCode)
    }
    if let country = placemark.country {
      addressComponents.append(country)
    }
    
    if !addressComponents.isEmpty {
      fullAddress = addressComponents.joined(separator: ", ")
    }
    
    // Prefer "City, State" for short label
    if let locality = placemark.locality, let administrativeArea = placemark.administrativeArea {
      shortLabel = "\(locality), \(administrativeArea)"
    }
    
    // Fallback to just locality
    if shortLabel == nil, let locality = placemark.locality {
      shortLabel = locality
    }
    
    // Fallback to administrative area
    if shortLabel == nil, let administrativeArea = placemark.administrativeArea {
      shortLabel = administrativeArea
    }
    
    // Fallback to full address
    if shortLabel == nil, let full = fullAddress {
      shortLabel = full
    }
    
    // Last resort: name
    if shortLabel == nil, let name = placemark.name?.trimmingCharacters(in: .whitespacesAndNewlines), !name.isEmpty {
      shortLabel = name
    }
    
    guard let shortLabel else { return nil }
    return AddressResult(shortLabel: shortLabel, fullAddress: fullAddress)
  }

  @available(iOS 26.0, *)
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
  
  private static func getCLGeocoderPlacemarks(
    location: CLLocation,
    locale: Locale,
    timeoutSeconds: TimeInterval
  ) async throws -> [CLPlacemark] {
    try await withThrowingTaskGroup(of: [CLPlacemark].self) { group in
      group.addTask {
        try await withCheckedThrowingContinuation { continuation in
          let geocoder = CLGeocoder()
          geocoder.reverseGeocodeLocation(location, preferredLocale: locale) { placemarks, error in
            if let error {
              continuation.resume(throwing: error)
              return
            }
            continuation.resume(returning: placemarks ?? [])
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

