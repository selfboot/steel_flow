import SwiftUI

private struct LocalizedNavigationTitle: ViewModifier {
    @Environment(\.locale) private var locale
    let key: String

    func body(content: Content) -> some View {
        // Navigation titles can cache a LocalizedStringKey across an in-app language change.
        // Resolve against the environment so the actual title value changes with the language.
        content.navigationTitle(Text(verbatim: AppLocalization.text(key, locale: locale)))
    }
}

extension View {
    func localizedNavigationTitle(_ key: String) -> some View {
        modifier(LocalizedNavigationTitle(key: key))
    }
}
