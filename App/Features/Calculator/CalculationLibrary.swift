import Foundation
import Observation

struct DraftState: Codable, Hashable, Sendable {
    var profile: ProfileKind
    var dimensions: [String: String]
    var geometryUnit: LengthUnit
    var areaUnit: AreaUnit
    var length: String
    var lengthUnit: LengthUnit
    var quantity: Int
    var materialID: String
    var density: String
    var waste: String
    var basis: PriceBasis
    var price: String
    var processing: String
    var other: String
    var source: PriceSource
    var sourceName: String
    var region: String
    var grade: String
    var includesTax: Bool
    var effectiveAt: Date
    var description: String
    var note: String
    var priceNeedsReview: Bool
    var currency: String
    var localeIdentifier: String

    @MainActor init(_ draft: CalculatorDraft, currency: String, locale: Locale) {
        profile = draft.profile; dimensions = Dictionary(uniqueKeysWithValues: draft.dimensionTexts.map { ($0.key.rawValue, $0.value) })
        geometryUnit = draft.geometryUnit; areaUnit = draft.areaUnit; length = draft.lengthText; lengthUnit = draft.lengthUnit
        quantity = draft.quantity; materialID = draft.selectedMaterialID; density = draft.densityText; waste = draft.wasteText
        basis = draft.priceBasis; price = draft.unitPriceText; processing = draft.processingFeeText; other = draft.otherFeeText
        source = draft.priceSource; sourceName = draft.priceSourceName; region = draft.priceRegion; grade = draft.materialGrade
        includesTax = draft.priceIncludesTax; effectiveAt = draft.priceEffectiveAt; description = draft.itemDescription; note = draft.internalNote
        priceNeedsReview = draft.priceNeedsReview; self.currency = currency; localeIdentifier = locale.identifier
    }

    @MainActor func makeDraft(locale: Locale) -> CalculatorDraft {
        let draft = CalculatorDraft(profile: profile)
        func text(_ raw: String) -> String {
            guard locale.identifier != localeIdentifier, let value = DecimalParser.parse(raw, locale: Locale(identifier: localeIdentifier)) else { return raw }
            return value.description.replacingOccurrences(of: ".", with: locale.decimalSeparator ?? ".")
        }
        draft.dimensionTexts = Dictionary(uniqueKeysWithValues: dimensions.compactMap { key, value in DimensionField(rawValue: key).map { ($0, text(value)) } })
        draft.geometryUnit = geometryUnit; draft.areaUnit = areaUnit; draft.lengthText = text(length); draft.lengthUnit = lengthUnit
        draft.quantity = quantity; draft.selectedMaterialID = materialID; draft.densityText = text(density); draft.wasteText = text(waste)
        draft.priceBasis = basis; draft.unitPriceText = text(price); draft.processingFeeText = text(processing); draft.otherFeeText = text(other)
        draft.priceSource = source; draft.priceSourceName = sourceName; draft.priceRegion = region; draft.materialGrade = grade
        draft.priceIncludesTax = includesTax; draft.priceEffectiveAt = effectiveAt; draft.itemDescription = description; draft.internalNote = note
        draft.priceNeedsReview = priceNeedsReview
        return draft
    }
}

struct SavedCalculation: Identifiable, Codable, Sendable {
    var id = UUID()
    var state: DraftState
    var createdAt = Date.now
    var isFavorite = false
}

struct CalculationLibraryPayload: Codable, Sendable {
    var records: [SavedCalculation] = []
    var drafts: [String: DraftState] = [:]
}

