import SwiftUI
import SwiftData
import Observation
import UIKit

enum SteelFlowTheme {
    static let steelBlue = Color(uiColor: UIColor { traits in
        traits.userInterfaceStyle == .dark ? UIColor(red: 0.24, green: 0.68, blue: 0.91, alpha: 1) : UIColor(red: 0.04, green: 0.43, blue: 0.62, alpha: 1)
    })
    /// Neutral steel tones for supporting iconography, distinct from action tint.
    static let steelGray = Color(uiColor: UIColor { traits in
        traits.userInterfaceStyle == .dark ? UIColor(red: 0.74, green: 0.76, blue: 0.78, alpha: 1) : UIColor(red: 0.38, green: 0.40, blue: 0.42, alpha: 1)
    })
    static let steelGraySurface = Color(uiColor: UIColor { traits in
        traits.userInterfaceStyle == .dark ? UIColor(red: 0.19, green: 0.20, blue: 0.21, alpha: 1) : UIColor(red: 0.93, green: 0.94, blue: 0.95, alpha: 1)
    })
    /// The graphite-blue of the app icon, with white symbols for crisp settings tiles.
    static let settingsIconFill = Color(uiColor: UIColor { traits in
        traits.userInterfaceStyle == .dark ? UIColor(red: 0.26, green: 0.36, blue: 0.43, alpha: 1) : UIColor(red: 0.28, green: 0.39, blue: 0.47, alpha: 1)
    })
    static let proGradient = LinearGradient(
        colors: [Color(red: 0.19, green: 0.29, blue: 0.37), Color(red: 0.07, green: 0.15, blue: 0.22)],
        startPoint: .topLeading, endPoint: .bottomTrailing
    )
    static let proHighlight = Color(red: 0.57, green: 0.82, blue: 0.98)
    static let actionFill = Color(red: 0.04, green: 0.43, blue: 0.62)
    static let deepSteel = Color(red: 0.03, green: 0.20, blue: 0.27)
    static let surface = Color(uiColor: .secondarySystemGroupedBackground)
}

/// A restrained highlight on symbol silhouettes; inherited tint keeps warning and disabled roles intact.
struct SteelSymbolFinish: ViewModifier {
    @Environment(\.isEnabled) private var isEnabled
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency

    func body(content: Content) -> some View {
        content.overlay {
            if isEnabled && !reduceTransparency {
                EllipticalGradient(
                    stops: [.init(color: .white.opacity(0.34), location: 0),
                            .init(color: .white.opacity(0.12), location: 0.35),
                            .init(color: .clear, location: 0.65),
                            .init(color: .black.opacity(0.12), location: 1)],
                    center: .center, startRadiusFraction: 0, endRadiusFraction: 0.7
                )
                .mask(content)
                .allowsHitTesting(false)
                .accessibilityHidden(true)
            }
        }
    }
}

struct PolishedSymbol: View {
    let systemName: String
    var body: some View {
        Image(systemName: systemName).modifier(SteelSymbolFinish())
    }
}

struct SteelLabelStyle: LabelStyle {
    func makeBody(configuration: Configuration) -> some View {
        Label { configuration.title } icon: {
            configuration.icon.modifier(SteelSymbolFinish())
        }
    }
}

/// Steel-colored glass tiles used by settings and Pro benefits.
struct SteelIconTile: View {
    let systemName: String
    var size: CGFloat = 32
    var base: Color = SteelFlowTheme.settingsIconFill
    var foreground: Color = .white
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: size * 0.27, style: .continuous)
        PolishedSymbol(systemName: systemName)
            .font(.system(size: size * 0.48, weight: .semibold))
            .foregroundStyle(foreground)
            .shadow(color: .black.opacity(0.16), radius: 0.5, y: 0.5)
            .frame(width: size, height: size)
            .background {
                shape.fill(base)
                    .overlay {
                        if !reduceTransparency {
                            shape.fill(RadialGradient(
                                stops: [.init(color: .white.opacity(0.46), location: 0),
                                        .init(color: .white.opacity(0.25), location: 0.3),
                                        .init(color: .white.opacity(0.04), location: 0.63),
                                        .init(color: .black.opacity(0.23), location: 1)],
                                center: .center, startRadius: 0, endRadius: size * 0.7
                            ))
                        }
                    }
                    .overlay {
                        shape.strokeBorder(.white.opacity(0.28), lineWidth: 0.75)
                    }
                    .shadow(color: base.opacity(0.24), radius: 1.5, y: 1.5)
            }
            .accessibilityHidden(true)
    }
}

