import Foundation
import UIKit

struct PDFSummarySectionRow {
  let title: String
  let miles: Double
}

final class PDFExportService {
  private let calendar: Calendar

  init(calendar: Calendar = .current) {
    self.calendar = calendar
  }

  func writeSummaryPDFToTemporaryFile(
    trips: [Trip],
    range: ExportDateRange,
    includeClientBreakdown: Bool,
    vehicles: [NamedVehicle] = [],
    rates: [MileageRate] = [],
    receipts: [TripReceipt] = [],
    filename: String
  ) throws -> URL {
    let data = makePDFData(
      trips: trips,
      range: range,
      includeClientBreakdown: includeClientBreakdown,
      vehicles: vehicles,
      rates: rates,
      receipts: receipts
    )

    let sanitized = filename.replacingOccurrences(of: "/", with: "-")
    let url = FileManager.default.temporaryDirectory
      .appendingPathComponent(sanitized)
      .appendingPathExtension("pdf")

    try data.write(to: url, options: [.atomic, .completeFileProtection])
    return url
  }

  // MARK: - Main Render

  private func makePDFData(
    trips: [Trip],
    range: ExportDateRange,
    includeClientBreakdown: Bool,
    vehicles: [NamedVehicle],
    rates: [MileageRate],
    receipts: [TripReceipt]
  ) -> Data {
    let pageRect = CGRect(x: 0, y: 0, width: 612, height: 792) // US Letter @ 72dpi
    let renderer = UIGraphicsPDFRenderer(bounds: pageRect)
    let margin: CGFloat = 48
    let contentWidth = pageRect.width - margin * 2
    let rangeText = formatRange(range)

    let confirmedTrips = trips.filter { $0.state == .confirmed }
    let totalMiles = confirmedTrips.reduce(0) { $0 + $1.distanceMiles }

    let byCategory = topRows(
      trips: confirmedTrips,
      key: { ($0.category ?? "").trimmingCharacters(in: .whitespacesAndNewlines) },
      emptyFallback: "Uncategorized",
      limit: 5
    )
    let byClient: [PDFSummarySectionRow] = includeClientBreakdown
      ? topRows(
        trips: confirmedTrips,
        key: { ($0.clientOrOrg ?? "").trimmingCharacters(in: .whitespacesAndNewlines) },
        emptyFallback: "No client",
        limit: 5
      ) : []
    let byVehicle = topRows(
      trips: confirmedTrips,
      key: { vehicleName(for: $0.vehicleID, vehicles: vehicles) },
      emptyFallback: "",
      limit: 5,
      skipEmpty: true
    )
    let byPurpose = topRows(
      trips: confirmedTrips,
      key: { ($0.purpose ?? "").trimmingCharacters(in: .whitespacesAndNewlines) },
      emptyFallback: "",
      limit: 5,
      skipEmpty: true
    )

    return renderer.pdfData { ctx in

      // MARK: Page 1 — Summary
      ctx.beginPage()
      var cursorY = margin

      cursorY += drawText(
        "MileTrack by Plenitudo",
        in: CGRect(x: margin, y: cursorY, width: contentWidth, height: 40),
        font: .systemFont(ofSize: 22, weight: .bold),
        color: .black
      )
      cursorY += 4

      cursorY += drawText(
        "Mileage Report · \(rangeText)",
        in: CGRect(x: margin, y: cursorY, width: contentWidth, height: 30),
        font: .systemFont(ofSize: 12, weight: .semibold),
        color: UIColor.black.withAlphaComponent(0.70)
      )
      cursorY += 14

      // Totals
      cursorY += drawSectionHeader("Total distance", x: margin, y: cursorY, width: contentWidth)
      cursorY += 6
      cursorY += drawText(
        milesText(totalMiles),
        in: CGRect(x: margin, y: cursorY, width: contentWidth, height: 28),
        font: .systemFont(ofSize: 18, weight: .bold),
        color: .black
      )
      cursorY += 4
      cursorY += drawText(
        "\(confirmedTrips.count) confirmed trip\(confirmedTrips.count == 1 ? "" : "s")",
        in: CGRect(x: margin, y: cursorY, width: contentWidth, height: 16),
        font: .systemFont(ofSize: 11, weight: .regular),
        color: UIColor.black.withAlphaComponent(0.55)
      )
      cursorY += 18
      
      // Total Expense
      let calculator = ExpenseCalculator()
      let totalExpense = calculator.calculateTotalExpense(for: confirmedTrips, rates: rates, receipts: receipts)
      
      cursorY += drawSectionHeader("Total expense", x: margin, y: cursorY, width: contentWidth)
      cursorY += 6
      cursorY += drawText(
        totalExpense.formattedTotal(),
        in: CGRect(x: margin, y: cursorY, width: contentWidth, height: 28),
        font: .systemFont(ofSize: 18, weight: .bold),
        color: .black
      )
      cursorY += 4
      cursorY += drawText(
        "Mileage: \(totalExpense.formattedMileageAmount()) · Receipts: \(totalExpense.formattedReceiptsAmount())",
        in: CGRect(x: margin, y: cursorY, width: contentWidth, height: 16),
        font: .systemFont(ofSize: 11, weight: .regular),
        color: UIColor.black.withAlphaComponent(0.55)
      )
      cursorY += 18

      // By category
      cursorY += drawSectionHeader("By category", x: margin, y: cursorY, width: contentWidth)
      cursorY += 8
      cursorY = drawRows(byCategory, x: margin, y: cursorY, width: contentWidth)
      cursorY += 18

      // By vehicle (new)
      if !byVehicle.isEmpty {
        cursorY += drawSectionHeader("By vehicle", x: margin, y: cursorY, width: contentWidth)
        cursorY += 8
        cursorY = drawRows(byVehicle, x: margin, y: cursorY, width: contentWidth)
        cursorY += 18
      }

      // By purpose (new)
      if !byPurpose.isEmpty {
        cursorY += drawSectionHeader("By business purpose", x: margin, y: cursorY, width: contentWidth)
        cursorY += 8
        cursorY = drawRows(byPurpose, x: margin, y: cursorY, width: contentWidth)
        cursorY += 18
      }

      // By client
      if includeClientBreakdown {
        cursorY += drawSectionHeader("By client", x: margin, y: cursorY, width: contentWidth)
        cursorY += 8
        cursorY = drawRows(byClient, x: margin, y: cursorY, width: contentWidth)
        cursorY += 18
      }

      drawPageFooter(pageRect: pageRect, margin: margin, contentWidth: contentWidth)

      // MARK: Page 2+ — IRS Trip Log
      if !confirmedTrips.isEmpty {
        let sorted = confirmedTrips.sorted { $0.date < $1.date }
        drawDetailPages(
          trips: sorted,
          vehicles: vehicles,
          rates: rates,
          receipts: receipts,
          rangeText: rangeText,
          ctx: ctx,
          pageRect: pageRect,
          margin: margin,
          contentWidth: contentWidth
        )
      }
    }
  }

