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

  func makeCSV(
    trips: [Trip],
    vehicles: [NamedVehicle] = [],
    rates: [MileageRate] = [],
    receipts: [TripReceipt] = []
  ) -> String {
    let header = [
      "Date",
      "From",
      "To",
      "Miles",
      "Category",
      "Purpose",
      "Vehicle",
      "Client",
      "Project",
      "Mileage Rate",
      "Mileage Amount",
      "Receipts",
      "Receipt Total",
      "Total Reimbursement",
      "Notes",
    ].joined(separator: ",")

    let df = DateFormatter()
    df.locale = Locale(identifier: "en_US_POSIX")
    df.dateFormat = "yyyy-MM-dd"

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

    func vehicleName(_ id: UUID?) -> String? {
      guard let id else { return nil }
      return vehicles.first(where: { $0.id == id })?.name
    }

    let calculator = ExpenseCalculator()
    
    let lines: [String] = trips.map { trip in
      let calculation = calculator.calculateExpense(for: trip, rates: rates, receipts: receipts)
      let tripReceipts = receipts.filter { $0.tripId == trip.id }
      
      // Format receipts as comma-separated list
      let receiptsList = tripReceipts.map { receipt in
        let type = receipt.type.displayName
        let amount = receipt.amount.map { formatDecimal($0) } ?? ""
        return "\(type): \(amount)"
      }.joined(separator: "; ")
      
      let from = fullLocation(address: trip.startAddress, label: trip.startLabel)
      let to = fullLocation(address: trip.endAddress, label: trip.endLabel)

      return [
        escapeCSV(df.string(from: trip.date)),
        field(from),
        field(to),
        milesField(trip.distanceMiles),
        field(trip.category),
        field(trip.purpose),
        field(vehicleName(trip.vehicleID)),
        field(trip.clientOrOrg),
        field(trip.projectCode),
        field(calculation.map { formatDecimal($0.mileageRate) }),
        field(calculation.map { formatDecimal($0.mileageAmount) }),
        field(receiptsList.isEmpty ? nil : receiptsList),
        field(calculation.map { formatDecimal($0.receiptsAmount) }),
        field(calculation.map { formatDecimal($0.totalAmount) }),
        field(trip.notes),
      ].joined(separator: ",")
    }

    // Totals row
    let totalMiles = trips.reduce(0.0) { $0 + $1.distanceMiles }
    let calculations = trips.compactMap { calculator.calculateExpense(for: $0, rates: rates, receipts: receipts) }
    let totalMileageAmount = calculations.reduce(Decimal.zero) { $0 + $1.mileageAmount }
    let totalReceiptAmount = calculations.reduce(Decimal.zero) { $0 + $1.receiptsAmount }
    let totalReimbursement = calculations.reduce(Decimal.zero) { $0 + $1.totalAmount }

    let totalsRow = [
      escapeCSV("TOTALS"),
      "", "",
      milesField(totalMiles),
      "", "", "", "", "",
      "",
      escapeCSV(formatDecimal(totalMileageAmount)),
      "",
      escapeCSV(formatDecimal(totalReceiptAmount)),
      escapeCSV(formatDecimal(totalReimbursement)),
      "",
    ].joined(separator: ",")

    return ([header] + lines + [""] + [totalsRow]).joined(separator: "\n") + "\n"
  }

  func writeCSVToTemporaryFile(csv: String, filename: String) throws -> URL {
    let sanitized = filename.replacingOccurrences(of: "/", with: "-")
    let url = FileManager.default.temporaryDirectory.appendingPathComponent(sanitized).appendingPathExtension("csv")
    try csv.data(using: .utf8)?.write(to: url, options: [.atomic, .completeFileProtection])
    return url
  }

  // MARK: - Formatting Helpers
  
  private func formatDecimal(_ value: Decimal) -> String {
    let formatter = NumberFormatter()
    formatter.locale = Locale(identifier: "en_US_POSIX")
    formatter.numberStyle = .decimal
    formatter.minimumFractionDigits = 2
    formatter.maximumFractionDigits = 2
    return formatter.string(from: value as NSNumber) ?? "\(value)"
  }

  /// Combines address and label into a single location string.
  /// Prefers address (full street); appends label in parentheses if it adds info.
  private func fullLocation(address: String?, label: String?) -> String? {
    let addr = address?.trimmingCharacters(in: .whitespacesAndNewlines)
    let lbl = label?.trimmingCharacters(in: .whitespacesAndNewlines)
    let hasAddr = addr != nil && !addr!.isEmpty
    let hasLabel = lbl != nil && !lbl!.isEmpty

    if hasAddr && hasLabel {
      // If the address already contains the label text, skip the label
      if addr!.localizedCaseInsensitiveContains(lbl!) {
        return addr
      }
      return "\(lbl!) — \(addr!)"
    }
    if hasAddr { return addr }
    if hasLabel { return lbl }
    return nil
  }

  // MARK: - CSV escaping

  private func escapeCSV(_ input: String) -> String {
    // RFC 4180-ish: wrap in quotes if contains comma, quote, or newline; escape quotes by doubling.
    // Also guard against spreadsheet formula injection (DDE attacks) by prefixing dangerous chars.
    var sanitized = input
    if let first = sanitized.first, "=+-@\t\r".contains(first) {
      sanitized = "'" + sanitized
    }
    let needsQuotes = sanitized.contains(",") || sanitized.contains("\"") || sanitized.contains("\n") || sanitized.contains("\r")
    if !needsQuotes { return sanitized }
    let escaped = sanitized.replacingOccurrences(of: "\"", with: "\"\"")
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