/// Keep the existing cutout artwork, with a small specular lift and contact shadow.
struct ProfileMaterialIcon: View {
    let profile: ProfileKind
    var width: CGFloat = 48
    var height: CGFloat = 48
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency

    private var artwork: some View {
        Image("ProfileMaterial-\(profile.rawValue)")
            .resizable().scaledToFit()
            .frame(width: width, height: height)
    }

    var body: some View {
        artwork
            .overlay {
                if !reduceTransparency {
                    EllipticalGradient(
                        stops: [.init(color: .white.opacity(colorScheme == .dark ? 0.30 : 0.22), location: 0),
                                .init(color: .white.opacity(0.06), location: 0.48),
                                .init(color: .clear, location: 0.72),
                                .init(color: .black.opacity(0.08), location: 1)],
                        center: .center, startRadiusFraction: 0, endRadiusFraction: 0.7
                    )
                    .mask(artwork)
                }
            }
            .shadow(color: .black.opacity(colorScheme == .dark ? 0.20 : 0.12), radius: 0.8, y: 1)
            .accessibilityHidden(true)
    }
}

/// UIKit tab bars retain original-rendered SF Symbols, including their steel highlights.
@MainActor enum SteelTabImage {
    private static var cache: [String: UIImage] = [:]

    static func image(_ name: String, selected: Bool, dark: Bool) -> UIImage {
        let key = "\(name)-\(selected)-\(dark)"
        if let image = cache[key] { return image }
        let config = UIImage.SymbolConfiguration(pointSize: 24, weight: .medium)
        guard let symbol = UIImage(systemName: name, withConfiguration: config) else { return UIImage() }
        let colors: [UIColor]
        if selected {
            colors = [UIColor(red: 0.36, green: 0.76, blue: 0.94, alpha: 1),
                      UIColor(red: 0.10, green: 0.51, blue: 0.70, alpha: 1),
                      UIColor(red: 0.03, green: 0.34, blue: 0.51, alpha: 1)]
        } else if dark {
            colors = [UIColor(white: 0.91, alpha: 1), UIColor(white: 0.69, alpha: 1), UIColor(white: 0.48, alpha: 1)]
        } else {
            colors = [UIColor(red: 0.54, green: 0.62, blue: 0.68, alpha: 1),
                      UIColor(red: 0.32, green: 0.41, blue: 0.47, alpha: 1),
                      UIColor(red: 0.18, green: 0.25, blue: 0.31, alpha: 1)]
        }
        let format = UIGraphicsImageRendererFormat()
        format.scale = 3
        let image = UIGraphicsImageRenderer(size: symbol.size, format: format).image { renderer in
            symbol.withTintColor(.black, renderingMode: .alwaysOriginal).draw(at: .zero)
            let context = renderer.cgContext
            context.setBlendMode(.sourceAtop)
            let center = CGPoint(x: symbol.size.width / 2, y: symbol.size.height / 2)
            let radius = max(symbol.size.width, symbol.size.height) * 0.65
            if let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: colors.map(\.cgColor) as CFArray, locations: [0, 0.48, 1]) {
                context.drawRadialGradient(gradient, startCenter: center, startRadius: 0,
                                           endCenter: center, endRadius: radius,
                                           options: [.drawsAfterEndLocation])
            }
            let reflection = [UIColor(white: 1, alpha: 0.30), UIColor(white: 1, alpha: 0.08), UIColor(white: 1, alpha: 0)]
            if let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: reflection.map(\.cgColor) as CFArray, locations: [0, 0.45, 1]) {
                context.drawRadialGradient(gradient, startCenter: center, startRadius: 0,
                                           endCenter: center, endRadius: radius,
                                           options: [.drawsAfterEndLocation])
            }
        }.withRenderingMode(.alwaysOriginal)
        cache[key] = image
        return image
    }
}

