import Foundation

/// Namespace for nonisolated Trip decoding utilities.
/// Kept in a separate file to ensure no main-actor isolation inference.
enum TripDecoder {
  /// Mirrors TripPersistenceStore's per-trip fallback decoding strategy.
  /// Decodes Trip data in a nonisolated context.
  static func decodeTrips(from data: Data) -> [Trip] {
    let decoder = JSONDecoder()
    decoder.dateDecodingStrategy = .deferredToDate
    if let trips = try? decoder.decode([Trip].self, from: data) { return trips }
    guard let raw = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]] else { return [] }
    return raw.compactMap { element in
      guard let d = try? JSONSerialization.data(withJSONObject: element) else { return nil }
      return try? decoder.decode(Trip.self, from: d)
    }
  }
}
