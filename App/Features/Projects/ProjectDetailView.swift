import SwiftUI
import SwiftData

struct ProjectDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.locale) private var locale
    @Bindable var project: ProjectEntity
    @State private var showEdit = false
    @State private var showQuote = false
    @State private var showBulkPricing = false
    @State private var pendingDeleteItems: [CalculationItemEntity] = []
    @State private var showDeleteConfirmation = false

    private var sortedItems: [CalculationItemEntity] { project.items.sorted { $0.sortIndex < $1.sortIndex } }
    private var summary: ProjectSummary { ProjectCalculator.summarize(project) }

    var body: some View {
        List {
            Section {
                LabeledContent("project.number", value: project.projectNumber)
                if !project.customerName.isEmpty { LabeledContent("project.customer", value: project.customerName) }
                LabeledContent("project.updated", value: AppFormatters.date(project.updatedAt, locale: locale))
            }

            Section("project.items") {
                if sortedItems.isEmpty {
                    Text("project.items.empty").foregroundStyle(.secondary)
                } else {
                    ForEach(sortedItems) { item in
                        NavigationLink { ProjectItemDetailView(item: item, currencyCode: project.currencyCode) } label: {
                            ProjectItemRow(item: item, currencyCode: project.currencyCode)
                        }
                    }
                    .onDelete(perform: requestDeleteItems)
                    .onMove(perform: moveItems)
                }
                NavigationLink {
                    ProfilePickerForProject(project: project)
                } label: { Label("project.add_item", systemImage: "plus.circle") }
            }

            Section("project.summary") {
                LabeledContent("calculator.result.total_mass", value: "\(AppFormatters.number(summary.netMassKg, maximumFractionDigits: 2, locale: locale)) kg")
                LabeledContent("calculator.result.with_waste", value: "\(AppFormatters.number(summary.adjustedMassKg, maximumFractionDigits: 2, locale: locale)) kg")
                LabeledContent("project.material_subtotal", value: money(summary.pricing.materialSubtotal))
                LabeledContent("project.fees", value: money(summary.pricing.fees))
                LabeledContent(project.profitMode == .markup ? "project.markup" : "project.margin", value: money(summary.pricing.profit))
                LabeledContent("project.tax", value: money(summary.pricing.tax))
                LabeledContent("project.total", value: money(summary.pricing.total))
                    .font(.headline).foregroundStyle(SteelFlowTheme.steelBlue)
                if summary.invalidItemCount > 0 {
                    Label(String.localizedStringWithFormat(String(localized: "project.invalid_items"), summary.invalidItemCount), systemImage: "exclamationmark.triangle")
                        .foregroundStyle(.orange)
                }
                if !summary.isPricingPolicyValid {
                    Label("error.invalid_pricing_policy", systemImage: "exclamationmark.triangle").foregroundStyle(.red)
                }
                let zeroPriceCount = project.items.filter { $0.isPricingValid && $0.unitPrice == 0 }.count
                if zeroPriceCount > 0 {
                    Label(String.localizedStringWithFormat(String(localized: "project.zero_price_items"), zeroPriceCount), systemImage: "exclamationmark.circle").foregroundStyle(.orange)
                }
            }

            Section {
                Button { showQuote = true } label: {
                    Label("quote.preview", systemImage: "doc.text.magnifyingglass").frame(maxWidth: .infinity)
                }
                .disabled(sortedItems.isEmpty || summary.invalidItemCount > 0 || !summary.isPricingPolicyValid)
            }
        }
        .navigationTitle(project.name)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) { EditButton() }
            ToolbarItem(placement: .primaryAction) {
                Menu {
                    Button("common.edit") { showEdit = true }
                    Button("project.bulk_pricing") { showBulkPricing = true }
                } label: { Image(systemName: "ellipsis.circle") }
            }
        }
        .sheet(isPresented: $showEdit) { ProjectSettingsSheet(project: project) }
        .sheet(isPresented: $showQuote) { QuotePreviewView(project: project) }
        .sheet(isPresented: $showBulkPricing) { BulkPricingSheet(project: project) }
        .alert("delete.confirm.title", isPresented: $showDeleteConfirmation) {
            Button("common.delete", role: .destructive) { confirmDeleteItems() }
            Button("common.cancel", role: .cancel) { pendingDeleteItems = [] }
        } message: {
            Text("delete.confirm.message")
        }
    }

    private func money(_ value: Decimal) -> String { AppFormatters.decimal(value, currencyCode: project.currencyCode, locale: locale) }

    private func requestDeleteItems(at offsets: IndexSet) {
        pendingDeleteItems = offsets.map { sortedItems[$0] }
        showDeleteConfirmation = !pendingDeleteItems.isEmpty
    }

    private func confirmDeleteItems() {
        for item in pendingDeleteItems { modelContext.delete(item) }
        project.updatedAt = .now
        _ = PersistenceErrorCenter.shared.save(modelContext)
        pendingDeleteItems = []
    }

    private func moveItems(from source: IndexSet, to destination: Int) {
        var reordered = sortedItems
        reordered.move(fromOffsets: source, toOffset: destination)
        for (index, item) in reordered.enumerated() { item.sortIndex = index }
        project.updatedAt = .now
        PersistenceErrorCenter.shared.save(modelContext)
    }
}

