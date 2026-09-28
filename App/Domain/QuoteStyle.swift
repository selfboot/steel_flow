import Foundation

/// Raw values are persisted in projects, backups and immutable quote snapshots.
enum QuoteStyle: String, Codable, CaseIterable, Identifiable, Sendable {
    case classic, blue, forest, minimal, executive, modern, ledger
    var id: String { rawValue }
    var titleKey: String { "quote.style.\(rawValue)" }
    var detailKey: String { "quote.style.\(rawValue).detail" }
}
