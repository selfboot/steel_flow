import Foundation

/// The app UI and customer quotes share supported languages, but store independent choices.
enum AppLanguage: String, CaseIterable, Identifiable {
    case english = "en"
    case simplifiedChinese = "zh-Hans"
    case traditionalChinese = "zh-Hant"
    case japanese = "ja"
    case korean = "ko"
    case german = "de"
    case spanish = "es"
    case french = "fr"

    var id: String { rawValue }

    var nativeName: String {
        switch self {
        case .english: "English"
        case .simplifiedChinese: "简体中文"
        case .traditionalChinese: "繁體中文"
        case .japanese: "日本語"
        case .korean: "한국어"
        case .german: "Deutsch"
        case .spanish: "Español"
        case .french: "Français"
        }
    }

    static func resolve(_ locale: Locale) -> AppLanguage {
        switch locale.language.languageCode?.identifier {
        case "zh":
            // An explicit script takes precedence over the region (e.g. zh-Hans-TW).
            switch locale.language.script?.identifier {
            case "Hant": return .traditionalChinese
            case "Hans": return .simplifiedChinese
            default:
                return ["TW", "HK", "MO"].contains(locale.region?.identifier ?? "")
                    ? .traditionalChinese : .simplifiedChinese
            }
        case "ja": return .japanese
        case "ko": return .korean
        case "de": return .german
        case "es": return .spanish
        case "fr": return .french
        default: return .english
        }
    }

    static func preferred(in languages: [String]) -> AppLanguage {
        let match = Bundle.preferredLocalizations(from: allCases.map(\.rawValue), forPreferences: languages).first
        return match.flatMap(AppLanguage.init(rawValue:)) ?? .english
    }

    static func selected(_ preference: String, systemLocale: Locale) -> AppLanguage {
        AppLanguage(rawValue: preference) ?? resolve(systemLocale)
    }
}
