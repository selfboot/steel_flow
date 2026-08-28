import Foundation

enum AppFormatters {
    static func number(_ value: Double, maximumFractionDigits: Int = 3, locale: Locale = .current) -> String {
        value.formatted(.number.locale(locale).precision(.fractionLength(0...maximumFractionDigits)))
    }

    static func decimal(_ value: Decimal, currencyCode: String, locale: Locale = .current) -> String {
        let number = NSDecimalNumber(decimal: value)
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = currencyCode
        formatter.locale = locale
        return formatter.string(from: number) ?? "\(currencyCode) \(value)"
    }

    static func date(_ value: Date, locale: Locale = .current) -> String {
        value.formatted(.dateTime.year().month().day().locale(locale))
    }
}

enum DecimalParser {
    static func parse(_ text: String, locale: Locale = .current) -> Decimal? {
        var normalized = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !normalized.isEmpty else { return nil }
        let formatter = NumberFormatter()
        formatter.locale = locale
        let decimalSeparator = formatter.decimalSeparator ?? "."
        let groupingSeparator = formatter.groupingSeparator ?? ","
        normalized = normalized.replacingOccurrences(of: "\u{00A0}", with: "")
        normalized = normalized.replacingOccurrences(of: "\u{202F}", with: "")
        normalized = normalized.replacingOccurrences(of: " ", with: "")
        if groupingSeparator != decimalSeparator {
            let unsigned = normalized.first.map { $0 == "+" || $0 == "-" } == true ? String(normalized.dropFirst()) : normalized
            let integerPart = unsigned.components(separatedBy: decimalSeparator).first ?? unsigned
            if integerPart.contains(groupingSeparator) {
                let groups = integerPart.components(separatedBy: groupingSeparator)
                guard let first = groups.first, (1...3).contains(first.count), groups.dropFirst().allSatisfy({ $0.count == 3 }) else { return nil }
            }
            normalized = normalized.replacingOccurrences(of: groupingSeparator, with: "")
        }
        if decimalSeparator != "." {
            normalized = normalized.replacingOccurrences(of: decimalSeparator, with: ".")
        }
        let pattern = "^[+-]?(?:[0-9]+(?:\\.[0-9]*)?|\\.[0-9]+)$"
        guard normalized.range(of: pattern, options: .regularExpression) != nil else { return nil }
        return Decimal(string: normalized, locale: Locale(identifier: "en_US_POSIX"))
    }

    static func double(_ text: String, locale: Locale = .current) -> Double? {
        parse(text, locale: locale).map { NSDecimalNumber(decimal: $0).doubleValue }
    }
}
