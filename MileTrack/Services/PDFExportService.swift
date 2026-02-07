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
    filename: String
  ) throws -> URL {
    let data = makeSummaryPDFData(
      trips: trips,
      range: range,
      includeClientBreakdown: includeClientBreakdown
    )

    let sanitized = filename.replacingOccurrences(of: "/", with: "-")
    let url = FileManager.default.temporaryDirectory
      .appendingPathComponent(sanitized)
      .appendingPathExtension("pdf")

    try data.write(to: url, options: [.atomic])
    return url
  }

  // MARK: - Rendering

  private func makeSummaryPDFData(
    trips: [Trip],
    range: ExportDateRange,
    includeClientBreakdown: Bool
  ) -> Data {
    let pageRect = CGRect(x: 0, y: 0, width: 612, height: 792) // US Letter @ 72dpi
    let renderer = UIGraphicsPDFRenderer(bounds: pageRect)

    let rangeText = formatRange(range)
    let totalMiles = trips.reduce(0) { $0 + $1.distanceMiles }

    let byCategory = topRows(
      trips: trips,
      key: { ($0.category ?? "").trimmingCharacters(in: .whitespacesAndNewlines) },
      emptyFallback: "Uncategorized",
      limit: 5
    )

    let byClient: [PDFSummarySectionRow] = includeClientBreakdown
      ? topRows(
        trips: trips,
        key: { ($0.clientOrOrg ?? "").trimmingCharacters(in: .whitespacesAndNewlines) },
        emptyFallback: "No client",
        limit: 5
      )
      : []

    return renderer.pdfData { ctx in
      ctx.beginPage()

      let margin: CGFloat = 48
      var cursorY = margin
      let contentWidth = pageRect.width - (margin * 2)

      // Title
      cursorY += drawText(
        "MileTrack",
        in: CGRect(x: margin, y: cursorY, width: contentWidth, height: 40),
        font: .systemFont(ofSize: 22, weight: .bold),
        color: .black
      )
      cursorY += 4

      // Subtitle
      cursorY += drawText(
        "Summary • \(rangeText)",
        in: CGRect(x: margin, y: cursorY, width: contentWidth, height: 30),
        font: .systemFont(ofSize: 12, weight: .semibold),
        color: UIColor.black.withAlphaComponent(0.70)
      )
      cursorY += 14

      // Total miles
      cursorY += drawSectionHeader("Total miles", x: margin, y: cursorY, width: contentWidth)
      cursorY += 6
      cursorY += drawText(
        milesText(totalMiles),
        in: CGRect(x: margin, y: cursorY, width: contentWidth, height: 28),
        font: .systemFont(ofSize: 18, weight: .bold),
        color: .black
      )
      cursorY += 18

      // Miles by category
      cursorY += drawSectionHeader("Miles by category (top 5)", x: margin, y: cursorY, width: contentWidth)
      cursorY += 8
      cursorY = drawRows(byCategory, x: margin, y: cursorY, width: contentWidth)
      cursorY += 18

      // Optional: Miles by client
      if includeClientBreakdown {
        cursorY += drawSectionHeader("Miles by client (top 5)", x: margin, y: cursorY, width: contentWidth)
        cursorY += 8
        cursorY = drawRows(byClient, x: margin, y: cursorY, width: contentWidth)
        cursorY += 18
      }

      // Footer
      let footer = "Generated \(Date().formatted(date: .abbreviated, time: .shortened))"
      _ = drawText(
        footer,
        in: CGRect(x: margin, y: pageRect.height - margin - 16, width: contentWidth, height: 16),
        font: .systemFont(ofSize: 10, weight: .regular),
        color: UIColor.black.withAlphaComponent(0.55)
      )
    }
  }

  private func drawSectionHeader(_ title: String, x: CGFloat, y: CGFloat, width: CGFloat) -> CGFloat {
    let h = drawText(
      title,
      in: CGRect(x: x, y: y, width: width, height: 18),
      font: .systemFont(ofSize: 12, weight: .semibold),
      color: UIColor.black.withAlphaComponent(0.75)
    )

    // Hairline separator.
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
      let titleRect = CGRect(x: x, y: cursorY, width: titleWidth, height: 16)
      let valueRect = CGRect(x: x + titleWidth, y: cursorY, width: valueWidth, height: 16)

      _ = drawText(
        row.title,
        in: titleRect,
        font: .systemFont(ofSize: 11, weight: .regular),
        color: UIColor.black.withAlphaComponent(0.85)
      )

      _ = drawText(
        milesText(row.miles),
        in: valueRect,
        font: .systemFont(ofSize: 11, weight: .semibold),
        color: UIColor.black.withAlphaComponent(0.85),
        alignment: .right
      )

      cursorY += 18
    }

    return cursorY
  }

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

  // MARK: - Helpers

  private func topRows(
    trips: [Trip],
    key: (Trip) -> String,
    emptyFallback: String,
    limit: Int
  ) -> [PDFSummarySectionRow] {
    var totals: [String: Double] = [:]
    for trip in trips where trip.state == .confirmed {
      let raw = key(trip)
      let name = raw.isEmpty ? emptyFallback : raw
      totals[name, default: 0] += trip.distanceMiles
    }

    let rows = totals
      .map { PDFSummarySectionRow(title: $0.key, miles: $0.value) }
      .sorted { $0.miles > $1.miles }

    return Array(rows.prefix(max(0, limit)))
  }

  private func milesText(_ miles: Double) -> String {
    let formatter = NumberFormatter()
    formatter.locale = Locale(identifier: "en_US_POSIX")
    formatter.numberStyle = .decimal
    formatter.minimumFractionDigits = 2
    formatter.maximumFractionDigits = 2
    let text = formatter.string(from: NSNumber(value: miles)) ?? "\(miles)"
    return "\(text) mi"
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

