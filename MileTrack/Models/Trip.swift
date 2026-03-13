import Foundation

enum TripSource: String, CaseIterable, Sendable {
  case manual
  case auto
}

extension TripSource: Codable {
  init(from decoder: Decoder) throws {
    let raw = try decoder.singleValueContainer().decode(String.self)
    self = TripSource(rawValue: raw) ?? .manual
  }
}

enum TripState: String, CaseIterable, Sendable {
  case pendingCategory = "pending_category"
  case confirmed
  case ignored
}

extension TripState: Codable {
  init(from decoder: Decoder) throws {
    let raw = try decoder.singleValueContainer().decode(String.self)
    self = TripState(rawValue: raw) ?? .pendingCategory
  }
}

struct Trip: Identifiable, Codable, Equatable, Sendable {
  var id: UUID
  var date: Date
  var distanceMiles: Double
  var durationSeconds: Int?
  var startLabel: String?
  var endLabel: String?
  var startAddress: String?
  var endAddress: String?
  var startLatitude: Double?
  var startLongitude: Double?
  var endLatitude: Double?
  var endLongitude: Double?
  var source: TripSource
  var state: TripState
  /// Category is kept as a simple string for UI friendliness; see `TripCategory` for typed options.
  var category: String?
  var clientOrOrg: String?
  /// Optional project/job code (free text MVP).
  var projectCode: String?
  /// If present, the trip was prefilled by this rule and should show as a suggestion in Inbox.
  var suggestedByRuleName: String?
  var notes: String?
  /// Business purpose for IRS §274(d) compliance (e.g. "Client meeting", "Site visit").
  var purpose: String?
  /// Links this trip to a saved vehicle in VehiclesStore.
  var vehicleID: UUID?
  /// Intermediate stop labels from merged trips (e.g. ["Coffee Shop"] for Home→Coffee Shop→Office).
  var waypoints: [String]?

  init(
    id: UUID = UUID(),
    date: Date,
    distanceMiles: Double,
    durationSeconds: Int? = nil,
    startLabel: String? = nil,
    endLabel: String? = nil,
    startAddress: String? = nil,
    endAddress: String? = nil,
    startLatitude: Double? = nil,
    startLongitude: Double? = nil,
    endLatitude: Double? = nil,
    endLongitude: Double? = nil,
    source: TripSource,
    state: TripState,
    category: String? = nil,
    clientOrOrg: String? = nil,
    projectCode: String? = nil,
    suggestedByRuleName: String? = nil,
    notes: String? = nil,
    purpose: String? = nil,
    vehicleID: UUID? = nil,
    waypoints: [String]? = nil
  ) {
    self.id = id
    self.date = date
    self.distanceMiles = distanceMiles
    self.durationSeconds = durationSeconds
    self.startLabel = startLabel
    self.endLabel = endLabel
    self.startAddress = startAddress
    self.endAddress = endAddress
    self.startLatitude = startLatitude
    self.startLongitude = startLongitude
    self.endLatitude = endLatitude
    self.endLongitude = endLongitude
    self.source = source
    self.state = state
    self.category = category
    self.clientOrOrg = clientOrOrg
    self.projectCode = projectCode
    self.suggestedByRuleName = suggestedByRuleName
    self.notes = notes
    self.purpose = purpose
    self.vehicleID = vehicleID
    self.waypoints = waypoints
  }

  // MARK: - Display Helpers

  /// Best available start location for display: full address when available, label as fallback.
  var startDisplay: String? {
    let addr = startAddress?.trimmingCharacters(in: .whitespacesAndNewlines)
    if let addr, !addr.isEmpty { return addr }
    let label = startLabel?.trimmingCharacters(in: .whitespacesAndNewlines)
    if let label, !label.isEmpty { return label }
    return nil
  }

  /// Best available end location for display: full address when available, label as fallback.
  var endDisplay: String? {
    let addr = endAddress?.trimmingCharacters(in: .whitespacesAndNewlines)
    if let addr, !addr.isEmpty { return addr }
    let label = endLabel?.trimmingCharacters(in: .whitespacesAndNewlines)
    if let label, !label.isEmpty { return label }
    return nil
  }

  /// Route label chaining all stops using human-readable label fields.
  /// Uses labels (not full addresses) — suitable for compact single-line display.
  var routeLabel: String {
    let start = startLabel?.trimmingCharacters(in: .whitespacesAndNewlines)
    let end   = endLabel?.trimmingCharacters(in: .whitespacesAndNewlines)
    let stops = waypoints?.filter { !$0.isEmpty } ?? []

    var parts: [String] = []
    if let s = start, !s.isEmpty { parts.append(s) }
    parts.append(contentsOf: stops)
    if let e = end,   !e.isEmpty { parts.append(e) }

    switch parts.count {
    case 0:  return "Trip"
    case 1:  return parts[0]
    default: return parts.joined(separator: " → ")
    }
  }

  // MARK: - Resilient Decoding

  init(from decoder: Decoder) throws {
    let c = try decoder.container(keyedBy: CodingKeys.self)

    // Required fields — provide sensible defaults if missing/corrupted
    self.id = (try? c.decode(UUID.self, forKey: .id)) ?? UUID()
    self.date = (try? c.decode(Date.self, forKey: .date)) ?? Date()

    let rawDistance = (try? c.decode(Double.self, forKey: .distanceMiles)) ?? 0
    self.distanceMiles = rawDistance.isFinite && rawDistance >= 0 ? rawDistance : 0

    self.source = (try? c.decode(TripSource.self, forKey: .source)) ?? .manual
    self.state = (try? c.decode(TripState.self, forKey: .state)) ?? .pendingCategory

    // Optional fields — nil on missing or corrupted
    self.durationSeconds = try? c.decode(Int.self, forKey: .durationSeconds)
    self.startLabel = try? c.decode(String.self, forKey: .startLabel)
    self.endLabel = try? c.decode(String.self, forKey: .endLabel)
    self.startAddress = try? c.decode(String.self, forKey: .startAddress)
    self.endAddress = try? c.decode(String.self, forKey: .endAddress)
    self.startLatitude = try? c.decode(Double.self, forKey: .startLatitude)
    self.startLongitude = try? c.decode(Double.self, forKey: .startLongitude)
    self.endLatitude = try? c.decode(Double.self, forKey: .endLatitude)
    self.endLongitude = try? c.decode(Double.self, forKey: .endLongitude)
    self.category = try? c.decode(String.self, forKey: .category)
    self.clientOrOrg = try? c.decode(String.self, forKey: .clientOrOrg)
    self.projectCode = try? c.decode(String.self, forKey: .projectCode)
    self.suggestedByRuleName = try? c.decode(String.self, forKey: .suggestedByRuleName)
    self.notes = try? c.decode(String.self, forKey: .notes)
    self.purpose = try? c.decode(String.self, forKey: .purpose)
    self.vehicleID = try? c.decode(UUID.self, forKey: .vehicleID)
    self.waypoints = try? c.decode([String].self, forKey: .waypoints)
  }
}

