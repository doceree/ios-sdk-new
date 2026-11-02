import Foundation

/// Parses and normalizes decimal numbers to at most two fractional digits.
public enum DocereeDecimalPrecision {
    private static let scale = 100.0

    public static func roundToTwoDecimals(_ value: Double) -> Double {
        (value * scale).rounded() / scale
    }

    public static func roundToTwoDecimals(_ value: Float) -> Float {
        Float(roundToTwoDecimals(Double(value)))
    }

    /// Parses a decimal string and rounds to two fractional digits, or `nil` if not a number.
    public static func double(from string: String) -> Double? {
        let trimmed = string.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, let value = Double(trimmed) else { return nil }
        return roundToTwoDecimals(value)
    }

    /// Normalized decimal string with at most two fractional digits (for APIs that expect strings).
    public static func decimalString(from string: String) -> String? {
        guard let value = double(from: string) else { return nil }
        return formattedTwoDecimalString(value)
    }

    public static func formattedTwoDecimalString(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 2
        formatter.usesGroupingSeparator = false
        return formatter.string(from: NSNumber(value: value)) ?? String(value)
    }

    /// Recursively rounds `Double` / `Float` values in JSON-like trees (e.g. after `JSONSerialization`).
    public static func normalizeJSONObject(_ value: Any) -> Any {
        switch value {
        case let number as Double:
            return roundToTwoDecimals(number)
        case let number as Float:
            return roundToTwoDecimals(number)
        case let number as NSNumber:
            let doubleValue = number.doubleValue
            let intValue = number.intValue
            if doubleValue == Double(intValue), number.stringValue.range(of: ".") == nil {
                return intValue
            }
            return roundToTwoDecimals(doubleValue)
        case let dict as [String: Any]:
            var normalized: [String: Any] = [:]
            for (key, nested) in dict {
                normalized[key] = normalizeJSONObject(nested)
            }
            return normalized
        case let array as [Any]:
            return array.map { normalizeJSONObject($0) }
        default:
            return value
        }
    }
}