@MainActor @Observable
final class CalculationLibrary {
    static let shared = CalculationLibrary()
    private(set) var payload = CalculationLibraryPayload()
    private let defaults: UserDefaults
    private let key = "workflow.calculation_library.v1"
    var latestQuickDraft: DraftState? {
        guard let key = defaults.string(forKey: "ui.latest_quick_draft") else { return nil }
        return payload.drafts[key]
    }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
#if DEBUG
        if ProcessInfo.processInfo.arguments.contains("--reset-workflow") { defaults.removeObject(forKey: key); defaults.set(false, forKey: "workflow.show_pricing") }
#endif
        if let data = defaults.data(forKey: key), let stored = try? JSONDecoder().decode(CalculationLibraryPayload.self, from: data) { payload = stored }
    }
    var records: [SavedCalculation] { payload.records.sorted { $0.createdAt > $1.createdAt } }
    var exportData: Data? { try? JSONEncoder().encode(payload) }
    func saveDraft(_ state: DraftState, key: String) {
        payload.drafts[key] = state
        if key.hasPrefix("quick.") { defaults.set(key, forKey: "ui.latest_quick_draft") }
        if payload.drafts.count > 100, let old = payload.drafts.keys.sorted().first(where: { $0 != key }) { payload.drafts.removeValue(forKey: old) }
        persist()
    }
    func record(_ state: DraftState, favorite: Bool = false) {
        if let index = payload.records.firstIndex(where: { $0.state == state }) {
            payload.records[index].createdAt = .now
            if favorite { payload.records[index].isFavorite = true }
        } else { payload.records.append(SavedCalculation(state: state, isFavorite: favorite)) }
        let recent = payload.records.filter { !$0.isFavorite }.sorted { $0.createdAt > $1.createdAt }.prefix(100)
        payload.records = payload.records.filter(\.isFavorite) + recent
        persist()
    }
    func toggleFavorite(_ id: UUID) {
        guard let i = payload.records.firstIndex(where: { $0.id == id }) else { return }
        payload.records[i].isFavorite.toggle(); persist()
    }
    func remove(_ id: UUID) { payload.records.removeAll { $0.id == id }; persist() }
    func clear() { payload = .init(); persist() }
    func merge(_ data: Data) throws {
        let imported = try JSONDecoder().decode(CalculationLibraryPayload.self, from: data)
        guard imported.records.count <= 10_000, imported.drafts.count <= 100 else { throw BackupError.corrupt }
        for record in imported.records where !payload.records.contains(where: { $0.id == record.id }) { payload.records.append(record) }
        // Existing unfinished work wins over imported drafts.
        payload.drafts.merge(imported.drafts) { current, _ in current }
        persist()
    }
    private func persist() { if let data = exportData { defaults.set(data, forKey: key) } }
}

extension DraftState {
    @MainActor init(item: CalculationItemEntity, currency: String, locale: Locale) {
        let draft = CalculatorDraft(profile: item.profile)
        draft.dimensionTexts = item.geometry.values.mapValues { AppFormatters.number($0, maximumFractionDigits: 12, locale: locale) }
        draft.geometryUnit = item.geometry.lengthUnit; draft.areaUnit = item.geometry.areaUnit
        draft.lengthText = AppFormatters.number(item.lengthValue, maximumFractionDigits: 12, locale: locale); draft.lengthUnit = item.lengthUnit
        draft.quantity = item.quantity; draft.selectedMaterialID = item.materialID
        draft.densityText = AppFormatters.number(item.densityKgPerM3, maximumFractionDigits: 12, locale: locale)
        draft.wasteText = AppFormatters.number(item.wastePercent, maximumFractionDigits: 12, locale: locale)
        draft.priceBasis = item.priceBasis
        func localized(_ value: Decimal) -> String { value.description.replacingOccurrences(of: ".", with: locale.decimalSeparator ?? ".") }
        draft.unitPriceText = localized(item.unitPrice); draft.processingFeeText = localized(item.processingFee); draft.otherFeeText = localized(item.otherFee)
        draft.priceSource = item.priceSource; draft.priceSourceName = item.priceSourceName; draft.priceRegion = item.priceRegion
        draft.materialGrade = item.materialGrade; draft.priceIncludesTax = item.priceIncludesTax; draft.priceEffectiveAt = item.priceEffectiveAt ?? .now
        draft.itemDescription = item.descriptionText; draft.internalNote = item.internalNote
        self.init(draft, currency: currency, locale: locale)
    }
}