/// Shared navigation and content spacing for the four root tabs.
struct RootTabLayout: ViewModifier {
    func body(content: Content) -> some View {
        content
            .navigationBarTitleDisplayMode(.inline)
            .contentMargins(.top, 8, for: .scrollContent)
    }
}

struct PrimaryActionStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.body.weight(.semibold))
            .foregroundStyle(isEnabled ? Color.white : Color(uiColor: .secondaryLabel))
            .padding(.horizontal, 16).padding(.vertical, 12)
            .frame(minHeight: 48)
            .background(isEnabled ? SteelFlowTheme.actionFill : Color(uiColor: .tertiarySystemFill), in: RoundedRectangle(cornerRadius: 14))
            .opacity(configuration.isPressed && isEnabled ? 0.8 : 1)
    }
}

struct ResultMetric: View {
    let title: LocalizedStringResource
    let value: String
    let emphasized: Bool

    init(_ title: LocalizedStringResource, value: String, emphasized: Bool = false) {
        self.title = title
        self.value = value
        self.emphasized = emphasized
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title).font(.caption).foregroundStyle(.secondary)
            Text(value)
                .font(emphasized ? .title2.bold() : .headline)
                .foregroundStyle(.primary)
                .monospacedDigit()
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(SteelFlowTheme.surface, in: RoundedRectangle(cornerRadius: 14))
    }
}

struct AdaptiveFormRow<Content: View>: View {
    let title: LocalizedStringResource
    @ViewBuilder let content: () -> Content
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    init(_ title: LocalizedStringResource, @ViewBuilder content: @escaping () -> Content) {
        self.title = title
        self.content = content
    }

    var body: some View {
        if dynamicTypeSize.isAccessibilitySize {
            VStack(alignment: .leading, spacing: 8) {
                Text(title)
                HStack(spacing: 8) { content() }
            }
        } else {
            HStack(spacing: 8) {
                Text(title)
                Spacer(minLength: 12)
                content()
            }
        }
    }
}

struct LengthValueInput: View {
    @Binding var text: String
    @State private var isFocused = false
    @Environment(\.locale) private var locale

    var body: some View {
        CursorAtEndTextField(
            text: $text,
            keyboardType: .decimalPad,
            accessibilityIdentifier: "length.value",
            doneTitle: AppLocalization.text("common.done", locale: locale),
            onFocusChange: { isFocused = $0 }
        )
        .padding(.horizontal, 12)
        .frame(minWidth: 112, maxWidth: .infinity, minHeight: 44)
        .background(Color(uiColor: .tertiarySystemFill), in: RoundedRectangle(cornerRadius: 10))
        .overlay {
            RoundedRectangle(cornerRadius: 10)
                .stroke(isFocused ? SteelFlowTheme.steelBlue : .clear, lineWidth: 2)
        }
        .contentShape(Rectangle())
        .accessibilityLabel("calculator.length")
    }
}

struct QuantityValueInput: View {
    @Binding var value: Int
    let range: ClosedRange<Int>
    @State private var text: String
    @State private var isFocused = false
    @Environment(\.locale) private var locale

    init(value: Binding<Int>, range: ClosedRange<Int>) {
        _value = value
        self.range = range
        _text = State(initialValue: value.wrappedValue == Int.min ? "" : String(value.wrappedValue))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
        CursorAtEndTextField(
            text: $text,
            keyboardType: .numberPad,
            accessibilityIdentifier: "quantity.value",
            doneTitle: AppLocalization.text("common.done", locale: locale),
            onFocusChange: handleFocusChange
        )
        .padding(.horizontal, 12)
        .frame(minWidth: 112, maxWidth: 160, minHeight: 44)
        .background(Color(uiColor: .tertiarySystemFill), in: RoundedRectangle(cornerRadius: 10))
        .overlay {
            RoundedRectangle(cornerRadius: 10)
                .stroke(isFocused ? SteelFlowTheme.steelBlue : .clear, lineWidth: 2)
        }
        .contentShape(Rectangle())
        .accessibilityLabel("calculator.quantity")
        if !range.contains(value) { InlineIssue(key: "ui.quantity_range") }
        }
        .onChange(of: text) { _, newValue in
            value = Int(newValue) ?? Int.min
        }
        .onChange(of: value) { _, newValue in
            guard !isFocused else { return }
            text = newValue == Int.min ? text : String(newValue)
        }
    }

    private func handleFocusChange(_ focused: Bool) {
        isFocused = focused
        guard !focused else { return }
        // Retain invalid input so the user can correct it; never silently clamp it.
        value = Int(text) ?? Int.min
    }


}

