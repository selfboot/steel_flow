import SwiftUI
import SwiftData

struct CalculatorEditorView: View {
    let profile: ProfileKind
    let destinationProject: ProjectEntity?
    @Environment(\.modelContext) private var modelContext
    @Environment(\.locale) private var locale
    @Query(sort: \MaterialEntity.createdAt) private var materials: [MaterialEntity]
    @Query(sort: \ProjectEntity.updatedAt, order: .reverse) private var projects: [ProjectEntity]
    @Query(sort: \PriceBookEntryEntity.effectiveAt, order: .reverse) private var priceBook: [PriceBookEntryEntity]
    @AppStorage("app.unitSystem") private var unitSystemRaw = UnitSystem.metric.rawValue
    @AppStorage("app.currency") private var defaultCurrency = "USD"
    @State private var draft: CalculatorDraft
    @State private var showSaveSheet = false
    @State private var showDetails = false
    @State private var savedConfirmation = false
    @State private var showProLimit = false
    @State private var purchaseManager = PurchaseManager.shared
    @State private var selectedPriceEntryID: UUID?

    init(profile: ProfileKind, destinationProject: ProjectEntity? = nil, marketingPreset: Bool = false) {
        self.profile = profile
        self.destinationProject = destinationProject
        let draft = CalculatorDraft(profile: profile)
        if marketingPreset {
            let arguments = ProcessInfo.processInfo.arguments
            let localeIndex = arguments.firstIndex(of: "--marketing-locale")
            let localeCode = localeIndex.flatMap { arguments.indices.contains($0 + 1) ? arguments[$0 + 1] : nil }
            draft.applyMarketingPreset(chinese: localeCode?.hasPrefix("zh") == true)
        }
        _draft = State(initialValue: draft)
    }

    private var calculation: Result<CalculationResult, CalculationError>? { draft.result(locale: locale) }
    private var result: CalculationResult? {
        guard case .success(let value) = calculation else { return nil }
        return value
    }
    private var currencyCode: String { destinationProject?.currencyCode ?? defaultCurrency }
    private var pricing: PricingResult? {
        guard let result else { return nil }
        return draft.pricing(locale: locale, result: result, currencyCode: currencyCode)
    }
    private var availablePriceEntries: [PriceBookEntryEntity] {
        priceBook.filter { $0.currencyCode == currencyCode && ($0.materialID.isEmpty || $0.materialID == draft.selectedMaterialID) }
    }

