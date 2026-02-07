import Foundation

enum ExportDateRangePreset: String, CaseIterable, Identifiable {
  case monthToDate = "Month"
  case yearToDate = "YTD"
  case year = "Year"
  case custom = "Custom"

  var id: String { rawValue }
}

struct ExportDateRange {
  var start: Date
  var end: Date
}

final class ExportService {
  private let calendar: Calendar

  init(calendar: Calendar = .current) {
    self.calendar = calendar
  }

  func range(
    for preset: ExportDateRangePreset,
    now: Date = Date(),
    custom: ExportDateRange? = nil
  ) -> ExportDateRange {
    switch preset {
    case .monthToDate:
      let start = calendar.date(from: calendar.dateComponents([.year, .month], from: now)) ?? now
      return ExportDateRange(start: start, end: now)
    case .yearToDate:
      let start = calendar.date(from: calendar.dateComponents([.year], from: now)) ?? now
      return ExportDateRange(start: start, end: now)
    case .year:
      let yearStart = calendar.date(from: calendar.dateComponents([.year], from: now)) ?? now
      let yearEnd: Date = {
        guard let startOfNextYear = calendar.date(byAdding: .year, value: 1, to: yearStart) else { return now }
        return calendar.date(byAdding: .second, value: -1, to: startOfNextYear) ?? now
      }()
      return ExportDateRange(start: yearStart, end: min(yearEnd, now))
    case .custom:
      if let custom { return normalized(range: custom) }
      return ExportDateRange(start: now, end: now)
    }
  }

  func confirmedTrips(in range: ExportDateRange, from trips: [Trip]) -> [Trip] {
    let range = normalized(range: range)
    return trips
      .filter { $0.state == .confirmed }
      .filter { $0.date >= range.start && $0.date <= range.end }
      .sorted { $0.date < $1.date }
  }

  func confirmedTrips(
    in range: ExportDateRange,
    from trips: [Trip],
    category: String?,
    client: String?,
    projectCode: String?
  ) -> [Trip] {
    let base = confirmedTrips(in: range, from: trips)
    return base.filter { trip in
      if let category = normalizedFilterValue(category) {
        let tripValue = normalizedFilterValue(trip.category) ?? ""
        if tripValue.caseInsensitiveCompare(category) != .orderedSame { return false }
      }
      if let client = normalizedFilterValue(client) {
        let tripValue = normalizedFilterValue(trip.clientOrOrg) ?? ""
        if tripValue.caseInsensitiveCompare(client) != .orderedSame { return false }
      }
      if let projectCode = normalizedFilterValue(projectCode) {
        let tripValue = normalizedFilterValue(trip.projectCode) ?? ""
        if tripValue.caseInsensitiveCompare(projectCode) != .orderedSame { return false }
      }
      return true
    }
  }

  func makeCSV(trips: [Trip]) -> String {
    let header = [
      "date",
      "category",
      "miles",
      "source",
      "startLabel",
      "endLabel",
      "client",
      "project",
      "notes",
    ].joined(separator: ",")

    let df = ISO8601DateFormatter()
    df.formatOptions = [.withInternetDateTime]

    func field(_ value: String?) -> String {
      escapeCSV(value ?? "")
    }

    func milesField(_ miles: Double) -> String {
      // Use a stable dot-decimal representation regardless of locale.
      let formatter = NumberFormatter()
      formatter.locale = Locale(identifier: "en_US_POSIX")
      formatter.numberStyle = .decimal
      formatter.minimumFractionDigits = 2
      formatter.maximumFractionDigits = 2
      let text = formatter.string(from: NSNumber(value: miles)) ?? "\(miles)"
      return escapeCSV(text)
    }

    let lines: [String] = trips.map { trip in
      [
        escapeCSV(df.string(from: trip.date)),
        field(trip.category),
        milesField(trip.distanceMiles),
        escapeCSV(trip.source.rawValue),
        field(trip.startLabel),
        field(trip.endLabel),
        field(trip.clientOrOrg),
        field(trip.projectCode),
        field(trip.notes),
      ].joined(separator: ",")
    }

    return ([header] + lines).joined(separator: "\n") + "\n"
  }

  func writeCSVToTemporaryFile(csv: String, filename: String) throws -> URL {
    let sanitized = filename.replacingOccurrences(of: "/", with: "-")
    let url = FileManager.default.temporaryDirectory.appendingPathComponent(sanitized).appendingPathExtension("csv")
    try csv.data(using: .utf8)?.write(to: url, options: [.atomic])
    return url
  }

  // MARK: - CSV escaping

  private func escapeCSV(_ input: String) -> String {
    // RFC 4180-ish: wrap in quotes if contains comma, quote, or newline; escape quotes by doubling.
    let needsQuotes = input.contains(",") || input.contains("\"") || input.contains("\n") || input.contains("\r")
    if !needsQuotes { return input }
    let escaped = input.replacingOccurrences(of: "\"", with: "\"\"")
    return "\"\(escaped)\""
  }

  private func normalized(range: ExportDateRange) -> ExportDateRange {
    // Ensure start <= end and extend end to end-of-day for date-picker friendliness.
    let start = min(range.start, range.end)
    let end = max(range.start, range.end)
    let endOfDay = calendar.date(bySettingHour: 23, minute: 59, second: 59, of: end) ?? end
    return ExportDateRange(start: start, end: endOfDay)
  }

  private func normalizedFilterValue(_ value: String?) -> String? {
    let trimmed = value?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
    return trimmed.isEmpty ? nil : trimmed
  }
}