  // MARK: - Detail Trip Log Pages

  private func drawDetailPages(
    trips: [Trip],
    vehicles: [NamedVehicle],
    rates: [MileageRate],
    receipts: [TripReceipt],
    rangeText: String,
    ctx: UIGraphicsPDFRendererContext,
    pageRect: CGRect,
    margin: CGFloat,
    contentWidth: CGFloat
  ) {
    let rowHeight: CGFloat = 17
    let footerClearance: CGFloat = margin + 20

    ctx.beginPage()
    var cursorY = drawDetailPageHeader(rangeText: rangeText, margin: margin, contentWidth: contentWidth)
    cursorY = drawTableColumnHeaders(x: margin, y: cursorY, contentWidth: contentWidth)

    let df = DateFormatter()
    df.locale = Locale(identifier: "en_US_POSIX")
    df.dateFormat = "MMM d"

    for (idx, trip) in trips.enumerated() {
      // Page break
      if cursorY + rowHeight > pageRect.height - footerClearance {
        drawPageFooter(pageRect: pageRect, margin: margin, contentWidth: contentWidth)
        ctx.beginPage()
        cursorY = drawDetailPageHeader(rangeText: rangeText, margin: margin, contentWidth: contentWidth)
        cursorY = drawTableColumnHeaders(x: margin, y: cursorY, contentWidth: contentWidth)
      }

      // Alternating stripe
      if idx % 2 == 1 {
        UIColor.black.withAlphaComponent(0.03).setFill()
        UIBezierPath(rect: CGRect(
          x: margin - 4, y: cursorY - 1,
          width: contentWidth + 8, height: rowHeight
        )).fill()
      }

      let cols = tableColumns(x: margin, contentWidth: contentWidth)
      
      // Calculate expenses for this trip
      let calculator = ExpenseCalculator()
      let calculation = calculator.calculateExpense(for: trip, rates: rates, receipts: receipts)
      let tripReceipts = receipts.filter { $0.tripId == trip.id }
      let receiptsTotal = tripReceipts.reduce(Decimal(0)) { $0 + ($1.amount ?? 0) }
      
      let values: [String] = [
        df.string(from: trip.date),
        trip.startLabel ?? "",
        trip.endLabel ?? "",
        milesText(trip.distanceMiles),
        calculation.map { formatCurrency($0.mileageRate) } ?? "",
        calculation.map { formatCurrency($0.mileageAmount) } ?? "",
        formatCurrency(receiptsTotal),
        calculation.map { formatCurrency($0.totalAmount) } ?? "",
        trip.category ?? "",
      ]
      let alignments: [NSTextAlignment] = [.left, .left, .left, .right, .right, .right, .right, .right, .left]

      for (i, col) in cols.enumerated() {
        _ = drawText(
          i < values.count ? values[i] : "",
          in: CGRect(x: col.x, y: cursorY, width: col.width, height: rowHeight),
          font: .systemFont(ofSize: 9.5, weight: .regular),
          color: UIColor.black.withAlphaComponent(0.82),
          alignment: i < alignments.count ? alignments[i] : .left
        )
      }

      cursorY += rowHeight
    }

    drawPageFooter(pageRect: pageRect, margin: margin, contentWidth: contentWidth)
  }

