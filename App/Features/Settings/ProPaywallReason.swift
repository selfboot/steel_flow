import Foundation

enum ProPaywallReason: String, Identifiable {
    case general = "purchase.help"
    case projects = "purchase.limit.projects"
    case duplicate = "purchase.limit.duplicate"
    case bulkPricing = "purchase.limit.bulk_pricing"
    case items = "purchase.limit.items"
    case materials = "purchase.limit.materials"
    case csv = "purchase.limit.csv"
    case companyProfile = "purchase.limit.company_profile"
    case quoteBranding = "quote.pro.detail"
    case backups = "purchase.limit.backups"

    var id: String { rawValue }
    var emphasizesQuotes: Bool { self == .quoteBranding || self == .companyProfile || self == .csv }
    var benefits: [String] {
        switch self {
        case .quoteBranding, .companyProfile, .csv: ["quotes", "projects", "materials", "backups"]
        case .materials, .bulkPricing: ["materials", "projects", "quotes", "backups"]
        case .backups: ["backups", "projects", "quotes", "materials"]
        default: ["projects", "quotes", "materials", "backups"]
        }
    }
}
