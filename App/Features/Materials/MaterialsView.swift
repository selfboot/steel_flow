import SwiftUI
import SwiftData

struct MaterialsView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.locale) private var locale
    @Query(sort: \MaterialEntity.densityKgPerM3) private var materials: [MaterialEntity]
    @Query(sort: \PriceBookEntryEntity.effectiveAt, order: .reverse) private var priceBook: [PriceBookEntryEntity]
    @State private var search = ""
    @State private var catalog = 0
    @State private var pendingProAction: (() -> Void)?
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @AppStorage("workflow.favorite_materials") private var favoriteMaterials = ""
    @State private var editingMaterial: MaterialEntity?
    @State private var showNew = false
    @State private var showNewPrice = false
    @State private var editingPrice: PriceBookEntryEntity?
    @State private var paywallReason: ProPaywallReason?
    @State private var purchaseManager = PurchaseManager.shared
    @State private var pendingDeletion: CatalogDeletion?
    @State private var showDeleteConfirmation = false

    private var filteredMaterials: [MaterialEntity] {
        materials.filter { search.isEmpty || [$0.name, MaterialCatalog.localizedName(materialID: $0.id, fallback: $0.name, locale: locale)].contains { $0.localizedStandardContains(search) } }
            .sorted { a, b in
                let favoriteA = favoriteMaterials.split(separator: "|").contains(Substring(a.id))
                let favoriteB = favoriteMaterials.split(separator: "|").contains(Substring(b.id))
                return favoriteA != favoriteB ? favoriteA : a.densityKgPerM3 < b.densityKgPerM3
            }
    }
    private var filteredPrices: [PriceBookEntryEntity] {
        priceBook.filter { search.isEmpty || [$0.name, $0.supplier, $0.region, $0.materialGrade, $0.currencyCode].contains { $0.localizedStandardContains(search) } }
    }
    var body: some View {
        List {
            if (catalog == 0 ? filteredMaterials.isEmpty : filteredPrices.isEmpty) && !search.isEmpty {
                ContentUnavailableView.search(text: search)
                Button("ui.clear_search") { search = "" }
            }
            if catalog == 0 {
            Section("materials.built_in") {
                ForEach(filteredMaterials.filter(\.isBuiltIn)) { material in
                    MaterialRow(material: material).contextMenu {
                        Button("workflow.copy_material", systemImage: "doc.on.doc") {
                            if purchaseManager.isPro { copyMaterial(material) }
                            else { pendingProAction = { copyMaterial(material) }; paywallReason = .materials }
                        }
                        Button(isFavorite(material.id) ? "workflow.unpin" : "workflow.pin", systemImage: isFavorite(material.id) ? "pin.slash" : "pin") { toggleFavorite(material.id) }
                    }
                }
            }
            Section("materials.custom") {
                if search.isEmpty && materials.filter({ !$0.isBuiltIn }).isEmpty {
                    Text("materials.custom.empty").foregroundStyle(.secondary)
                }
                ForEach(filteredMaterials.filter { !$0.isBuiltIn }) { material in
                    Button { editingMaterial = material } label: { MaterialRow(material: material) }
                        .buttonStyle(.plain)
                        .contextMenu { Button(isFavorite(material.id) ? "workflow.unpin" : "workflow.pin", systemImage: "pin") { toggleFavorite(material.id) } }
                        .swipeActions(allowsFullSwipe: false) {
                            Button(role: .destructive) {
                                pendingDeletion = .material(material)
                                showDeleteConfirmation = true
                            } label: { Label("common.delete", systemImage: "trash") }
                        }
                }
            }
            Section { Text("material.note.typical").font(.caption).foregroundStyle(.secondary) }
            } else {
            Section("price_book.title") {
                if search.isEmpty && priceBook.isEmpty { Text("price_book.empty").foregroundStyle(.secondary) }
                ForEach(filteredPrices) { entry in
                    Button { editingPrice = entry } label: {
                        let layout = dynamicTypeSize.isAccessibilitySize ? AnyLayout(VStackLayout(alignment: .leading)) : AnyLayout(HStackLayout())
                        layout {
                            VStack(alignment: .leading, spacing: 3) {
                                Text(entry.name).font(.headline)
                                Text(PriceApplicability.description(profileRaw: entry.applicableProfile, geometryData: entry.applicableGeometry, locale: locale)).font(.caption).foregroundStyle(.secondary)
                                Text(AppFormatters.date(entry.effectiveAt, locale: locale)).font(.caption).foregroundStyle(.secondary)
                                if Date.now.timeIntervalSince(entry.effectiveAt) > 30 * 86400 { Label("workflow.old_price", systemImage: "clock.badge.exclamationmark").font(.caption).foregroundStyle(.orange) }
                                Text([entry.supplier, entry.region, entry.materialGrade].filter { !$0.isEmpty }.joined(separator: " · "))
                                    .font(.caption).foregroundStyle(.secondary).lineLimit(1)
                            }
                            .layoutPriority(1)
                            Spacer()
                            VStack(alignment: .trailing) {
                                Text(AppFormatters.decimal(entry.unitPrice, currencyCode: entry.currencyCode, locale: locale)).font(.subheadline.monospacedDigit())
                                Text(entry.priceBasis.localizationKey).font(.caption).foregroundStyle(.secondary)
                            }
                            .fixedSize(horizontal: true, vertical: false)
                        }
                    }
                    .buttonStyle(.plain)
                    .swipeActions(allowsFullSwipe: false) {
                        Button(role: .destructive) {
                            pendingDeletion = .price(entry)
                            showDeleteConfirmation = true
                        } label: { Label("common.delete", systemImage: "trash") }
                    }
                }
                Text("price_book.help").font(.caption).foregroundStyle(.secondary)
            }
            }
        }
        .safeAreaInset(edge: .top, spacing: 0) {
            Picker("tab.materials", selection: $catalog) { Text("tab.materials").tag(0); Text("price_book.title").tag(1) }
                .pickerStyle(.segmented).padding(.horizontal).padding(.vertical, 8).background(.bar)
        }
        .searchable(text: $search, placement: .navigationBarDrawer(displayMode: .always), prompt: catalog == 0 ? "ui.material_search" : "workflow.price_search")
        .onChange(of: catalog) { _, _ in search = "" }
        .navigationTitle("tab.materials")
        .modifier(RootTabLayout())
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    if catalog == 1 { showNewPrice = true }
                    else if purchaseManager.isPro { showNew = true }
                    else { pendingProAction = { showNew = true }; paywallReason = .materials }
                } label: { Label(catalog == 0 ? "materials.add" : "price_book.add", systemImage: "plus") }
            }
        }
        .sheet(isPresented: $showNew) { MaterialEditorSheet() }
        .sheet(item: $editingMaterial) { MaterialEditorSheet(material: $0) }
        .sheet(isPresented: $showNewPrice) { PriceBookEditorSheet(materials: materials) }
        .sheet(item: $editingPrice) { PriceBookEditorSheet(entry: $0, materials: materials) }
        .proPaywall(reason: $paywallReason) { let action = pendingProAction; pendingProAction = nil; action?() }
        .alert("delete.confirm.title", isPresented: $showDeleteConfirmation) {
            Button("common.delete", role: .destructive) { confirmDeletion() }
            Button("common.cancel", role: .cancel) { pendingDeletion = nil }
        } message: {
            Text("delete.confirm.message")
        }
    }

    private func copyMaterial(_ material: MaterialEntity) {
        let copy = MaterialEntity(name: MaterialCatalog.localizedName(materialID: material.id, fallback: material.name, locale: locale), densityKgPerM3: material.densityKgPerM3, note: material.note)
        modelContext.insert(copy)
        if PersistenceErrorCenter.shared.save(modelContext) { editingMaterial = copy }
    }

    private func isFavorite(_ id: String) -> Bool { favoriteMaterials.split(separator: "|").contains(Substring(id)) }

    private func toggleFavorite(_ id: String) {
        var ids = Set(favoriteMaterials.split(separator: "|").map(String.init))
        if ids.contains(id) { ids.remove(id) } else { ids.insert(id) }
        favoriteMaterials = ids.sorted().joined(separator: "|")
    }

    @ViewBuilder
    private func MaterialRow(material: MaterialEntity) -> some View {
        let layout = dynamicTypeSize.isAccessibilitySize ? AnyLayout(VStackLayout(alignment: .leading)) : AnyLayout(HStackLayout())
        layout {
            VStack(alignment: .leading, spacing: 3) {
                if let key = material.nameKey { Text(LocalizedStringKey(key)).font(.headline).lineLimit(2) } else { Text(material.name).font(.headline).lineLimit(2) }
                if isFavorite(material.id) { Label("workflow.pinned", systemImage: "pin.fill").font(.caption).foregroundStyle(.secondary) }
                Text(material.isBuiltIn ? "materials.preset" : "materials.custom.label").font(.caption).foregroundStyle(.secondary)
            }
            .layoutPriority(1)
            Spacer()
            Text("\(AppFormatters.number(material.densityKgPerM3, maximumFractionDigits: 1, locale: locale)) kg/m³")
                .font(.subheadline.monospacedDigit())
                .fixedSize(horizontal: true, vertical: false)
        }
        .padding(.vertical, 3)
        .contentShape(Rectangle())
    }

    private func confirmDeletion() {
        guard let pendingDeletion else { return }
        switch pendingDeletion {
        case .material(let material): modelContext.delete(material)
        case .price(let entry): modelContext.delete(entry)
        }
        _ = PersistenceErrorCenter.shared.save(modelContext)
        self.pendingDeletion = nil
    }
}

