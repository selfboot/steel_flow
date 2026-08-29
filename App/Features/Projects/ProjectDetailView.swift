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
    @State private var paywallReason: ProPaywallReason?
    @State private var purchaseManager = PurchaseManager.shared

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
                if purchaseManager.isPro || project.items.count < ProPolicy.freeItemsPerProjectLimit {
                    NavigationLink {
                        ProfilePickerForProject(project: project)
                    } label: { Label("project.add_item", systemImage: "plus.circle") }
                } else {
                    Button { paywallReason = .items } label: {
                        Label("project.add_item", systemImage: "lock.fill")
                    }
                }
            }

            Section("project.summary") {
                ProjectSummaryRow("calculator.result.total_mass", value: "\(AppFormatters.number(summary.netMassKg, maximumFractionDigits: 2, locale: locale)) kg")
                ProjectSummaryRow("calculator.result.with_waste", value: "\(AppFormatters.number(summary.adjustedMassKg, maximumFractionDigits: 2, locale: locale)) kg")
                ProjectSummaryRow("project.material_subtotal", value: money(summary.pricing.materialSubtotal))
                ProjectSummaryRow("project.fees", value: money(summary.pricing.fees))
                ProjectSummaryRow(project.profitMode == .markup ? "project.markup" : "project.margin", value: money(summary.pricing.profit))
                ProjectSummaryRow("project.tax", value: money(summary.pricing.tax))
                ProjectSummaryRow("project.total", value: money(summary.pricing.total), emphasized: true)
                if summary.invalidItemCount > 0 {
                    Label(AppLocalization.count("project.invalid_items", value: summary.invalidItemCount, locale: locale), systemImage: "exclamationmark.triangle")
                        .foregroundStyle(.orange)
                }
                if !summary.isPricingPolicyValid {
                    Label("error.invalid_pricing_policy", systemImage: "exclamationmark.triangle").foregroundStyle(.red)
                }
                let zeroPriceCount = project.items.filter { $0.isPricingValid && $0.unitPrice == 0 }.count
                if zeroPriceCount > 0 {
                    Label(AppLocalization.count("project.zero_price_items", value: zeroPriceCount, locale: locale), systemImage: "exclamationmark.circle").foregroundStyle(.orange)
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
                    Button("project.bulk_pricing") {
                        if purchaseManager.isPro { showBulkPricing = true } else { paywallReason = .bulkPricing }
                    }
                } label: { Image(systemName: "ellipsis.circle") }
            }
        }
        .sheet(isPresented: $showEdit) { ProjectSettingsSheet(project: project) }
        .sheet(isPresented: $showQuote) { QuotePreviewView(project: project) }
        .sheet(isPresented: $showBulkPricing) { BulkPricingSheet(project: project) }
        .proPaywall(reason: $paywallReason)
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

private struct ProjectSummaryRow: View {
    let title: LocalizedStringResource
    let value: String
    let emphasized: Bool
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    init(_ title: LocalizedStringResource, value: String, emphasized: Bool = false) {
        self.title = title
        self.value = value
        self.emphasized = emphasized
    }

