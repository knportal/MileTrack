import SwiftUI

/// Formats distances respecting the user's unit preference (miles vs kilometers).
/// Use this throughout the app for consistent distance display.
struct DistanceFormatter {
    /// Formats a distance value (stored internally as miles) for display.
    /// - Parameter miles: The distance in miles
    /// - Returns: A formatted string like "12.5 mi" or "20.1 km"
    static func format(_ miles: Double) -> String {
        let useMetric = UserDefaults.standard.bool(forKey: "useMetricUnits")
        if useMetric {
            let km = miles * 1.60934
            return String(format: "%.1f km", km)
        } else {
            return String(format: "%.1f mi", miles)
        }
    }
    
    /// Formats a distance with more precision (2 decimal places).
    /// - Parameter miles: The distance in miles
    /// - Returns: A formatted string like "12.50 mi" or "20.12 km"
    static func formatPrecise(_ miles: Double) -> String {
        let useMetric = UserDefaults.standard.bool(forKey: "useMetricUnits")
        if useMetric {
            let km = miles * 1.60934
            return String(format: "%.2f km", km)
        } else {
            return String(format: "%.2f mi", miles)
        }
    }
    
    /// Returns just the numeric value formatted for display (no unit suffix).
    /// - Parameter miles: The distance in miles
    /// - Returns: A formatted number string like "12.5" or "20.1"
    static func formatValue(_ miles: Double) -> String {
        let useMetric = UserDefaults.standard.bool(forKey: "useMetricUnits")
        if useMetric {
            let km = miles * 1.60934
            return String(format: "%.1f", km)
        } else {
            return String(format: "%.1f", miles)
        }
    }
    
    /// Returns just the numeric value with more precision (no unit suffix).
    /// - Parameter miles: The distance in miles
    /// - Returns: A formatted number string like "12.50" or "20.12"
    static func formatValuePrecise(_ miles: Double) -> String {
        let useMetric = UserDefaults.standard.bool(forKey: "useMetricUnits")
        if useMetric {
            let km = miles * 1.60934
            return String(format: "%.2f", km)
        } else {
            return String(format: "%.2f", miles)
        }
    }
    
    /// The unit label based on user preference.
    static var unitLabel: String {
        let useMetric = UserDefaults.standard.bool(forKey: "useMetricUnits")
        return useMetric ? "km" : "mi"
    }
    
    /// The full unit name based on user preference.
    static var unitName: String {
        let useMetric = UserDefaults.standard.bool(forKey: "useMetricUnits")
        return useMetric ? "kilometers" : "miles"
    }
    
    /// Converts user-entered distance (in display units) to miles for storage.
    /// - Parameter displayValue: The value entered by user in their preferred units
    /// - Returns: The value in miles
    static func toMiles(_ displayValue: Double) -> Double {
        let useMetric = UserDefaults.standard.bool(forKey: "useMetricUnits")
        if useMetric {
            return displayValue / 1.60934
        } else {
            return displayValue
        }
    }
    
    /// Converts stored miles to display units.
    /// - Parameter miles: The distance in miles
    /// - Returns: The value in user's preferred units
    static func toDisplayUnits(_ miles: Double) -> Double {
        let useMetric = UserDefaults.standard.bool(forKey: "useMetricUnits")
        if useMetric {
            return miles * 1.60934
        } else {
            return miles
        }
    }
}
