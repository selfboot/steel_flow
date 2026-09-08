import SwiftUI
import UIKit

struct LabeledEntry: View {
    let title: LocalizedStringResource
    @Binding var text: String
    var keyboard: UIKeyboardType = .default
    var multiline = false
    init(_ title: LocalizedStringResource, text: Binding<String>, keyboard: UIKeyboardType = .default, multiline: Bool = false) {
        self.title = title; self._text = text; self.keyboard = keyboard; self.multiline = multiline
    }
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title).font(.caption).foregroundStyle(.secondary)
            TextField(title, text: $text, axis: multiline ? .vertical : .horizontal)
                .keyboardType(keyboard)
                .textInputAutocapitalization(keyboard == .emailAddress ? .never : .sentences)
                .frame(minHeight: 44)
                .accessibilityLabel(Text(title))
        }
    }
}

struct InlineIssue: View {
    let key: String
    var body: some View {
        Label(LocalizedStringKey(key), systemImage: "exclamationmark.circle.fill")
            .font(.caption).foregroundStyle(.red).fixedSize(horizontal: false, vertical: true)
            .accessibilityAddTraits(.isStaticText)
    }
}

struct StatusNotice: View {
    let text: String
    var actionTitle: LocalizedStringResource = "common.done"
    var action: (() -> Void)? = nil
    var body: some View {
        ViewThatFits(in: .horizontal) {
            HStack { Label(text, systemImage: "checkmark.circle"); Spacer(); actionButton }
            VStack(alignment: .leading) { Label(text, systemImage: "checkmark.circle"); actionButton }
        }
        .font(.subheadline).padding(12)
        .background(Color.accentColor.opacity(0.09), in: RoundedRectangle(cornerRadius: 12))
        .accessibilityElement(children: .contain)
    }
    @ViewBuilder private var actionButton: some View {
        if let action { Button(actionTitle, action: action).frame(minHeight: 44) }
    }
}

struct PressableCardStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label.opacity(configuration.isPressed ? 0.65 : 1)
            .background(configuration.isPressed ? Color.primary.opacity(0.05) : .clear)
    }
}

@MainActor enum InputNavigation {
    static func focus(_ identifier: String) {
        func find(_ view: UIView) -> UIView? {
            if view.accessibilityIdentifier == identifier && (view is UITextField || view is UITextView) { return view }
            return view.subviews.lazy.compactMap(find).first
        }
        let windows = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }.flatMap(\.windows)
        if let window = windows.first(where: \.isKeyWindow) { find(window)?.becomeFirstResponder() }
    }

    static func move(_ direction: Int) {
        guard let window = UIApplication.shared.connectedScenes.compactMap({ $0 as? UIWindowScene }).flatMap(\.windows).first(where: \.isKeyWindow) else { return }
        func fields(_ view: UIView) -> [UIView] {
            guard !view.isHidden, view.alpha > 0 else { return [] }
            if let field = view as? UITextField, field.isEnabled { return [field] }
            if let field = view as? UITextView, field.isEditable { return [field] }
            return view.subviews.flatMap(fields)
        }
        let inputs = fields(window).sorted { a, b in
            let ar = a.convert(a.bounds, to: window), br = b.convert(b.bounds, to: window)
            return abs(ar.minY - br.minY) > 5 ? ar.minY < br.minY : ar.minX < br.minX
        }
        guard let index = inputs.firstIndex(where: \.isFirstResponder), inputs.indices.contains(index + direction) else { return }
        let next = inputs[index + direction]
        next.becomeFirstResponder()
        var ancestor = next.superview
        while let view = ancestor {
            if let scroll = view as? UIScrollView { scroll.scrollRectToVisible(next.convert(next.bounds, to: scroll).insetBy(dx: 0, dy: -28), animated: true); break }
            ancestor = view.superview
        }
    }
}

struct ShareFile: Identifiable { let id = UUID(); let url: URL }
struct FileShareSheet: UIViewControllerRepresentable {
    let url: URL
    func makeUIViewController(context: Context) -> UIActivityViewController { UIActivityViewController(activityItems: [url], applicationActivities: nil) }
    func updateUIViewController(_ controller: UIActivityViewController, context: Context) {}
}
