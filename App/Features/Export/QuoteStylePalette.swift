import UIKit

/// Print colors are fixed, independent of the device's light/dark appearance.
struct QuoteStylePalette {
    let accent: UIColor
    let ink: UIColor
    let secondary = UIColor(white: 0.38, alpha: 1)
    let wash: UIColor
    let rule: UIColor

    init(_ style: QuoteStyle) {
        ink = style == .classic ? .black : style == .minimal ? UIColor(white: 0.13, alpha: 1) : UIColor(red: 0.10, green: 0.14, blue: 0.18, alpha: 1)
        switch style {
        case .classic:
            accent = .black; wash = UIColor(white: 0.9, alpha: 1)
        case .blue:
            accent = UIColor(red: 0.06, green: 0.32, blue: 0.57, alpha: 1)
            wash = UIColor(red: 0.94, green: 0.97, blue: 0.99, alpha: 1)
        case .forest:
            accent = UIColor(red: 0.09, green: 0.27, blue: 0.23, alpha: 1)
            wash = UIColor(red: 0.94, green: 0.97, blue: 0.95, alpha: 1)
        case .executive:
            accent = UIColor(red: 0.10, green: 0.17, blue: 0.29, alpha: 1); wash = .white
        case .modern:
            accent = UIColor(red: 0.02, green: 0.33, blue: 0.40, alpha: 1)
            wash = UIColor(red: 0.94, green: 0.97, blue: 0.98, alpha: 1)
        case .ledger:
            accent = UIColor(red: 0.22, green: 0.27, blue: 0.33, alpha: 1); wash = .white
        case .minimal:
            accent = UIColor(white: 0.13, alpha: 1); wash = UIColor(white: 0.97, alpha: 1)
        }
        rule = style == .ledger ? UIColor(white: 0.60, alpha: 1) : style == .minimal ? UIColor(white: 0.35, alpha: 1) : UIColor(white: 0.84, alpha: 1)
    }
}