  // MARK: - Table Helpers

  private struct TableCol {
    let x: CGFloat
    let width: CGFloat
  }

  /// Column layout for expense report table (total = contentWidth).
  private func tableColumns(x: CGFloat, contentWidth: CGFloat) -> [TableCol] {
    // Date | Start | End | Miles | Rate | Mileage$ | Receipts | Total | Category
    let fractions: [CGFloat] = [0.08, 0.16, 0.16, 0.07, 0.07, 0.09, 0.09, 0.10, 0.18]
    let gap: CGFloat = 3
    var result: [TableCol] = []
    var curX = x
    for f in fractions {
      let w = contentWidth * f
      result.append(TableCol(x: curX, width: w - gap))
      curX += w
    }
    return result
  }

  @discardableResult
  private func drawDetailPageHeader(rangeText: String, margin: CGFloat, contentWidth: CGFloat) -> CGFloat {
    var y = margin

    y += drawText(
      "MileTrack by Plenitudo — IRS §274(d) Trip Log",
      in: CGRect(x: margin, y: y, width: contentWidth, height: 18),
      font: .systemFont(ofSize: 13, weight: .bold),
      color: .black
    )
    y += 3

    y += drawText(
      rangeText,
      in: CGRect(x: margin, y: y, width: contentWidth, height: 14),
      font: .systemFont(ofSize: 10, weight: .regular),
      color: UIColor.black.withAlphaComponent(0.55)
    )
    y += 8

    let sep = UIBezierPath()
    sep.move(to: CGPoint(x: margin, y: y))
    sep.addLine(to: CGPoint(x: margin + contentWidth, y: y))
    UIColor.black.withAlphaComponent(0.15).setStroke()
    sep.lineWidth = 1
    sep.stroke()

    return y + 8
  }

  @discardableResult
  private func drawTableColumnHeaders(x: CGFloat, y: CGFloat, contentWidth: CGFloat) -> CGFloat {
    let titles = ["Date", "Start", "End", "Miles", "Rate", "Mileage", "Receipts", "Total", "Category"]
    let alignments: [NSTextAlignment] = [.left, .left, .left, .right, .right, .right, .right, .right, .left]
    let cols = tableColumns(x: x, contentWidth: contentWidth)

    for (i, col) in cols.enumerated() {
      _ = drawText(
        i < titles.count ? titles[i] : "",
        in: CGRect(x: col.x, y: y, width: col.width, height: 14),
        font: .systemFont(ofSize: 9, weight: .semibold),
        color: UIColor.black.withAlphaComponent(0.50),
        alignment: i < alignments.count ? alignments[i] : .left
      )
    }

    let sep = UIBezierPath()
    let lineY = y + 16
    sep.move(to: CGPoint(x: x, y: lineY))
    sep.addLine(to: CGPoint(x: x + contentWidth, y: lineY))
    UIColor.black.withAlphaComponent(0.10).setStroke()
    sep.lineWidth = 0.5
    sep.stroke()

    return lineY + 4
  }

  private func drawPageFooter(pageRect: CGRect, margin: CGFloat, contentWidth: CGFloat) {
    _ = drawText(
      "Generated \(Date().formatted(date: .abbreviated, time: .shortened))",
      in: CGRect(x: margin, y: pageRect.height - margin - 14, width: contentWidth, height: 14),
      font: .systemFont(ofSize: 9, weight: .regular),
      color: UIColor.black.withAlphaComponent(0.45)
    )
  }

  // MARK: - Summary Section Helpers

  private func drawSectionHeader(_ title: String, x: CGFloat, y: CGFloat, width: CGFloat) -> CGFloat {
    let h = drawText(
      title,
      in: CGRect(x: x, y: y, width: width, height: 18),
      font: .systemFont(ofSize: 12, weight: .semibold),
      color: UIColor.black.withAlphaComponent(0.75)
    )
    let lineY = y + h + 6
    let path = UIBezierPath()
    path.move(to: CGPoint(x: x, y: lineY))
    path.addLine(to: CGPoint(x: x + width, y: lineY))
    UIColor.black.withAlphaComponent(0.10).setStroke()
    path.lineWidth = 1
    path.stroke()
    return h + 12
  }

