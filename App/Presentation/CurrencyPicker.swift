import Foundation
import SwiftUI

enum CurrencyCatalog {
    static let allCodes: [String] = Array(Set(Locale.commonISOCurrencyCodes)).sorted()

    static func localizedName(for code: String, locale: Locale) -> String {
        locale.localizedString(forCurrencyCode: code) ?? code
    }

    static func decodedRecent(_ value: String) -> [String] {
        var seen = Set<String>()
        return value
            .split(separator: ",")
            .compactMap { CurrencyRules.normalizedCode(String($0)) }
            .filter { seen.insert($0).inserted }
    }

    static func encodedRecent(_ codes: [String]) -> String {
        codes.joined(separator: ",")
    }

    static func updatedRecent(selecting code: String, existing: [String], limit: Int = 8) -> [String] {
        guard let normalized = CurrencyRules.normalizedCode(code), limit > 0 else { return Array(existing.prefix(max(0, limit))) }
        return Array(([normalized] + existing.filter { $0 != normalized }).prefix(limit))
    }

    static func sortedCodes(_ codes: [String], locale: Locale) -> [String] {
        codes.sorted { lhs, rhs in
            let lhsName = localizedName(for: lhs, locale: locale)
            let rhsName = localizedName(for: rhs, locale: locale)
            let result = lhsName.compare(
                rhsName,
                options: [.caseInsensitive, .diacriticInsensitive],
                range: nil,
                locale: locale
            )
            return result == .orderedSame ? lhs < rhs : result == .orderedAscending
        }
    }
}

struct CurrencyPickerRow: View {
    @Binding var selection: String
    @Environment(\.locale) private var locale

    var body: some View {
        NavigationLink {
            CurrencySelectionView(selection: $selection)
        } label: {
            HStack {
                Text("settings.currency")
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    Text(selection)
                    Text(CurrencyCatalog.localizedName(for: selection, locale: locale))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }
}

private struct CurrencySelectionView: View {
    @Binding var selection: String
    @Environment(\.dismiss) private var dismiss
    @Environment(\.locale) private var locale
    @AppStorage("app.recentCurrencies") private var storedRecentCodes = ""
    @State private var searchText = ""

    private var recentCodes: [String] {
        CurrencyCatalog.decodedRecent(storedRecentCodes)
    }

    private var remainingCodes: [String] {
        let recent = Set(recentCodes)
        return CurrencyCatalog.sortedCodes(CurrencyCatalog.allCodes.filter { !recent.contains($0) }, locale: locale)
    }

    var body: some View {
        List {
            Section {
                HStack(spacing: 10) {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(.secondary)

                    TextField("currency.selector.search", text: $searchText)
                        .textInputAutocapitalization(.characters)
                        .autocorrectionDisabled()
                        .submitLabel(.done)

                    if !searchText.isEmpty {
                        Button {
                            searchText = ""
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundStyle(.tertiary)
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("common.clear")
                    }
                }
            }

            let recentMatches = filtered(recentCodes)
            if !recentMatches.isEmpty {
                Section("currency.selector.recent") {
                    ForEach(recentMatches, id: \.self) { currencyButton(for: $0) }
                }
            }

            let allMatches = filtered(remainingCodes)
            if !allMatches.isEmpty {
                Section("currency.selector.all") {
                    ForEach(allMatches, id: \.self) { currencyButton(for: $0) }
                }
            }
        }
        .navigationTitle("currency.selector.title")
        .navigationBarTitleDisplayMode(.inline)
        .keyboardDismissSupport()
        .onAppear { record(selection) }
    }

    private func filtered(_ codes: [String]) -> [String] {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return codes }
        return codes.filter { code in
            code.localizedCaseInsensitiveContains(query) ||
                CurrencyCatalog.localizedName(for: code, locale: locale).localizedCaseInsensitiveContains(query)
        }
    }

    private func currencyButton(for code: String) -> some View {
        Button {
            selection = code
            record(code)
            dismiss()
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(CurrencyCatalog.localizedName(for: code, locale: locale))
                    Text(code).font(.caption).foregroundStyle(.secondary)
                }
                Spacer()
                if code == selection {
                    Image(systemName: "checkmark").foregroundStyle(Color.accentColor)
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private func record(_ code: String) {
        storedRecentCodes = CurrencyCatalog.encodedRecent(
            CurrencyCatalog.updatedRecent(selecting: code, existing: recentCodes)
        )
    }
}