    var body: some View {
        Form {
            Section("calculator.section.geometry") {
                ForEach(profile.dimensionFields) { field in
                    HStack {
                        Text(field.localizationKey)
                        Spacer()
                        TextField("0", text: dimensionBinding(field))
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(minWidth: 90)
                        Text(field == .customArea ? draft.areaUnit.rawValue : draft.geometryUnit.rawValue)
                            .foregroundStyle(.secondary).frame(minWidth: 34, alignment: .leading)
                    }
                    .accessibilityElement(children: .combine)
                }

                if profile == .customArea {
                    Picker("calculator.area_unit", selection: $draft.areaUnit) {
                        ForEach(AreaUnit.allCases) { Text($0.rawValue).tag($0) }
                    }
                } else {
                    Picker("calculator.dimension_unit", selection: geometryUnitBinding) {
                        ForEach([LengthUnit.millimeter, .centimeter, .inch]) { Text($0.rawValue).tag($0) }
                    }
                }

                HStack {
                    Text("calculator.length")
                    Spacer()
                    TextField("0", text: $draft.lengthText)
                        .keyboardType(.decimalPad).multilineTextAlignment(.trailing)
                    Picker("calculator.length_unit", selection: lengthUnitBinding) {
                        ForEach([LengthUnit.meter, .foot, .millimeter, .inch]) { Text($0.rawValue).tag($0) }
                    }
                    .labelsHidden().frame(width: 78)
                }
                Stepper(value: $draft.quantity, in: 1...1_000_000) {
                    LabeledContent("calculator.quantity", value: "\(draft.quantity)")
                }
            }

            Section("calculator.section.material") {
                Picker("calculator.material", selection: materialBinding) {
                    ForEach(materials) { material in
                        Text(materialDisplayName(material)).tag(material.id)
                    }
                }
                HStack {
                    Text("calculator.density")
                    Spacer()
                    TextField("7850", text: $draft.densityText)
                        .keyboardType(.decimalPad).multilineTextAlignment(.trailing)
                    Text("kg/m³").foregroundStyle(.secondary)
                }
                Text("material.note.typical").font(.caption).foregroundStyle(.secondary)
            }

            Section("calculator.section.pricing") {
                HStack {
                    Text("calculator.waste")
                    Spacer()
                    TextField("0", text: $draft.wasteText).keyboardType(.decimalPad).multilineTextAlignment(.trailing)
                    Text("%").foregroundStyle(.secondary)
                }
                Text("calculator.waste_pricing_help").font(.caption).foregroundStyle(.secondary)
                Picker("calculator.price_basis", selection: $draft.priceBasis) {
                    ForEach(PriceBasis.allCases) { Text($0.localizationKey).tag($0) }
                }
                HStack {
                    Text("calculator.unit_price")
                    Spacer()
                    TextField("0", text: $draft.unitPriceText).keyboardType(.decimalPad).multilineTextAlignment(.trailing)
                    Text(currencyCode).foregroundStyle(.secondary)
                }
                HStack {
                    Text("calculator.line_processing_fee")
                    Spacer()
                    TextField("0", text: $draft.processingFeeText).keyboardType(.decimalPad).multilineTextAlignment(.trailing)
                }
                HStack {
                    Text("calculator.line_other_fee")
                    Spacer()
                    TextField("0", text: $draft.otherFeeText).keyboardType(.decimalPad).multilineTextAlignment(.trailing)
                }
                TextField("calculator.description", text: $draft.itemDescription)
                TextField("calculator.internal_note", text: $draft.internalNote, axis: .vertical)
                Picker("calculator.price_source", selection: $draft.priceSource) {
                    ForEach(PriceSource.allCases) { Text($0.localizationKey).tag($0) }
                }
                if draft.priceSource == .history {
                    Picker("calculator.price_history", selection: $selectedPriceEntryID) {
                        Text("calculator.price_history.choose").tag(UUID?.none)
                        ForEach(availablePriceEntries) { entry in
                            Text("\(entry.name) · \(AppFormatters.decimal(entry.unitPrice, currencyCode: entry.currencyCode, locale: locale))").tag(Optional(entry.id))
                        }
                    }
                    .onChange(of: selectedPriceEntryID) { _, id in
                        if let id, let entry = priceBook.first(where: { $0.id == id }) { draft.apply(priceEntry: entry) }
                    }
                    if availablePriceEntries.isEmpty {
                        Text("calculator.price_history.empty").font(.caption).foregroundStyle(.secondary)
                    }
                }
                if draft.priceSource != .history {
                    TextField("calculator.price_source_name", text: $draft.priceSourceName)
                    TextField("calculator.price_region", text: $draft.priceRegion)
                    TextField("calculator.material_grade", text: $draft.materialGrade)
                    DatePicker("calculator.price_effective_date", selection: $draft.priceEffectiveAt, displayedComponents: .date)
                }
                Toggle("calculator.price_includes_tax", isOn: $draft.priceIncludesTax)
                Text("calculator.price_reference_help").font(.caption).foregroundStyle(.secondary)
                if pricing == nil {
                    Label("error.invalid_pricing", systemImage: "exclamationmark.triangle.fill").foregroundStyle(.red)
                }
            }

            Section("calculator.section.result") {
                if let result {
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                        ResultMetric("calculator.result.unit_mass", value: mass(result.unitMassKg))
                        ResultMetric("calculator.result.total_mass", value: mass(result.totalMassKg), emphasized: true)
                        ResultMetric("calculator.result.area", value: area(result.areaSquareMeters))
                        ResultMetric("calculator.result.volume", value: "\(AppFormatters.number(result.volumeCubicMeters, maximumFractionDigits: 6, locale: locale)) m³")
                    }
                    if result.wasteAdjustedMassKg != result.totalMassKg {
                        LabeledContent("calculator.result.with_waste", value: mass(result.wasteAdjustedMassKg))
                    }
                    if let pricing {
                        LabeledContent("calculator.result.material_subtotal", value: AppFormatters.decimal(pricing.materialSubtotal, currencyCode: currencyCode, locale: locale))
                        LabeledContent("calculator.result.estimated_total", value: AppFormatters.decimal(pricing.total, currencyCode: currencyCode, locale: locale))
                            .font(.headline)
                    }
                    if profile.usesIdealizedGeometry {
                        Label("calculator.idealized_geometry_help", systemImage: "info.circle").font(.caption).foregroundStyle(.secondary)
                    }
                    Button("calculator.details") { showDetails = true }
                } else if case .failure(let error) = calculation {
                    Label(errorText(error), systemImage: "exclamationmark.triangle.fill")
                        .foregroundStyle(.red)
                } else {
                    ContentUnavailableView("calculator.invalid_input", systemImage: "number")
                }
            }

            Section {
                Button {
                    if let destinationProject {
                        if canAdd(to: destinationProject) { save(to: destinationProject) } else { showProLimit = true }
                    }
                    else { showSaveSheet = true }
                } label: {
                    Label("calculator.save_to_project", systemImage: "folder.badge.plus")
                        .frame(maxWidth: .infinity)
                }
                .disabled(result == nil || pricing == nil)
            }
        }
        .navigationTitle(profile.localizationKey)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            let preferred = UnitSystem(rawValue: unitSystemRaw) ?? .metric
            if draft.geometryUnit == .millimeter && preferred == .imperial {
                draft = CalculatorDraft(profile: profile, unitSystem: preferred)
            }
            if let material = materials.first(where: { $0.id == draft.selectedMaterialID }) { draft.apply(material: material) }
        }
        .sheet(isPresented: $showSaveSheet) {
            SaveToProjectSheet(projects: projects) { project in save(to: project) }
        }
        .sheet(isPresented: $showDetails) {
            if let result { CalculationDetailsView(result: result) }
        }
        .alert("calculator.saved", isPresented: $savedConfirmation) { Button("common.ok", role: .cancel) {} }
        .alert("purchase.limit.title", isPresented: $showProLimit) { Button("common.ok", role: .cancel) {} } message: { Text("purchase.limit.items") }
    }

    private func dimensionBinding(_ field: DimensionField) -> Binding<String> {
        Binding(get: { draft.dimensionTexts[field] ?? "" }, set: { draft.dimensionTexts[field] = $0 })
    }

    private var geometryUnitBinding: Binding<LengthUnit> {
        Binding(get: { draft.geometryUnit }, set: { draft.convertGeometry(to: $0, locale: locale) })
    }

    private var lengthUnitBinding: Binding<LengthUnit> {
        Binding(get: { draft.lengthUnit }, set: { draft.convertLength(to: $0, locale: locale) })
    }

    private var materialBinding: Binding<String> {
        Binding(get: { draft.selectedMaterialID }, set: { id in
            if let material = materials.first(where: { $0.id == id }) { draft.apply(material: material) }
        })
    }

    private func materialDisplayName(_ material: MaterialEntity) -> String {
        guard let key = material.nameKey else { return material.name }
        return String(localized: String.LocalizationValue(key), locale: locale)
    }

    private func mass(_ kg: Double) -> String {
        let system = UnitSystem(rawValue: unitSystemRaw) ?? .metric
        let unit = system.massUnit
        return "\(AppFormatters.number(unit.fromKilograms(kg), maximumFractionDigits: 3, locale: locale)) \(unit.rawValue)"
    }

    private func area(_ squareMeters: Double) -> String {
        let unit: AreaUnit = (UnitSystem(rawValue: unitSystemRaw) ?? .metric) == .metric ? .squareMillimeter : .squareInch
        return "\(AppFormatters.number(squareMeters / unit.squareMetersPerUnit, maximumFractionDigits: 3, locale: locale)) \(unit.rawValue)"
    }

    private func errorText(_ error: CalculationError) -> LocalizedStringResource {
        switch error {
        case .wallTooThick: "error.wall_too_thick"
        case .flangeTooThick: "error.flange_too_thick"
        case .webTooThick: "error.web_too_thick"
        case .invalidLength: "error.invalid_length"
        case .invalidQuantity: "error.invalid_quantity"
        case .invalidDensity: "error.invalid_density"
        case .missing, .invalid: "error.invalid_dimension"
        case .nonFiniteResult: "error.invalid_result"
        }
    }

    private func save(to project: ProjectEntity) {
        guard canAdd(to: project) else { showProLimit = true; return }
        guard let material = materials.first(where: { $0.id == draft.selectedMaterialID }),
              let item = draft.makeItem(materialName: materialDisplayName(material), locale: locale, sortIndex: project.items.count) else { return }
        project.items.append(item)
        project.updatedAt = .now
        modelContext.insert(item)
        try? modelContext.save()
        showSaveSheet = false
        savedConfirmation = true
    }

    private func canAdd(to project: ProjectEntity) -> Bool {
        purchaseManager.isPro || project.items.count < ProPolicy.freeItemsPerProjectLimit
    }
}