private enum CatalogDeletion {
    case material(MaterialEntity)
    case price(PriceBookEntryEntity)
}

private struct PriceBookEditorSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(\.locale) private var locale
    var entry: PriceBookEntryEntity?
    let materials: [MaterialEntity]
    @AppStorage("app.currency") private var defaultCurrency = "USD"
    @State private var clearScope = false
    @State private var needsReview = false
    @State private var name = ""
    @State private var materialID = ""
    @State private var grade = ""
    @State private var supplier = ""
    @State private var region = ""
    @State private var currency = "USD"
    @State private var basis = PriceBasis.perKilogram
    @State private var price = ""
    @State private var includesTax = false
    @State private var effectiveAt = Date.now
    @State private var note = ""

    private var normalizedCurrency: String? { CurrencyRules.normalizedCode(currency) }
    private var validPrice: Decimal? { PricingInputValidator.nonnegative(price, locale: locale) }
    private var canSave: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && normalizedCurrency != nil && validPrice != nil
    }

    var body: some View {
        NavigationStack {
            Form {
                LabeledEntry("price_book.name", text: $name)
                if let entry, entry.applicableProfile != nil {
                    Text(PriceApplicability.description(profileRaw: entry.applicableProfile, geometryData: entry.applicableGeometry, locale: locale)).font(.caption)
                    if let length = entry.applicableLengthMeters { Text(AppFormatters.number(length, locale: locale) + " m").font(.caption) }
                    Toggle("workflow.clear_scope", isOn: $clearScope)
                }
                if needsReview { Text("workflow.price_review").foregroundStyle(.orange); Button("workflow.confirm_price") { needsReview = false } }
                Picker("calculator.material", selection: $materialID) {
                    Text("price_book.any_material").tag("")
                    ForEach(materials) { material in
                        Text(material.nameKey.map { AppLocalization.text($0, locale: locale) } ?? material.name).tag(material.id)
                    }
                }
                LabeledEntry("calculator.material_grade", text: $grade)
                LabeledEntry("price_book.supplier", text: $supplier)
                LabeledEntry("calculator.price_region", text: $region)
                CurrencyPickerRow(selection: $currency)
                Picker("calculator.price_basis", selection: Binding(get: { basis }, set: { newBasis in
                    if let value = validPrice, let converted = PriceBasisConversion.convert(value, from: basis, to: newBasis) { price = converted.description.replacingOccurrences(of: ".", with: locale.decimalSeparator ?? ".") }
                    else if basis != newBasis && !price.isEmpty { needsReview = true }
                    basis = newBasis
                })) { ForEach(PriceBasis.allCases) { Text($0.localizationKey).tag($0) } }
                HStack {
                    Text("calculator.unit_price")
                    Spacer()
                    LabeledEntry("0", text: $price).keyboardType(.decimalPad).multilineTextAlignment(.trailing).frame(minHeight: 44)
                }
                Toggle("calculator.price_includes_tax", isOn: $includesTax)
                DatePicker("calculator.price_effective_date", selection: $effectiveAt, displayedComponents: .date)
                LabeledEntry("materials.note", text: $note, multiline: true)
                if normalizedCurrency == nil { Label("error.invalid_currency", systemImage: "exclamationmark.triangle.fill").foregroundStyle(.red) }
                if validPrice == nil { Label("error.invalid_pricing", systemImage: "exclamationmark.triangle.fill").foregroundStyle(.red) }
                Text("price_book.reference_disclaimer").font(.caption).foregroundStyle(.secondary)
            }
            .keyboardDismissSupport()
            .navigationTitle(entry == nil ? "price_book.add" : "price_book.edit")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("common.cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) { Button("common.save") { save() }.disabled(!canSave || needsReview) }
            }
            .onAppear { load() }
        }
    }

    private func load() {
        guard let entry else { currency = defaultCurrency; return }
        name = entry.name
        materialID = entry.materialID
        grade = entry.materialGrade
        supplier = entry.supplier
        region = entry.region
        currency = entry.currencyCode
        basis = entry.priceBasis
        price = entry.unitPriceText
        includesTax = entry.includesTax
        effectiveAt = entry.effectiveAt
        note = entry.note
    }

    private func save() {
        guard let currencyCode = normalizedCurrency, let unitPrice = validPrice else { return }
        let material = materials.first(where: { $0.id == materialID })
        if let entry {
            if clearScope { entry.applicableProfile = nil; entry.applicableGeometry = nil; entry.applicableLengthMeters = nil }
            entry.name = name.trimmingCharacters(in: .whitespacesAndNewlines)
            entry.materialID = materialID
            entry.materialName = material?.name ?? ""
            entry.materialGrade = grade
            entry.supplier = supplier
            entry.region = region
            entry.currencyCode = currencyCode
            entry.priceBasis = basis
            entry.unitPriceText = unitPrice.description
            entry.includesTax = includesTax
            entry.effectiveAt = effectiveAt
            entry.note = note
            entry.updatedAt = .now
        } else {
            modelContext.insert(PriceBookEntryEntity(
                name: name.trimmingCharacters(in: .whitespacesAndNewlines),
                materialID: materialID,
                materialName: material?.name ?? "",
                materialGrade: grade,
                supplier: supplier,
                region: region,
                currencyCode: currencyCode,
                priceBasis: basis,
                unitPrice: unitPrice,
                includesTax: includesTax,
                effectiveAt: effectiveAt,
                note: note
            ))
        }
        if PersistenceErrorCenter.shared.save(modelContext) { dismiss() }
    }
}

