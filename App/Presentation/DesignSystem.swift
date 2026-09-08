import SwiftUI
import SwiftData
import Observation
import UIKit

enum SteelFlowTheme {
    static let steelBlue = Color(red: 0.04, green: 0.43, blue: 0.62)
    static let deepSteel = Color(red: 0.03, green: 0.20, blue: 0.27)
    static let surface = Color(uiColor: .secondarySystemGroupedBackground)
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
                .foregroundStyle(emphasized ? SteelFlowTheme.steelBlue : .primary)
                .minimumScaleFactor(0.72)
                .lineLimit(1)
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
        _text = State(initialValue: String(value.wrappedValue))
    }

    var body: some View {
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
        .onChange(of: text) { _, newValue in
            guard let parsed = Int(newValue), range.contains(parsed) else { return }
            value = parsed
        }
        .onChange(of: value) { _, newValue in
            guard !isFocused else { return }
            text = String(clamped(newValue))
        }
    }

    private func handleFocusChange(_ focused: Bool) {
        isFocused = focused
        guard !focused else { return }
        let normalized = clamped(Int(text) ?? value)
        value = normalized
        text = String(normalized)
    }

    private func clamped(_ value: Int) -> Int {
        min(max(value, range.lowerBound), range.upperBound)
    }
}

private struct CursorAtEndTextField: UIViewRepresentable {
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
        toolbar.items = [.flexibleSpace(), doneButton]
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
