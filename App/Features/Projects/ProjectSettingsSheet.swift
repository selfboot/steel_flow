import SwiftUI
import SwiftData

struct ProjectSettingsSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(\.locale) private var locale
    @Bindable var project: ProjectEntity
    @State private var currencyDraft = ""
    @State private var taxDraft = ""
    @State private var profitDraft = ""
    @State private var profitMode = ProfitMode.markup
    @State private var showCurrencyChange = false

    private var normalizedCurrency: String? { CurrencyRules.normalizedCode(currencyDraft) }
    private var validTax: Decimal? { PricingInputValidator.percentage(taxDraft, locale: locale) }
    private var validProfit: Decimal? { PricingInputValidator.percentage(profitDraft, mode: profitMode, locale: locale) }
    private var canSave: Bool { normalizedCurrency != nil && validTax != nil && validProfit != nil }

    var body: some View {
        NavigationStack {
            Form {
                Section("project.details") {
                    TextField("project.name", text: $project.name)
                    TextField("project.number", text: $project.projectNumber)
                    TextField("project.customer", text: $project.customerName)
                    Picker("project.quote_language", selection: $project.quoteLanguage) {
                        Text("language.english").tag("en")
                        Text("language.chinese").tag("zh-Hans")
                    }
                    TextField("settings.currency", text: $currencyDraft).textInputAutocapitalization(.characters)
                    Picker("settings.paper", selection: Binding(get: { project.paperSize }, set: { project.paperSize = $0 })) {
                        Text("paper.a4").tag(PaperSize.a4)
                        Text("paper.letter").tag(PaperSize.letter)
                    }
                }
                Section("project.pricing") {
                    Picker("project.profit_mode", selection: $profitMode) { ForEach(ProfitMode.allCases) { Text($0.localizationKey).tag($0) } }
                    HStack { Text(profitMode == .markup ? "project.markup_percent" : "project.margin_percent"); Spacer(); TextField("0", text: $profitDraft).keyboardType(.decimalPad).multilineTextAlignment(.trailing); Text("%") }
                    HStack { Text("project.tax_percent"); Spacer(); TextField("0", text: $taxDraft).keyboardType(.decimalPad).multilineTextAlignment(.trailing); Text("%") }
                    Stepper(value: $project.validDays, in: 1...365) { LabeledContent("project.valid_days", value: "\(project.validDays)") }
                    if validProfit == nil || validTax == nil { Label("error.invalid_pricing_policy", systemImage: "exclamationmark.triangle.fill").foregroundStyle(.red) }
                }
                Section("project.terms") {
                    TextField("project.terms", text: $project.terms, axis: .vertical).lineLimit(3...8)
                    TextField("project.notes", text: $project.notes, axis: .vertical).lineLimit(3...8)
                }
            }
            .navigationTitle("project.edit")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("common.done") {
                        save()
                    }
                    .disabled(!canSave)
                }
            }
            .onAppear {
                currencyDraft = project.currencyCode
                taxDraft = project.taxPercentText
                profitDraft = project.markupPercentText
                profitMode = project.profitMode
            }
            .sheet(isPresented: $showCurrencyChange) {
                if let newCurrency = normalizedCurrency {
                    CurrencyChangeSheet(oldCurrency: project.currencyCode, newCurrency: newCurrency) { mode, rate in
                        applyCurrencyChange(mode: mode, rate: rate, newCurrency: newCurrency)
                        finishSave()
                    }
                }
            }
        }
    }

    private func save() {
        guard let newCurrency = normalizedCurrency, validTax != nil, validProfit != nil else { return }
        if newCurrency != project.currencyCode { showCurrencyChange = true }
        else { finishSave() }
    }

    private func finishSave() {
        guard let tax = validTax, let profit = validProfit else { return }
        project.taxPercentText = tax.description
        project.markupPercentText = profit.description
        project.profitMode = profitMode
        project.updatedAt = .now
        try? modelContext.save()
        dismiss()
    }

    private func applyCurrencyChange(mode: CurrencyChangeMode, rate: Decimal?, newCurrency: String) {
        _ = CurrencyMigration.apply(to: project, newCurrency: newCurrency, mode: mode, rate: rate)
    }
}

private struct CurrencyChangeSheet: View {
    @Environment(\.dismiss) private var dismiss
    let oldCurrency: String
    let newCurrency: String
    let apply: (CurrencyChangeMode, Decimal?) -> Void
    @State private var mode = CurrencyChangeMode.clearAmounts
    @State private var rateText = ""

    private var rate: Decimal? {
        guard let value = PricingInputValidator.nonnegative(rateText), value > 0 else { return nil }
        return value
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    LabeledContent("currency_change.from", value: oldCurrency)
                    LabeledContent("currency_change.to", value: newCurrency)
                }
                Section("currency_change.action") {
                    Picker("currency_change.action", selection: $mode) {
                        ForEach(CurrencyChangeMode.allCases) { Text($0.localizationKey).tag($0) }
                    }
                    .pickerStyle(.inline)
                    if mode == .convert {
                        HStack {
                            Text("currency_change.rate")
                            Spacer()
                            TextField("1", text: $rateText).keyboardType(.decimalPad).multilineTextAlignment(.trailing)
                            Text(newCurrency).foregroundStyle(.secondary)
                        }
                    }
                    Text(mode == .keepAmounts ? "currency_change.keep_warning" : mode == .convert ? "currency_change.convert_help" : "currency_change.clear_help")
                        .font(.caption).foregroundStyle(.secondary)
                }
            }
            .navigationTitle("currency_change.title")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("common.cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("common.apply") { apply(mode, mode == .convert ? rate : nil); dismiss() }
                        .disabled(mode == .convert && rate == nil)
                }
            }
        }
    }
}