private struct SaveToProjectSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    let projects: [ProjectEntity]
    let onSelect: (ProjectEntity) -> Void
    @State private var newName = ""
    @State private var showProjectLimit = false
    @State private var showItemLimit = false
    @State private var purchaseManager = PurchaseManager.shared

    var body: some View {
        NavigationStack {
            List {
                Section("project.choose") {
                    ForEach(projects.filter { !$0.isArchived }) { project in
                        Button {
                            if purchaseManager.isPro || project.items.count < ProPolicy.freeItemsPerProjectLimit { onSelect(project) }
                            else { showItemLimit = true }
                        } label: {
                            VStack(alignment: .leading) {
                                Text(project.name).foregroundStyle(.primary)
                                Text(project.projectNumber).font(.caption).foregroundStyle(.secondary)
                            }
                        }
                    }
                }
                Section("project.create") {
                    TextField("project.name", text: $newName)
                    Button("project.create_and_add") {
                        if !purchaseManager.isPro && projects.filter({ !$0.isArchived }).count >= ProPolicy.freeActiveProjectLimit {
                            showProjectLimit = true
                        } else {
                            let project = ProjectEntity(name: newName.isEmpty ? String(localized: "project.untitled") : newName)
                            modelContext.insert(project)
                            try? modelContext.save()
                            onSelect(project)
                        }
                    }
                }
            }
            .navigationTitle("calculator.save_to_project")
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("common.cancel") { dismiss() } } }
            .alert("purchase.limit.title", isPresented: $showProjectLimit) { Button("common.ok", role: .cancel) {} } message: { Text("purchase.limit.projects") }
            .alert("purchase.limit.title", isPresented: $showItemLimit) { Button("common.ok", role: .cancel) {} } message: { Text("purchase.limit.items") }
        }
    }
}

private struct CalculationDetailsView: View {
    @Environment(\.dismiss) private var dismiss
    let result: CalculationResult

    var body: some View {
        NavigationStack {
            List {
                Section("calculator.details.formula") { Text(result.trace.formula).font(.body.monospaced()) }
                Section("calculator.details.normalized") {
                    ForEach(result.trace.normalizedDimensions.keys.sorted(), id: \.self) { key in
                        LabeledContent(key, value: "\(AppFormatters.number(result.trace.normalizedDimensions[key] ?? 0, maximumFractionDigits: 8)) m")
                    }
                    LabeledContent("calculator.result.area", value: "\(result.areaSquareMeters) m²")
                    LabeledContent("calculator.length", value: "\(result.trace.lengthMeters) m")
                    LabeledContent("calculator.quantity", value: "\(result.trace.quantity)")
                    LabeledContent("calculator.density", value: "\(result.trace.densityKgPerM3) kg/m³")
                }
                Section("calculator.details.engine") { LabeledContent("calculator.details.version", value: "\(result.trace.engineVersion)") }
            }
            .navigationTitle("calculator.details")
            .toolbar { ToolbarItem(placement: .confirmationAction) { Button("common.done") { dismiss() } } }
        }
    }
}
