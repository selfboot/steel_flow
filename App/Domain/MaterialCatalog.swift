import Foundation

struct MaterialPreset: Identifiable, Codable, Hashable, Sendable {
    let id: String
    let nameKey: String
    let densityKgPerM3: Double
    let noteKey: String
}

enum MaterialCatalog {
    static let presets: [MaterialPreset] = [
        .init(id: "carbon-steel", nameKey: "material.carbon_steel", densityKgPerM3: 7_850, noteKey: "material.note.typical"),
        .init(id: "stainless-304", nameKey: "material.stainless_304", densityKgPerM3: 7_930, noteKey: "material.note.typical"),
        .init(id: "stainless-316", nameKey: "material.stainless_316", densityKgPerM3: 8_000, noteKey: "material.note.typical"),
        .init(id: "aluminum", nameKey: "material.aluminum", densityKgPerM3: 2_700, noteKey: "material.note.typical"),
        .init(id: "brass", nameKey: "material.brass", densityKgPerM3: 8_500, noteKey: "material.note.typical"),
        .init(id: "copper", nameKey: "material.copper", densityKgPerM3: 8_960, noteKey: "material.note.typical"),
        .init(id: "cast-iron", nameKey: "material.cast_iron", densityKgPerM3: 7_200, noteKey: "material.note.typical")
    ]

    static func localizedName(materialID: String, fallback: String, locale: Locale) -> String {
        guard let preset = presets.first(where: { $0.id == materialID }) else { return fallback }
        return AppLocalization.text(preset.nameKey, locale: locale)
    }
}

enum AppLocalization {
    static var systemLocale: Locale {
        // Match the supported language preference list, while keeping the user's region.
        // For example, French followed by Japanese should use Japanese throughout the app.
        let language = AppLanguage.preferred(in: Locale.preferredLanguages).rawValue
        let region = Locale.autoupdatingCurrent.region.map { "_" + $0.identifier } ?? ""
        return Locale(identifier: language + region)
    }

    static var preferredLocale: Locale {
        let preference = UserDefaults.standard.string(forKey: "app.language") ?? "system"
        return AppLanguage(rawValue: preference).map { Locale(identifier: $0.rawValue) } ?? systemLocale
    }

    static func text(_ key: String) -> String {
        text(key, locale: preferredLocale)
    }

    static func text(_ key: String, locale: Locale) -> String {
        let language = AppLanguage.resolve(locale).rawValue
        for candidate in [language, "en"] {
            if let path = Bundle.main.path(forResource: candidate, ofType: "lproj"), let bundle = Bundle(path: path) {
                let value = bundle.localizedString(forKey: key, value: key, table: nil)
                if value != key { return value }
            }
        }
        return key
    }

    static func format(_ key: String, locale: Locale, _ arguments: CVarArg...) -> String {
        String(format: text(key, locale: locale), locale: locale, arguments: arguments)
    }

    static func count(_ key: String, value: Int, locale: Locale) -> String {
        let suffix = value == 1 ? "one" : "other"
        return format("\(key).\(suffix)", locale: locale, value)
    }
}