private struct CursorAtEndTextField: UIViewRepresentable {
    @Environment(\.locale) private var locale
    @Binding var text: String
    let keyboardType: UIKeyboardType
    let accessibilityIdentifier: String
    let doneTitle: String
    let onFocusChange: (Bool) -> Void

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    func makeUIView(context: Context) -> UITextField {
        let textField = UITextField()
        textField.delegate = context.coordinator
        textField.keyboardType = keyboardType
        textField.textAlignment = .right
        textField.font = .monospacedDigitSystemFont(ofSize: UIFont.preferredFont(forTextStyle: .body).pointSize, weight: .regular)
        textField.adjustsFontForContentSizeCategory = true
        textField.accessibilityIdentifier = accessibilityIdentifier
        let toolbar = UIToolbar()
        let doneButton = UIBarButtonItem(title: doneTitle, style: .done, target: context.coordinator, action: #selector(Coordinator.finishEditing))
        toolbar.items = [
            UIBarButtonItem(title: AppLocalization.text("ui.previous", locale: locale), style: .plain, target: context.coordinator, action: #selector(Coordinator.previousInput)),
            UIBarButtonItem(title: AppLocalization.text("ui.next", locale: locale), style: .plain, target: context.coordinator, action: #selector(Coordinator.nextInput)),
            .flexibleSpace(), doneButton]
        toolbar.sizeToFit()
        textField.inputAccessoryView = toolbar
        context.coordinator.textField = textField
        context.coordinator.doneButton = doneButton
        textField.addTarget(context.coordinator, action: #selector(Coordinator.textChanged(_:)), for: .editingChanged)
        return textField
    }

    func updateUIView(_ textField: UITextField, context: Context) {
        context.coordinator.parent = self
        textField.keyboardType = keyboardType
        textField.accessibilityIdentifier = accessibilityIdentifier
        context.coordinator.doneButton?.title = doneTitle
        if let toolbar = textField.inputAccessoryView as? UIToolbar {
            toolbar.items?.first?.title = AppLocalization.text("ui.previous", locale: locale)
            toolbar.items?.dropFirst().first?.title = AppLocalization.text("ui.next", locale: locale)
        }
        if textField.text != text { textField.text = text }
    }

    final class Coordinator: NSObject, UITextFieldDelegate {
        var parent: CursorAtEndTextField
        weak var textField: UITextField?
        weak var doneButton: UIBarButtonItem?

        init(_ parent: CursorAtEndTextField) {
            self.parent = parent
        }

        @objc func textChanged(_ textField: UITextField) {
            parent.text = textField.text ?? ""
        }

        @objc func previousInput() { InputNavigation.move(-1) }
        @objc func nextInput() { InputNavigation.move(1) }

        @objc func finishEditing() {
            textField?.resignFirstResponder()
        }

        func textFieldDidBeginEditing(_ textField: UITextField) {
            parent.onFocusChange(true)
            Task { @MainActor [weak textField] in
                await Task.yield()
                guard let textField else { return }
                let end = textField.endOfDocument
                textField.selectedTextRange = textField.textRange(from: end, to: end)
            }
        }

        func textFieldDidEndEditing(_ textField: UITextField) {
            parent.onFocusChange(false)
        }
    }
}

@MainActor
@Observable
final class PersistenceErrorCenter {
    static let shared = PersistenceErrorCenter()
    var message: String?

    @discardableResult
    func perform(_ operation: () throws -> Void) -> Bool {
        do {
            try operation()
            message = nil
            return true
        } catch {
            message = error.localizedDescription
            return false
        }
    }

    @discardableResult
    func save(_ context: ModelContext) -> Bool {
        let succeeded = perform { try context.save() }
        if !succeeded { context.rollback() }
        return succeeded
    }
}