private struct ProjectItemRow: View {
    let item: CalculationItemEntity
    let currencyCode: String
    @Environment(\.locale) private var locale

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: item.profile.symbol).foregroundStyle(SteelFlowTheme.steelBlue).frame(width: 30)
            VStack(alignment: .leading, spacing: 3) {
                Text(item.descriptionText.isEmpty ? String(localized: item.profile.localizationKey) : item.descriptionText).font(.subheadline.weight(.semibold))
                Text("\(MaterialCatalog.localizedName(materialID: item.materialID, fallback: item.materialName, locale: locale)) · \(AppFormatters.number(item.lengthValue)) \(item.lengthUnit.rawValue) × \(item.quantity)")
                    .font(.caption).foregroundStyle(.secondary).lineLimit(1)
            }
            Spacer()
            if item.isPricingValid, let result = try? item.calculation() {
                let subtotal = PricingCalculator.lineSubtotal(unitPrice: item.unitPrice, basis: item.priceBasis, result: result, lengthMeters: item.lengthUnit.toMeters(item.lengthValue), quantity: item.quantity, currencyCode: currencyCode)
                VStack(alignment: .trailing) {
                    Text("\(AppFormatters.number(result.totalMassKg, maximumFractionDigits: 2, locale: locale)) kg").font(.caption.monospacedDigit())
                    Text(AppFormatters.decimal(subtotal, currencyCode: currencyCode, locale: locale)).font(.caption2).foregroundStyle(.secondary)
                }
            } else {
                Image(systemName: "exclamationmark.triangle").foregroundStyle(.orange)
            }
        }
        .padding(.vertical, 2)
    }
}

private struct ProfilePickerForProject: View {
    let project: ProjectEntity
    let columns = [GridItem(.adaptive(minimum: 140), spacing: 12)]

    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(ProfileKind.allCases) { profile in
                    NavigationLink {
                        ProjectCalculatorEditorHost(profile: profile, project: project)
                    } label: { ProfilePickerCard(profile: profile) }
                    .buttonStyle(.plain)
                }
            }
            .padding()
        }
        .navigationTitle("project.add_item")
    }
}

private struct ProfilePickerCard: View {
    let profile: ProfileKind
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: profile.symbol).font(.title).foregroundStyle(SteelFlowTheme.steelBlue)
            Text(profile.localizationKey).font(.subheadline.weight(.semibold)).multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, minHeight: 100)
        .padding(12)
        .background(SteelFlowTheme.surface, in: RoundedRectangle(cornerRadius: 14))
    }
}

private struct ProjectCalculatorEditorHost: View {
    let profile: ProfileKind
    let project: ProjectEntity
    var body: some View { CalculatorEditorView(profile: profile, destinationProject: project) }
}

