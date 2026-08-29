import SwiftUI
import SwiftData

struct ProjectSettingsSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(\.locale) private var locale
    let project: ProjectEntity
    @State private var name = ""
    @State private var projectNumber = ""
    @State private var customerName = ""
    @State private var quoteLanguage = "en"
    @State private var unitSystem = UnitSystem.metric
    @State private var paperSize = PaperSize.a4
    @State private var validDays = 30
    @State private var terms = ""
    @State private var notes = ""
    @State private var currencyDraft = ""
    @State private var taxDraft = ""
    @State private var profitDraft = ""
    @State private var profitMode = ProfitMode.markup
    @State private var showCurrencyChange = false
    @State private var showCurrencyError = false
    @State private var paywallReason: ProPaywallReason?
    @State private var purchaseManager = PurchaseManager.shared

    private var normalizedCurrency: String? { CurrencyRules.normalizedCode(currencyDraft) }
    private var validTax: Decimal? { PricingInputValidator.percentage(taxDraft, locale: locale) }
    private var validProfit: Decimal? { PricingInputValidator.percentage(profitDraft, mode: profitMode, locale: locale) }
    private var canSave: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !projectNumber.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        normalizedCurrency != nil && validTax != nil && validProfit != nil
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("project.details") {
                    TextField("project.name", text: $name)
                    TextField("project.number", text: $projectNumber)
                    TextField("project.customer", text: $customerName)
                    Picker("project.quote_language", selection: $quoteLanguage) {
                        Text("language.english").tag("en")
                        Text("language.chinese").tag("zh-Hans")
                    }
                    Picker("settings.unit_system", selection: $unitSystem) {
                        ForEach(UnitSystem.allCases) { Text($0.localizationKey).tag($0) }
                    }
                    CurrencyPickerRow(selection: $currencyDraft)
                    Picker("settings.paper", selection: $paperSize) {
                        Text("paper.a4").tag(PaperSize.a4)
                        Text("paper.letter").tag(PaperSize.letter)
                    }
                }
                Section("project.pricing") {
                    Picker("project.profit_mode", selection: $profitMode) { ForEach(ProfitMode.allCases) { Text($0.localizationKey).tag($0) } }
                    HStack { Text(profitMode == .markup ? "project.markup_percent" : "project.margin_percent"); Spacer(); TextField("0", text: $profitDraft).keyboardType(.decimalPad).multilineTextAlignment(.trailing); Text("%") }
                    HStack { Text("project.tax_percent"); Spacer(); TextField("0", text: $taxDraft).keyboardType(.decimalPad).multilineTextAlignment(.trailing); Text("%") }
                    Stepper(value: $validDays, in: 1...365) { LabeledContent("project.valid_days", value: "\(validDays)") }
                    if validProfit == nil || validTax == nil { Label("error.invalid_pricing_policy", systemImage: "exclamationmark.triangle.fill").foregroundStyle(.red) }
                }
                Section("project.terms") {
                    if purchaseManager.isPro {
                        TextField("project.terms", text: $terms, axis: .vertical).lineLimit(3...8)
                    } else {
                        Button { paywallReason = .terms } label: {
                            Label("purchase.limit.terms", systemImage: "lock.fill")
                        }
                    }
                    TextField("project.notes", text: $notes, axis: .vertical).lineLimit(3...8)
                }
            }
            .keyboardDismissSupport()
            .navigationTitle("project.edit")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("common.cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("common.done") {
                        save()
                    }
                    .disabled(!canSave)
                }
            }
            .onAppear {
                name = project.name
                projectNumber = project.projectNumber
                customerName = project.customerName
                quoteLanguage = project.quoteLanguage
                unitSystem = project.unitSystem
                paperSize = project.paperSize
                validDays = project.validDays
                terms = project.terms
                notes = project.notes
                currencyDraft = project.currencyCode
                taxDraft = project.taxPercentText
                profitDraft = project.markupPercentText
                profitMode = project.profitMode
            }
            .sheet(isPresented: $showCurrencyChange) {
                if let newCurrency = normalizedCurrency {
                    CurrencyChangeSheet(oldCurrency: project.currencyCode, newCurrency: newCurrency) { mode, rate in
                        if applyCurrencyChange(mode: mode, rate: rate, newCurrency: newCurrency) {
                            finishSave()
                        } else {
                            showCurrencyError = true
                        }
                    }
                }
            }
            .alert("currency_change.failed.title", isPresented: $showCurrencyError) {
                Button("common.ok", role: .cancel) {}
            } message: {
                Text("currency_change.failed.message")
            }
            .proPaywall(reason: $paywallReason)
        }
    }

    private func save() {
        guard let newCurrency = normalizedCurrency, validTax != nil, validProfit != nil else { return }
        if newCurrency != project.currencyCode { showCurrencyChange = true }
        else { finishSave() }
    }

    private func finishSave() {
        guard let tax = validTax, let profit = validProfit else { return }
        project.name = name.trimmingCharacters(in: .whitespacesAndNewlines)
        project.projectNumber = projectNumber.trimmingCharacters(in: .whitespacesAndNewlines)
        project.customerName = customerName.trimmingCharacters(in: .whitespacesAndNewlines)
        project.quoteLanguage = quoteLanguage
        project.unitSystem = unitSystem
        project.paperSize = paperSize
        project.validDays = validDays
        if purchaseManager.isPro { project.terms = terms }
        project.notes = notes
        project.taxPercentText = tax.description
        project.markupPercentText = profit.description
        project.profitMode = profitMode
        project.updatedAt = .now
        if PersistenceErrorCenter.shared.save(modelContext) { dismiss() }
    }

    private func applyCurrencyChange(mode: CurrencyChangeMode, rate: Decimal?, newCurrency: String) -> Bool {
        CurrencyMigration.apply(to: project, newCurrency: newCurrency, mode: mode, rate: rate)
    }
}

private struct CurrencyChangeSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.locale) private var locale
    let oldCurrency: String
    let newCurrency: String
    let apply: (CurrencyChangeMode, Decimal?) -> Void
    @State private var mode = CurrencyChangeMode.clearAmounts
    @State private var rateText = ""

    private var rate: Decimal? {
        guard let value = PricingInputValidator.nonnegative(rateText, locale: locale), value > 0 else { return nil }
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
            .keyboardDismissSupport()
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
