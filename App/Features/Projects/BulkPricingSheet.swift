import SwiftUI
import SwiftData

struct ItemPricingState {
    let id: UUID
    let waste: Double
    let price: String
    let basis: String
    let source: PriceSource
    let sourceName: String
    let region: String
    let includesTax: Bool
    let effectiveAt: Date?
    init(_ item: CalculationItemEntity) {
        id = item.id; waste = item.wastePercent; price = item.unitPriceText; basis = item.priceBasisRaw
        source = item.priceSource; sourceName = item.priceSourceName; region = item.priceRegion; includesTax = item.priceIncludesTax; effectiveAt = item.priceEffectiveAt
    }
    func restore(_ item: CalculationItemEntity) {
        item.wastePercent = waste; item.unitPriceText = price; item.priceBasisRaw = basis; item.priceSource = source
        item.priceSourceName = sourceName; item.priceRegion = region; item.priceIncludesTax = includesTax; item.priceEffectiveAt = effectiveAt; item.updatedAt = .now
    }
}

struct BulkPricingSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(\.locale) private var locale
    let project: ProjectEntity
    let onApply: ([ItemPricingState]) -> Void
    @State private var selection = Set<UUID>()
    @State private var filter = ""
    @State private var updateWaste = false
    @State private var waste = "0"
    @State private var updatePrice = false
    @State private var price = "0"
    @State private var basis = PriceBasis.perKilogram
    @State private var confirm = false
    private var selected: [CalculationItemEntity] { project.items.filter { selection.contains($0.id) } }
    private var visible: [CalculationItemEntity] {
        project.items.sorted { $0.sortIndex < $1.sortIndex }.filter {
            filter.isEmpty || [$0.descriptionText, $0.materialName, $0.materialGrade, MaterialCatalog.localizedName(materialID: $0.materialID, fallback: $0.materialName, locale: locale)].contains { $0.localizedStandardContains(filter) }
        }
    }
    private var validWaste: Double? {
        guard let value = DecimalParser.double(waste, locale: locale), (0...1000).contains(value) else { return nil }; return value
    }
    private var validPrice: Decimal? { PricingInputValidator.nonnegative(price, locale: locale) }
    private var canApply: Bool { !selected.isEmpty && (updateWaste || updatePrice) && (!updateWaste || validWaste != nil) && (!updatePrice || validPrice != nil) }
    private func newItem(_ item: CalculationItemEntity) -> CalculationItemEntity {
        let copy = item.copyItem()
        if updateWaste, let value = validWaste { copy.wastePercent = value }
        if updatePrice, let value = validPrice { copy.unitPriceText = value.description; copy.priceBasisRaw = basis.rawValue }
        return copy
    }
    private var newTotal: Decimal {
        let preview = ProjectCloner.copy(project, name: project.name)
        preview.items = project.items.map { selection.contains($0.id) ? newItem($0) : $0.copyItem() }
        return ProjectCalculator.summarize(preview).pricing.total
    }
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Toggle("project.bulk.waste", isOn: $updateWaste)
                    if updateWaste { LabeledEntry("calculator.waste", text: $waste, keyboard: .decimalPad); if validWaste == nil { InlineIssue(key: "ui.waste_range") } }
                    Toggle("project.bulk.price", isOn: $updatePrice)
                    if updatePrice {
                        Picker("calculator.price_basis", selection: $basis) { ForEach(PriceBasis.allCases) { Text($0.localizationKey).tag($0) } }
                        LabeledEntry("calculator.unit_price", text: $price, keyboard: .decimalPad)
                        if validPrice == nil { InlineIssue(key: "ui.nonnegative_amount") }
                        Text(project.currencyCode).foregroundStyle(.secondary)
                    }
                }
                Section("workflow.select_items") {
                    TextField("workflow.material_search", text: $filter)
                    Button("workflow.select_visible") { selection = SelectionRules.addingVisible(visible.map(\.id), to: selection) }
                    Button("workflow.clear_selection") { selection = [] }
                    ForEach(visible) { item in
                        Button {
                            if selection.contains(item.id) { selection.remove(item.id) } else { selection.insert(item.id) }
                        } label: {
                            HStack {
                                Image(systemName: selection.contains(item.id) ? "checkmark.circle.fill" : "circle")
                                VStack(alignment: .leading) {
                                    Text(item.descriptionText.isEmpty ? MaterialCatalog.localizedName(materialID: item.materialID, fallback: item.materialName, locale: locale) : item.descriptionText).foregroundStyle(.primary)
                                    Text(AppLocalization.text("profile." + item.profileRaw, locale: locale) + " · " + AppFormatters.number(item.lengthValue, locale: locale) + " " + item.lengthUnit.rawValue + " × " + String(item.quantity)).font(.caption).foregroundStyle(.secondary)
                                }
                                Spacer()
                            }.frame(minHeight: 44)
                        }.accessibilityIdentifier("bulk.item." + item.descriptionText)
                        .accessibilityValue(selection.contains(item.id) ? Text("ui.selected") : Text("ui.not_selected"))

                    }
                }
                Section("workflow.change_preview") {
                    LabeledContent("workflow.affected", value: String(selected.count))
                    LabeledContent("workflow.before", value: AppFormatters.decimal(ProjectCalculator.summarize(project).pricing.total, currencyCode: project.currencyCode, locale: locale))
                    if canApply { LabeledContent("workflow.after", value: AppFormatters.decimal(newTotal, currencyCode: project.currencyCode, locale: locale)) }
                }
            }
            .keyboardDismissSupport()
            .safeAreaInset(edge: .bottom) {
                Text(AppLocalization.format("ui.selection_count", locale: locale, selection.count, visible.count))
                    .font(.subheadline.bold()).padding().frame(maxWidth: .infinity).background(.bar)
                    .accessibilityIdentifier("bulk.selection_count")
            }
            .navigationTitle("project.bulk_pricing")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("common.cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) { Button("project.bulk.apply") { confirm = true }.disabled(!canApply) }
            }
            .sheet(isPresented: $confirm) {
                NavigationStack {
                    List {
                        Text(AppLocalization.format("ui.selection_count", locale: locale, selection.count, visible.count))
                        ForEach(selected) { item in
                            VStack(alignment: .leading, spacing: 6) {
                                Text(item.descriptionText.isEmpty ? item.materialName : item.descriptionText).font(.headline)
                                if updateWaste { Text(wasteChange(item)) }
                                if updatePrice { Text(priceChange(item)) }
                            }
                        }
                    }.navigationTitle("workflow.change_preview").navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) { Button("common.cancel") { confirm = false } }
                        ToolbarItem(placement: .confirmationAction) { Button("common.apply") { confirm = false; apply() } }
                    }
                }
            }
        }
    }
    private func wasteChange(_ item: CalculationItemEntity) -> String {
        let title = AppLocalization.text("calculator.waste", locale: locale)
        let old = AppFormatters.number(item.wastePercent, locale: locale)
        return "\(title): \(old)% → \(waste)%"
    }
    private func priceChange(_ item: CalculationItemEntity) -> String {
        let oldAmount = AppFormatters.decimal(item.unitPrice, currencyCode: project.currencyCode, locale: locale)
        let oldUnit = AppLocalization.text("ui.basis." + item.priceBasis.rawValue, locale: locale)
        let newUnit = AppLocalization.text("ui.basis." + basis.rawValue, locale: locale)
        return oldAmount + " / " + oldUnit + " → " + price + " " + project.currencyCode + " / " + newUnit
    }
    private func apply() {
        guard canApply else { return }
        let previous = selected.map(ItemPricingState.init)
        for item in selected {
            if updateWaste, let value = validWaste { item.wastePercent = value }
            if updatePrice, let value = validPrice {
                item.unitPriceText = value.description; item.priceBasisRaw = basis.rawValue; item.priceSource = .manual
                item.priceSourceName = ""; item.priceRegion = ""; item.priceIncludesTax = false; item.priceEffectiveAt = .now
            }
            item.updatedAt = .now
        }
        project.updatedAt = .now
        if PersistenceErrorCenter.shared.save(modelContext) { onApply(previous); dismiss() }
    }
}