  private func drawRows(_ rows: [PDFSummarySectionRow], x: CGFloat, y: CGFloat, width: CGFloat) -> CGFloat {
    var cursorY = y
    let titleWidth = width * 0.68
    let valueWidth = width - titleWidth

    if rows.isEmpty {
      cursorY += drawText(
        "No data.",
        in: CGRect(x: x, y: cursorY, width: width, height: 16),
        font: .systemFont(ofSize: 11, weight: .regular),
        color: UIColor.black.withAlphaComponent(0.65)
      )
      return cursorY
    }

    for row in rows {
      _ = drawText(
        row.title,
        in: CGRect(x: x, y: cursorY, width: titleWidth, height: 16),
        font: .systemFont(ofSize: 11, weight: .regular),
        color: UIColor.black.withAlphaComponent(0.85)
      )
      _ = drawText(
        milesText(row.miles),
        in: CGRect(x: x + titleWidth, y: cursorY, width: valueWidth, height: 16),
        font: .systemFont(ofSize: 11, weight: .semibold),
        color: UIColor.black.withAlphaComponent(0.85),
        alignment: .right
      )
      cursorY += 18
    }
    return cursorY
  }

  // MARK: - Core Drawing

  private func drawText(
    _ text: String,
    in rect: CGRect,
    font: UIFont,
    color: UIColor,
    alignment: NSTextAlignment = .left
  ) -> CGFloat {
    let paragraph = NSMutableParagraphStyle()
    paragraph.alignment = alignment
    paragraph.lineBreakMode = .byTruncatingTail

    let attrs: [NSAttributedString.Key: Any] = [
      .font: font,
      .foregroundColor: color,
      .paragraphStyle: paragraph,
    ]
    let attributed = NSAttributedString(string: text, attributes: attrs)
    let bounding = attributed.boundingRect(
      with: CGSize(width: rect.width, height: .greatestFiniteMagnitude),
      options: [.usesLineFragmentOrigin, .usesFontLeading],
      context: nil
    )
    attributed.draw(in: rect)
    return min(rect.height, ceil(bounding.height))
  }

  // MARK: - Data Helpers
  
  private func formatCurrency(_ amount: Decimal) -> String {
    let formatter = NumberFormatter()
    formatter.numberStyle = .currency
    formatter.currencyCode = "USD"
    formatter.maximumFractionDigits = 2
    return formatter.string(from: amount as NSNumber) ?? "$0.00"
  }

  private func topRows(
    trips: [Trip],
    key: (Trip) -> String,
    emptyFallback: String,
    limit: Int,
    skipEmpty: Bool = false
  ) -> [PDFSummarySectionRow] {
    var totals: [String: Double] = [:]
    for trip in trips {
      let raw = key(trip)
      if raw.isEmpty {
        if skipEmpty { continue }
        totals[emptyFallback, default: 0] += trip.distanceMiles
      } else {
        totals[raw, default: 0] += trip.distanceMiles
      }
    }
    return totals
      .map { PDFSummarySectionRow(title: $0.key, miles: $0.value) }
      .sorted { $0.miles > $1.miles }
      .prefix(max(0, limit))
      .map { $0 }
  }

  private func vehicleName(for id: UUID?, vehicles: [NamedVehicle]) -> String {
    guard let id else { return "" }
    return vehicles.first(where: { $0.id == id })?.name ?? ""
  }

  private func routeLabel(_ trip: Trip) -> String {
    let start = trip.startLabel?.trimmingCharacters(in: .whitespacesAndNewlines)
    let end = trip.endLabel?.trimmingCharacters(in: .whitespacesAndNewlines)
    if let start, !start.isEmpty, let end, !end.isEmpty { return "\(start) → \(end)" }
    if let start, !start.isEmpty { return start }
    if let end, !end.isEmpty { return end }
    return "Trip"
  }

  private func milesText(_ miles: Double) -> String {
    DistanceFormatter.formatPrecise(miles)
  }

  private func formatRange(_ range: ExportDateRange) -> String {
    let start = min(range.start, range.end)
    let end = max(range.start, range.end)
    let df = DateFormatter()
    df.locale = Locale(identifier: "en_US_POSIX")
    df.dateFormat = "MMM d, yyyy"
    if calendar.isDate(start, inSameDayAs: end) {
      return df.string(from: start)
    }
    return "\(df.string(from: start)) – \(df.string(from: end))"
  }
}