    var body: some View {
        Group {
            if dynamicTypeSize.isAccessibilitySize {
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                    Text(value).frame(maxWidth: .infinity, alignment: .trailing)
                }
            } else {
                HStack(alignment: .firstTextBaseline, spacing: 12) {
                    Text(title).lineLimit(2)
                    Spacer(minLength: 8)
                    Text(value).fixedSize(horizontal: true, vertical: false)
                }
            }
        }
        .font(emphasized ? .headline : .body)
        .foregroundStyle(emphasized ? SteelFlowTheme.steelBlue : .primary)
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
                Text(item.descriptionText.isEmpty ? AppLocalization.text("profile.\(item.profile.rawValue)", locale: locale) : item.descriptionText)
                    .font(.subheadline.weight(.semibold))
                    .lineLimit(2)
                Text("\(MaterialCatalog.localizedName(materialID: item.materialID, fallback: item.materialName, locale: locale)) · \(AppFormatters.number(item.lengthValue, locale: locale)) \(item.lengthUnit.rawValue) × \(item.quantity)")
                    .font(.caption).foregroundStyle(.secondary).lineLimit(1)
            }
            .layoutPriority(1)
            Spacer()
            if item.isPricingValid, let result = try? item.calculation() {
                let subtotal = PricingCalculator.lineSubtotal(unitPrice: item.unitPrice, basis: item.priceBasis, result: result, lengthMeters: item.lengthUnit.toMeters(item.lengthValue), quantity: item.quantity, currencyCode: currencyCode)
                VStack(alignment: .trailing) {
                    Text("\(AppFormatters.number(result.totalMassKg, maximumFractionDigits: 2, locale: locale)) kg").font(.caption.monospacedDigit())
                    Text(AppFormatters.decimal(subtotal, currencyCode: currencyCode, locale: locale)).font(.caption2).foregroundStyle(.secondary)
                }
                .fixedSize(horizontal: true, vertical: false)
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
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    let item: CalculationItemEntity
    let currencyCode: String
    @Environment(\.locale) private var locale
    @Query(sort: \MaterialEntity.createdAt) private var materials: [MaterialEntity]
    @Query(sort: \PriceBookEntryEntity.effectiveAt, order: .reverse) private var priceBook: [PriceBookEntryEntity]
    @State private var selectedPriceEntryID: UUID?
    @State private var dimensionTexts: [DimensionField: String] = [:]
    @State private var geometryUnit = LengthUnit.millimeter
    @State private var areaUnit = AreaUnit.squareMillimeter
    @State private var selectedMaterialID = ""
    @State private var densityText = ""
    @State private var lengthText = ""
    @State private var lengthUnit = LengthUnit.meter
    @State private var quantity = 1
    @State private var wasteText = ""
    @State private var priceBasis = PriceBasis.perKilogram
    @State private var unitPriceText = ""
    @State private var processingFeeText = ""
    @State private var otherFeeText = ""
    @State private var priceSource = PriceSource.manual
    @State private var priceSourceName = ""
    @State private var priceRegion = ""
    @State private var materialGrade = ""
    @State private var priceIncludesTax = false
    @State private var priceEffectiveAt = Date.now
    @State private var descriptionText = ""
    @State private var internalNote = ""

    private var availablePriceEntries: [PriceBookEntryEntity] {
        priceBook.filter { $0.currencyCode == currencyCode && ($0.materialID.isEmpty || $0.materialID == selectedMaterialID) }
    }
    private var parsedDensity: Double? { DecimalParser.double(densityText, locale: locale) }
    private var parsedLength: Double? { DecimalParser.double(lengthText, locale: locale) }
    private var parsedWaste: Double? { DecimalParser.double(wasteText, locale: locale) }
    private var parsedUnitPrice: Decimal? { PricingInputValidator.nonnegative(unitPriceText, locale: locale) }
    private var parsedProcessingFee: Decimal? { PricingInputValidator.nonnegative(processingFeeText, locale: locale) }
    private var parsedOtherFee: Decimal? { PricingInputValidator.nonnegative(otherFeeText, locale: locale) }
    private var parsedGeometry: GeometryInput? {
        var values: [DimensionField: Double] = [:]
        for field in item.profile.dimensionFields {
            guard let text = dimensionTexts[field], let value = DecimalParser.double(text, locale: locale) else { return nil }
            values[field] = value
        }
        return GeometryInput(values: values, lengthUnit: geometryUnit, areaUnit: areaUnit)
    }
    private var previewInput: ProfilePreviewInput? {
        guard let geometry = parsedGeometry, let length = parsedLength else { return nil }
        return ProfilePreviewInput.make(
            profile: item.profile,
            geometry: geometry,
            lengthValue: length,
            lengthUnit: lengthUnit,
            locale: locale
        )
    }
    private var calculation: Result<CalculationResult, CalculationError>? {
        guard let geometry = parsedGeometry, let density = parsedDensity, let length = parsedLength, let waste = parsedWaste else { return nil }
        do {
            return .success(try CalculationEngine.calculate(.init(
                profile: item.profile,
                geometry: geometry,
                lengthValue: length,
                lengthUnit: lengthUnit,
                quantity: quantity,
                densityKgPerM3: density,
                wastePercent: waste
            )))
        } catch let error as CalculationError {
            return .failure(error)
        } catch {
            return .failure(.nonFiniteResult)
        }
    }
    private var result: CalculationResult? {
        guard case .success(let result) = calculation else { return nil }
        return result
    }
    private var isPricingDraftValid: Bool { parsedUnitPrice != nil && parsedProcessingFee != nil && parsedOtherFee != nil }
    private var canSave: Bool { result != nil && isPricingDraftValid }

    var body: some View {
        List {
            Section("calculator.section.geometry") {
                ForEach(item.profile.dimensionFields) { field in
                    AdaptiveFormRow(field.localizationKey) {
                        TextField("0", text: dimensionBinding(field))
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                        Text(field == .customArea ? areaUnit.rawValue : geometryUnit.rawValue)
                            .foregroundStyle(.secondary)
                            .fixedSize()
                    }
                }
                if item.profile == .customArea {
                    Picker("calculator.area_unit", selection: areaUnitBinding) {
                        ForEach(AreaUnit.allCases) { Text($0.rawValue).tag($0) }
                    }
                } else {
                    Picker("calculator.dimension_unit", selection: geometryUnitBinding) {
                        ForEach([LengthUnit.millimeter, .centimeter, .inch]) { Text($0.rawValue).tag($0) }
                    }
                }
            }
            Section("calculator.section.preview") {
                if let previewInput {
                    ProfileSection3DPreview(input: previewInput)
                } else {
                    Label("preview.invalid", systemImage: "cube")
                        .foregroundStyle(.secondary)
                }
            }
            Section("calculator.section.material") {
                Picker("calculator.material", selection: $selectedMaterialID) {
                    if !materials.contains(where: { $0.id == item.materialID }) {
                        Text(MaterialCatalog.localizedName(materialID: item.materialID, fallback: item.materialName, locale: locale)).tag(item.materialID)
                    }
                    ForEach(materials) { material in
                        Text(MaterialCatalog.localizedName(materialID: material.id, fallback: material.name, locale: locale)).tag(material.id)
                    }
                }
                .onChange(of: selectedMaterialID) { oldID, id in
                    guard !oldID.isEmpty else { return }
                    guard let material = materials.first(where: { $0.id == id }) else { return }
                    densityText = AppFormatters.number(material.densityKgPerM3, maximumFractionDigits: 3, locale: locale)
                }
                HStack {
                    Text("calculator.density")
                    Spacer()
                    TextField("7850", text: $densityText).keyboardType(.decimalPad).multilineTextAlignment(.trailing)
                    Text("kg/m³").foregroundStyle(.secondary)
                }
            }
            Section("calculator.section.pricing") {
                AdaptiveFormRow("calculator.length") {
                    LengthValueInput(
                        text: $lengthText,
                        unit: lengthUnitBinding,
                        units: LengthUnit.allCases
                    )
                }
                Stepper(value: $quantity, in: 1...1_000_000) { LabeledContent("calculator.quantity", value: "\(quantity)") }
                HStack { Text("calculator.waste"); Spacer(); TextField("0", text: $wasteText).keyboardType(.decimalPad).multilineTextAlignment(.trailing); Text("%") }
                Text("calculator.waste_pricing_help").font(.caption).foregroundStyle(.secondary)
                Picker("calculator.price_basis", selection: $priceBasis) {
                    ForEach(PriceBasis.allCases) { Text($0.localizationKey).tag($0) }
                }
                HStack { Text("calculator.unit_price"); Spacer(); TextField("0", text: $unitPriceText).keyboardType(.decimalPad).multilineTextAlignment(.trailing); Text(currencyCode).foregroundStyle(.secondary) }
                HStack { Text("calculator.line_processing_fee"); Spacer(); TextField("0", text: $processingFeeText).keyboardType(.decimalPad).multilineTextAlignment(.trailing) }
                HStack { Text("calculator.line_other_fee"); Spacer(); TextField("0", text: $otherFeeText).keyboardType(.decimalPad).multilineTextAlignment(.trailing) }
                Picker("calculator.price_source", selection: $priceSource) {
                    ForEach(PriceSource.allCases) { Text($0.localizationKey).tag($0) }
                }
                if priceSource == .history {
                    Picker("calculator.price_history", selection: $selectedPriceEntryID) {
                        Text("calculator.price_history.choose").tag(Optional<UUID>.none)
                        ForEach(availablePriceEntries) { entry in Text(entry.name).tag(Optional(entry.id)) }
                    }
                    .onChange(of: selectedPriceEntryID) { _, id in
                        guard let id, let entry = priceBook.first(where: { $0.id == id }) else { return }
                        unitPriceText = entry.unitPrice.description
                        priceBasis = entry.priceBasis
                        priceSourceName = entry.supplier.isEmpty ? entry.name : entry.supplier
                        priceRegion = entry.region
                        materialGrade = entry.materialGrade
                        priceIncludesTax = entry.includesTax
                        priceEffectiveAt = entry.effectiveAt
                    }
                } else {
                    TextField("calculator.price_source_name", text: $priceSourceName)
                    TextField("calculator.price_region", text: $priceRegion)
                    TextField("calculator.material_grade", text: $materialGrade)
                    DatePicker("calculator.price_effective_date", selection: $priceEffectiveAt, displayedComponents: .date)
                }
                Toggle("calculator.price_includes_tax", isOn: $priceIncludesTax)
                TextField("calculator.description", text: $descriptionText)
                TextField("calculator.internal_note", text: $internalNote, axis: .vertical)
                if !isPricingDraftValid { Label("error.invalid_pricing", systemImage: "exclamationmark.triangle.fill").foregroundStyle(.red) }
            }
            if let result {
                Section("calculator.section.result") {
                    LabeledContent("calculator.result.unit_mass", value: "\(AppFormatters.number(result.unitMassKg, maximumFractionDigits: 3, locale: locale)) kg")
                    LabeledContent("calculator.result.total_mass", value: "\(AppFormatters.number(result.totalMassKg, maximumFractionDigits: 3, locale: locale)) kg")
                    if let unitPrice = parsedUnitPrice, let length = parsedLength {
                        let subtotal = PricingCalculator.lineSubtotal(unitPrice: unitPrice, basis: priceBasis, result: result, lengthMeters: lengthUnit.toMeters(length), quantity: quantity, currencyCode: currencyCode)
                        LabeledContent("calculator.result.material_subtotal", value: AppFormatters.decimal(subtotal, currencyCode: currencyCode, locale: locale))
                    }
                    LabeledContent("calculator.details.formula", value: result.trace.formula)
                    if item.profile.usesIdealizedGeometry {
                        Label("calculator.idealized_geometry_help", systemImage: "info.circle").font(.caption).foregroundStyle(.secondary)
                    }
                }
            } else if calculation != nil {
                Section { Label("calculator.invalid_input", systemImage: "exclamationmark.triangle.fill").foregroundStyle(.red) }
            }
        }
        .keyboardDismissSupport()
        .navigationTitle(item.profile.localizationKey)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) { Button("common.cancel") { dismiss() } }
            ToolbarItem(placement: .confirmationAction) { Button("common.done") { save() }.disabled(!canSave) }
        }
        .onAppear(perform: load)
    }

    private var lengthUnitBinding: Binding<LengthUnit> {
        Binding(
            get: { lengthUnit },
            set: { newUnit in
                let oldUnit = lengthUnit
                guard newUnit != oldUnit else { return }
                if let value = parsedLength {
                    lengthText = AppFormatters.number(newUnit.fromMeters(oldUnit.toMeters(value)), maximumFractionDigits: 6, locale: locale)
                }
                lengthUnit = newUnit
            }
        )
    }

    private func dimensionBinding(_ field: DimensionField) -> Binding<String> {
        Binding(get: { dimensionTexts[field] ?? "" }, set: { dimensionTexts[field] = $0 })
    }

    private var geometryUnitBinding: Binding<LengthUnit> {
        Binding(
            get: { geometryUnit },
            set: { newUnit in
                guard newUnit != geometryUnit else { return }
                var converted = dimensionTexts
                for field in item.profile.dimensionFields where field != .customArea {
                    guard let text = dimensionTexts[field], let value = DecimalParser.double(text, locale: locale) else { return }
                    converted[field] = AppFormatters.number(newUnit.fromMeters(geometryUnit.toMeters(value)), maximumFractionDigits: 6, locale: locale)
                }
                dimensionTexts = converted
                geometryUnit = newUnit
            }
        )
    }

    private var areaUnitBinding: Binding<AreaUnit> {
        Binding(
            get: { areaUnit },
            set: { newUnit in
                guard newUnit != areaUnit,
                      let text = dimensionTexts[.customArea],
                      let value = DecimalParser.double(text, locale: locale) else { return }
                dimensionTexts[.customArea] = AppFormatters.number(
                    newUnit.fromSquareMeters(areaUnit.toSquareMeters(value)),
                    maximumFractionDigits: 6,
                    locale: locale
                )
                areaUnit = newUnit
            }
        )
    }

    private func load() {
        let geometry = item.geometry
        dimensionTexts = geometry.values.mapValues { AppFormatters.number($0, maximumFractionDigits: 6, locale: locale) }
        geometryUnit = geometry.lengthUnit
        areaUnit = geometry.areaUnit
        selectedMaterialID = item.materialID
        densityText = AppFormatters.number(item.densityKgPerM3, maximumFractionDigits: 3, locale: locale)
        lengthText = AppFormatters.number(item.lengthValue, maximumFractionDigits: 6, locale: locale)
        lengthUnit = item.lengthUnit
        quantity = item.quantity
        wasteText = AppFormatters.number(item.wastePercent, maximumFractionDigits: 3, locale: locale)
        priceBasis = item.priceBasis
        unitPriceText = item.unitPriceText
        processingFeeText = item.processingFeeText
        otherFeeText = item.otherFeeText
        priceSource = item.priceSource
        priceSourceName = item.priceSourceName
        priceRegion = item.priceRegion
        materialGrade = item.materialGrade
        priceIncludesTax = item.priceIncludesTax
        priceEffectiveAt = item.priceEffectiveAt ?? .now
        descriptionText = item.descriptionText
        internalNote = item.internalNote
    }

    private func save() {
        guard let geometry = parsedGeometry, let geometryData = try? JSONEncoder().encode(geometry),
              let density = parsedDensity, let length = parsedLength, let waste = parsedWaste,
              let unitPrice = parsedUnitPrice, let processingFee = parsedProcessingFee, let otherFee = parsedOtherFee,
              result != nil else { return }
        item.geometryData = geometryData
        if let material = materials.first(where: { $0.id == selectedMaterialID }) {
            item.materialID = material.id
            item.materialName = material.name
        }
        item.densityKgPerM3 = density
        item.lengthValue = length
        item.lengthUnitRaw = lengthUnit.rawValue
        item.quantity = quantity
        item.wastePercent = waste
        item.priceBasisRaw = priceBasis.rawValue
        item.unitPriceText = unitPrice.description
        item.processingFeeText = processingFee.description
        item.otherFeeText = otherFee.description
        item.priceSource = priceSource
        item.priceSourceName = priceSourceName
        item.priceRegion = priceRegion
        item.materialGrade = materialGrade
        item.priceIncludesTax = priceIncludesTax
        item.priceEffectiveAt = priceEffectiveAt
        item.descriptionText = descriptionText
        item.internalNote = internalNote
        item.updatedAt = .now
        if PersistenceErrorCenter.shared.save(modelContext) { dismiss() }
    }
}

private struct BulkPricingSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(\.locale) private var locale
    @Bindable var project: ProjectEntity
    @State private var updateWaste = true
    @State private var waste = "0"
    @State private var updatePrice = false
    @State private var price = "0"
    @State private var basis = PriceBasis.perKilogram

    private var validWaste: Double? {
        guard let value = DecimalParser.double(waste, locale: locale), value >= 0, value <= 1_000 else { return nil }
        return value
    }
    private var validPrice: Decimal? { PricingInputValidator.nonnegative(price, locale: locale) }
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
            .keyboardDismissSupport()
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
