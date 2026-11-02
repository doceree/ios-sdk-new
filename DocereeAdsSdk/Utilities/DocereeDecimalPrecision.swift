import CoreGraphics
import Foundation

/// SDK-wide rule: every **Double**, **Float**, **CGFloat**, and **NSNumber** (non-boolean) in JSON-like trees,
/// plus **decimal strings** (e.g. `"59.432…"`), use at most **two** fractional digits and serialize without IEEE-754 noise.
/// Use `jsonData(withJSONObject:)` / `jsonObject(with:)` for encoding and decoding; persisted attributes are normalized in `StorageManager`.
public enum DocereeDecimalPrecision {
    public enum JSONError: Error {
        case invalidJSONObject
    }
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

    /// Value suitable for `JSONSerialization` — at most two fractional digits without IEEE-754 noise (e.g. `98.6` not `98.599999999999994`).
    public static func jsonNormalizedNumber(from value: Double) -> Any {
        var decimal = Decimal(value)
        var rounded = Decimal()
        NSDecimalRound(&rounded, &decimal, 2, .plain)
        let scaled = NSDecimalNumber(decimal: rounded)
        if scaled.doubleValue == Double(scaled.intValue) {
            return scaled.intValue
        }
        let formatted = formattedTwoDecimalString(scaled.doubleValue)
        return NSDecimalNumber(string: formatted)
    }

    /// Recursively normalizes numeric values in JSON-like trees (numbers and decimal strings such as `age`).
    public static func normalizeJSONObject(_ value: Any) -> Any {
        switch value {
        case let number as Double:
            return jsonNormalizedNumber(from: number)
        case let number as Float:
            return jsonNormalizedNumber(from: Double(number))
        case let number as CGFloat:
            return jsonNormalizedNumber(from: Double(number))
        case let number as Decimal:
            return jsonNormalizedNumber(from: NSDecimalNumber(decimal: number).doubleValue)
        case let number as NSNumber:
            if CFGetTypeID(number) == CFBooleanGetTypeID() {
                return number
            }
            return jsonNormalizedNumber(from: number.doubleValue)
        case let string as String:
            if let normalized = normalizedDecimalStringIfNeeded(string) {
                return normalized
            }
            return string
        case let dict as [String: Any]:
            var normalized: [String: Any] = [:]
            normalized.reserveCapacity(dict.count)
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

    /// Normalizes a single value (same rules as `normalizeJSONObject`).
    public static func normalizeJSONValue(_ value: Any) -> Any {
        normalizeJSONObject(value)
    }

    /// Normalizes string fields that hold decimal numbers (e.g. `"ag": "59.4324324332423"`) without touching integer-only strings like `"59"` or `"004336"`.
    private static func normalizedDecimalStringIfNeeded(_ string: String) -> String? {
        let trimmed = string.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.contains("."), let value = double(from: trimmed) else { return nil }
        return formattedTwoDecimalString(value)
    }

    /// Serializes a JSON object after normalizing all numbers in the tree (quest, intake, config, beacons, etc.).
    public static func jsonData(withJSONObject object: Any, options: JSONSerialization.WritingOptions = []) throws -> Data {
        let normalized = normalizeJSONObject(object)
        guard JSONSerialization.isValidJSONObject(normalized) else {
            throw JSONError.invalidJSONObject
        }
        return try JSONSerialization.data(withJSONObject: normalized, options: options)
    }

    /// Parses JSON and normalizes numeric values (two decimals, stable wire form).
    public static func jsonObject(with data: Data, options: JSONSerialization.ReadingOptions = []) throws -> Any {
        let raw = try JSONSerialization.jsonObject(with: data, options: options)
        return normalizeJSONObject(raw)
    }
}