private struct ProjectItemDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Bindable var item: CalculationItemEntity
    let currencyCode: String
    @Environment(\.locale) private var locale
    @Query(sort: \PriceBookEntryEntity.effectiveAt, order: .reverse) private var priceBook: [PriceBookEntryEntity]
    @State private var selectedPriceEntryID: UUID?

    private var availablePriceEntries: [PriceBookEntryEntity] {
        priceBook.filter { $0.currencyCode == currencyCode && ($0.materialID.isEmpty || $0.materialID == item.materialID) }
    }
    private var isPricingDraftValid: Bool {
        PricingInputValidator.nonnegative(item.unitPriceText, locale: locale) != nil &&
        PricingInputValidator.nonnegative(item.processingFeeText, locale: locale) != nil &&
        PricingInputValidator.nonnegative(item.otherFeeText, locale: locale) != nil
    }

    var body: some View {
        List {
            Section("calculator.section.geometry") {
                ForEach(item.geometry.values.keys.sorted(by: { $0.rawValue < $1.rawValue }), id: \.self) { key in
                    LabeledContent {
                        Text("\(AppFormatters.number(item.geometry.values[key] ?? 0)) \(key == .customArea ? item.geometry.areaUnit.rawValue : item.geometry.lengthUnit.rawValue)")
                    } label: {
                        Text(key.localizationKey)
                    }
                }
                LabeledContent("calculator.length", value: "\(AppFormatters.number(item.lengthValue)) \(item.lengthUnit.rawValue)")
                LabeledContent("calculator.quantity", value: "\(item.quantity)")
            }
            Section("calculator.section.material") {
                LabeledContent("calculator.material", value: MaterialCatalog.localizedName(materialID: item.materialID, fallback: item.materialName, locale: locale))
                HStack {
                    Text("calculator.density")
                    Spacer()
                    TextField("7850", value: $item.densityKgPerM3, format: .number).keyboardType(.decimalPad).multilineTextAlignment(.trailing)
                    Text("kg/m³").foregroundStyle(.secondary)
                }
            }
            Section("calculator.section.pricing") {
                HStack {
                    Text("calculator.length")
                    Spacer()
                    TextField("0", value: $item.lengthValue, format: .number).keyboardType(.decimalPad).multilineTextAlignment(.trailing)
                    Picker("calculator.length_unit", selection: itemLengthUnitBinding) {
                        ForEach(LengthUnit.allCases) { Text($0.rawValue).tag($0.rawValue) }
                    }.labelsHidden().frame(width: 78)
                }
                Stepper(value: $item.quantity, in: 1...1_000_000) { LabeledContent("calculator.quantity", value: "\(item.quantity)") }
                HStack { Text("calculator.waste"); Spacer(); TextField("0", value: $item.wastePercent, format: .number).keyboardType(.decimalPad).multilineTextAlignment(.trailing); Text("%") }
                Text("calculator.waste_pricing_help").font(.caption).foregroundStyle(.secondary)
                Picker("calculator.price_basis", selection: $item.priceBasisRaw) {
                    ForEach(PriceBasis.allCases) { Text($0.localizationKey).tag($0.rawValue) }
                }
                HStack { Text("calculator.unit_price"); Spacer(); TextField("0", text: $item.unitPriceText).keyboardType(.decimalPad).multilineTextAlignment(.trailing); Text(currencyCode).foregroundStyle(.secondary) }
                HStack { Text("calculator.line_processing_fee"); Spacer(); TextField("0", text: $item.processingFeeText).keyboardType(.decimalPad).multilineTextAlignment(.trailing) }
                HStack { Text("calculator.line_other_fee"); Spacer(); TextField("0", text: $item.otherFeeText).keyboardType(.decimalPad).multilineTextAlignment(.trailing) }
                Picker("calculator.price_source", selection: $item.priceSourceRaw) {
                    ForEach(PriceSource.allCases) { Text($0.localizationKey).tag($0.rawValue) }
                }
                if item.priceSource == .history {
                    Picker("calculator.price_history", selection: $selectedPriceEntryID) {
                        Text("calculator.price_history.choose").tag(Optional<UUID>.none)
                        ForEach(availablePriceEntries) { entry in Text(entry.name).tag(Optional(entry.id)) }
                    }
                    .onChange(of: selectedPriceEntryID) { _, id in
                        guard let id, let entry = priceBook.first(where: { $0.id == id }) else { return }
                        item.unitPriceText = entry.unitPrice.description
                        item.priceBasisRaw = entry.priceBasis.rawValue
                        item.priceSourceName = entry.supplier.isEmpty ? entry.name : entry.supplier
                        item.priceRegion = entry.region
                        item.materialGrade = entry.materialGrade
                        item.priceIncludesTax = entry.includesTax
                        item.priceEffectiveAt = entry.effectiveAt
                    }
                } else {
                    TextField("calculator.price_source_name", text: $item.priceSourceName)
                    TextField("calculator.price_region", text: $item.priceRegion)
                    TextField("calculator.material_grade", text: $item.materialGrade)
                    DatePicker("calculator.price_effective_date", selection: Binding(get: { item.priceEffectiveAt ?? .now }, set: { item.priceEffectiveAt = $0 }), displayedComponents: .date)
                }
                Toggle("calculator.price_includes_tax", isOn: $item.priceIncludesTax)
                TextField("calculator.description", text: $item.descriptionText)
                TextField("calculator.internal_note", text: $item.internalNote, axis: .vertical)
                if !isPricingDraftValid { Label("error.invalid_pricing", systemImage: "exclamationmark.triangle.fill").foregroundStyle(.red) }
            }
            if let result = try? item.calculation() {
                Section("calculator.section.result") {
                    LabeledContent("calculator.result.unit_mass", value: "\(AppFormatters.number(result.unitMassKg, maximumFractionDigits: 3, locale: locale)) kg")
                    LabeledContent("calculator.result.total_mass", value: "\(AppFormatters.number(result.totalMassKg, maximumFractionDigits: 3, locale: locale)) kg")
                    if isPricingDraftValid, let unitPrice = PricingInputValidator.nonnegative(item.unitPriceText, locale: locale) {
                        let subtotal = PricingCalculator.lineSubtotal(unitPrice: unitPrice, basis: item.priceBasis, result: result, lengthMeters: item.lengthUnit.toMeters(item.lengthValue), quantity: item.quantity, currencyCode: currencyCode)
                        LabeledContent("calculator.result.material_subtotal", value: AppFormatters.decimal(subtotal, currencyCode: currencyCode, locale: locale))
                    }
                    LabeledContent("calculator.details.formula", value: result.trace.formula)
                    if item.profile.usesIdealizedGeometry {
                        Label("calculator.idealized_geometry_help", systemImage: "info.circle").font(.caption).foregroundStyle(.secondary)
                    }
                }
            }
        }
        .navigationTitle(item.profile.localizationKey)
        .onDisappear {
            _ = item.canonicalizePricing(locale: locale)
            item.updatedAt = .now
            PersistenceErrorCenter.shared.save(modelContext)
        }
    }

    private var itemLengthUnitBinding: Binding<String> {
        Binding(
            get: { item.lengthUnitRaw },
            set: { raw in
                guard let newUnit = LengthUnit(rawValue: raw) else { return }
                let oldUnit = item.lengthUnit
                guard newUnit != oldUnit else { return }
                item.lengthValue = newUnit.fromMeters(oldUnit.toMeters(item.lengthValue))
                item.lengthUnitRaw = newUnit.rawValue
            }
        )
    }
}

