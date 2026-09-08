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
    @State private var updateWaste = true
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
                    if updateWaste { TextField("calculator.waste", text: $waste).keyboardType(.decimalPad) }
                    Toggle("project.bulk.price", isOn: $updatePrice)
                    if updatePrice {
                        Picker("calculator.price_basis", selection: $basis) { ForEach(PriceBasis.allCases) { Text($0.localizationKey).tag($0) } }
                        TextField("calculator.unit_price", text: $price).keyboardType(.decimalPad)
                        Text(project.currencyCode).foregroundStyle(.secondary)
                    }
                }
                Section("workflow.select_items") {
                    TextField("workflow.material_search", text: $filter)
                    Button("workflow.select_visible") { selection = Set(visible.map(\.id)) }
                    Button("workflow.clear_selection") { selection = [] }
                    ForEach(visible) { item in
                        Toggle(isOn: Binding(get: { selection.contains(item.id) }, set: { if $0 { selection.insert(item.id) } else { selection.remove(item.id) } })) {
                            Text(item.descriptionText.isEmpty ? AppLocalization.text("profile." + item.profileRaw, locale: locale) + " · " + MaterialCatalog.localizedName(materialID: item.materialID, fallback: item.materialName, locale: locale) : item.descriptionText)
                        }
                    }
                }
                Section("workflow.change_preview") {
                    LabeledContent("workflow.affected", value: String(selected.count))
                    LabeledContent("workflow.before", value: AppFormatters.decimal(ProjectCalculator.summarize(project).pricing.total, currencyCode: project.currencyCode, locale: locale))
                    if canApply { LabeledContent("workflow.after", value: AppFormatters.decimal(newTotal, currencyCode: project.currencyCode, locale: locale)) }
                }
            }
            .keyboardDismissSupport()
            .navigationTitle("project.bulk_pricing")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("common.cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) { Button("project.bulk.apply") { confirm = true }.disabled(!canApply) }
            }
            .confirmationDialog("workflow.apply_confirm", isPresented: $confirm, titleVisibility: .visible) {
                Button("common.apply") { apply() }
            }
        }
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