private struct MaterialEditorSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(\.locale) private var locale
    var material: MaterialEntity?
    @State private var name = ""
    @State private var density = "7850"
    @State private var note = ""
    private var validDensity: Bool { DecimalParser.double(density, locale: locale).map { $0.finitePositive && $0 < 100_000 } ?? false }

    var body: some View {
        NavigationStack {
            Form {
                LabeledEntry("materials.name", text: $name)
                HStack {
                    Text("calculator.density")
                    Spacer()
                    LabeledEntry("7850", text: $density).keyboardType(.decimalPad).multilineTextAlignment(.trailing).frame(minHeight: 44)
                    Text("kg/m³").foregroundStyle(.secondary)
                }
                LabeledEntry("materials.note", text: $note, multiline: true).lineLimit(3...6)
                if !validDensity { InlineIssue(key: "materials.invalid_density") }
                if name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { InlineIssue(key: "ui.name_required") }
                Text("materials.density.help").font(.caption).foregroundStyle(.secondary)
            }
            .keyboardDismissSupport()
            .navigationTitle(material == nil ? "materials.add" : "materials.edit")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("common.cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) { Button("common.save") { save() }.disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || !validDensity) }
            }
            .onAppear {
                guard let material else { return }
                name = material.name
                density = AppFormatters.number(material.densityKgPerM3, maximumFractionDigits: 2, locale: locale)
                note = material.note
            }

        }
    }

    private func save() {
        guard let value = DecimalParser.double(density, locale: locale), value.finitePositive, value < 100_000 else { return }
        if let material {
            material.name = name.trimmingCharacters(in: .whitespacesAndNewlines)
            material.densityKgPerM3 = value
            material.note = note
            material.updatedAt = .now
        } else {
            modelContext.insert(MaterialEntity(name: name.trimmingCharacters(in: .whitespacesAndNewlines), densityKgPerM3: value, note: note))
        }
        if PersistenceErrorCenter.shared.save(modelContext) { dismiss() }
    }
}
