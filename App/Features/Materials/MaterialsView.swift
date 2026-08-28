import SwiftUI
import SwiftData

struct MaterialsView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.locale) private var locale
    @Query(sort: \MaterialEntity.densityKgPerM3) private var materials: [MaterialEntity]
    @Query(sort: \PriceBookEntryEntity.effectiveAt, order: .reverse) private var priceBook: [PriceBookEntryEntity]
    @State private var editingMaterial: MaterialEntity?
    @State private var showNew = false
    @State private var showNewPrice = false
    @State private var editingPrice: PriceBookEntryEntity?
    @State private var showProLimit = false
    @State private var purchaseManager = PurchaseManager.shared
    @State private var pendingDeletion: CatalogDeletion?
    @State private var showDeleteConfirmation = false

    var body: some View {
        List {
            Section("materials.built_in") {
                ForEach(materials.filter(\.isBuiltIn)) { material in MaterialRow(material: material) }
            }
            Section("materials.custom") {
                if materials.filter({ !$0.isBuiltIn }).isEmpty {
                    Text("materials.custom.empty").foregroundStyle(.secondary)
                }
                ForEach(materials.filter { !$0.isBuiltIn }) { material in
                    Button { editingMaterial = material } label: { MaterialRow(material: material) }
                        .buttonStyle(.plain)
                        .swipeActions(allowsFullSwipe: false) {
                            Button(role: .destructive) {
                                pendingDeletion = .material(material)
                                showDeleteConfirmation = true
                            } label: { Label("common.delete", systemImage: "trash") }
                        }
                }
            }
            Section("price_book.title") {
                if priceBook.isEmpty { Text("price_book.empty").foregroundStyle(.secondary) }
                ForEach(priceBook) { entry in
                    Button { editingPrice = entry } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 3) {
                                Text(entry.name).font(.headline)
                                Text([entry.supplier, entry.region, entry.materialGrade].filter { !$0.isEmpty }.joined(separator: " · "))
                                    .font(.caption).foregroundStyle(.secondary).lineLimit(1)
                            }
                            Spacer()
                            VStack(alignment: .trailing) {
                                Text(AppFormatters.decimal(entry.unitPrice, currencyCode: entry.currencyCode, locale: locale)).font(.subheadline.monospacedDigit())
                                Text(entry.priceBasis.localizationKey).font(.caption).foregroundStyle(.secondary)
                            }
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
            Section { Text("material.note.typical").font(.caption).foregroundStyle(.secondary) }
        }
        .navigationTitle("tab.materials")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Menu {
                    Button("materials.add") { if purchaseManager.isPro { showNew = true } else { showProLimit = true } }
                    Button("price_book.add") { showNewPrice = true }
                } label: { Image(systemName: "plus") }
            }
        }
        .sheet(isPresented: $showNew) { MaterialEditorSheet() }
        .sheet(item: $editingMaterial) { MaterialEditorSheet(material: $0) }
        .sheet(isPresented: $showNewPrice) { PriceBookEditorSheet(materials: materials) }
        .sheet(item: $editingPrice) { PriceBookEditorSheet(entry: $0, materials: materials) }
        .alert("purchase.limit.title", isPresented: $showProLimit) { Button("common.ok", role: .cancel) {} } message: { Text("purchase.limit.materials") }
        .alert("delete.confirm.title", isPresented: $showDeleteConfirmation) {
            Button("common.delete", role: .destructive) { confirmDeletion() }
            Button("common.cancel", role: .cancel) { pendingDeletion = nil }
        } message: {
            Text("delete.confirm.message")
        }
    }

    @ViewBuilder
    private func MaterialRow(material: MaterialEntity) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 3) {
                if let key = material.nameKey { Text(LocalizedStringKey(key)).font(.headline) } else { Text(material.name).font(.headline) }
                Text(material.isBuiltIn ? "materials.preset" : "materials.custom.label").font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
            Text("\(AppFormatters.number(material.densityKgPerM3, maximumFractionDigits: 1, locale: locale)) kg/m³")
                .font(.subheadline.monospacedDigit())
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
    var entry: PriceBookEntryEntity?
    let materials: [MaterialEntity]
    @AppStorage("app.currency") private var defaultCurrency = "USD"
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
    private var validPrice: Decimal? { PricingInputValidator.nonnegative(price) }
    private var canSave: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && normalizedCurrency != nil && validPrice != nil
    }

    var body: some View {
        NavigationStack {
            Form {
                TextField("price_book.name", text: $name)
                Picker("calculator.material", selection: $materialID) {
                    Text("price_book.any_material").tag("")
                    ForEach(materials) { material in
                        Text(material.nameKey.map { String(localized: String.LocalizationValue($0)) } ?? material.name).tag(material.id)
                    }
                }
                TextField("calculator.material_grade", text: $grade)
                TextField("price_book.supplier", text: $supplier)
                TextField("calculator.price_region", text: $region)
                HStack {
                    Text("settings.currency")
                    Spacer()
                    TextField("USD", text: $currency).textInputAutocapitalization(.characters).multilineTextAlignment(.trailing)
                }
                Picker("calculator.price_basis", selection: $basis) { ForEach(PriceBasis.allCases) { Text($0.localizationKey).tag($0) } }
                HStack {
                    Text("calculator.unit_price")
                    Spacer()
                    TextField("0", text: $price).keyboardType(.decimalPad).multilineTextAlignment(.trailing)
                }
                Toggle("calculator.price_includes_tax", isOn: $includesTax)
                DatePicker("calculator.price_effective_date", selection: $effectiveAt, displayedComponents: .date)
                TextField("materials.note", text: $note, axis: .vertical)
                if normalizedCurrency == nil { Label("error.invalid_currency", systemImage: "exclamationmark.triangle.fill").foregroundStyle(.red) }
                if validPrice == nil { Label("error.invalid_pricing", systemImage: "exclamationmark.triangle.fill").foregroundStyle(.red) }
                Text("price_book.reference_disclaimer").font(.caption).foregroundStyle(.secondary)
            }
            .navigationTitle(entry == nil ? "price_book.add" : "price_book.edit")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("common.cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) { Button("common.save") { save() }.disabled(!canSave) }
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
    var material: MaterialEntity?
    @State private var name = ""
    @State private var density = "7850"
    @State private var note = ""
    @State private var validationError = false

    var body: some View {
        NavigationStack {
            Form {
                TextField("materials.name", text: $name)
                HStack {
                    Text("calculator.density")
                    Spacer()
                    TextField("7850", text: $density).keyboardType(.decimalPad).multilineTextAlignment(.trailing)
                    Text("kg/m³").foregroundStyle(.secondary)
                }
                TextField("materials.note", text: $note, axis: .vertical).lineLimit(3...6)
                Text("materials.density.help").font(.caption).foregroundStyle(.secondary)
            }
            .navigationTitle(material == nil ? "materials.add" : "materials.edit")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("common.cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) { Button("common.save") { save() }.disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty) }
            }
            .onAppear {
                guard let material else { return }
                name = material.name
                density = AppFormatters.number(material.densityKgPerM3, maximumFractionDigits: 2)
                note = material.note
            }
            .alert("materials.invalid_density", isPresented: $validationError) { Button("common.ok", role: .cancel) {} }
        }
    }

    private func save() {
        guard let value = DecimalParser.double(density), value.finitePositive, value < 100_000 else { validationError = true; return }
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