private struct BulkPricingSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Bindable var project: ProjectEntity
    @State private var updateWaste = true
    @State private var waste = "0"
    @State private var updatePrice = false
    @State private var price = "0"
    @State private var basis = PriceBasis.perKilogram

    private var validWaste: Double? {
        guard let value = DecimalParser.double(waste), value >= 0, value <= 1_000 else { return nil }
        return value
    }
    private var validPrice: Decimal? { PricingInputValidator.nonnegative(price) }
    private var canApply: Bool { (!updateWaste || validWaste != nil) && (!updatePrice || validPrice != nil) && (updateWaste || updatePrice) }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Toggle("project.bulk.waste", isOn: $updateWaste)
                    if updateWaste { HStack { Text("calculator.waste"); Spacer(); TextField("0", text: $waste).keyboardType(.decimalPad).multilineTextAlignment(.trailing); Text("%") } }
                    Toggle("project.bulk.price", isOn: $updatePrice)
                    if updatePrice {
                        Picker("calculator.price_basis", selection: $basis) { ForEach(PriceBasis.allCases) { Text($0.localizationKey).tag($0) } }
                        HStack { Text("calculator.unit_price"); Spacer(); TextField("0", text: $price).keyboardType(.decimalPad).multilineTextAlignment(.trailing); Text(project.currencyCode) }
                    }
                }
                Section { Text("project.bulk.help").font(.caption).foregroundStyle(.secondary) }
                if !canApply { Section { Label("error.invalid_pricing", systemImage: "exclamationmark.triangle.fill").foregroundStyle(.red) } }
            }
            .navigationTitle("project.bulk_pricing")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("common.cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) { Button("project.bulk.apply") { apply() }.disabled(!canApply) }
            }
        }
    }

    private func apply() {
        for item in project.items {
            if updateWaste, let value = validWaste { item.wastePercent = value }
            if updatePrice, let value = validPrice { item.unitPriceText = value.description; item.priceBasisRaw = basis.rawValue; item.priceSource = .manual; item.priceEffectiveAt = .now }
            item.updatedAt = .now
        }
        project.updatedAt = .now
        if PersistenceErrorCenter.shared.save(modelContext) { dismiss() }
    }
}
