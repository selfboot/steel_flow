import Foundation
import Observation

@MainActor
@Observable
final class CalculatorDraft {
    let profile: ProfileKind
    var dimensionTexts: [DimensionField: String]
    var geometryUnit: LengthUnit
    var areaUnit: AreaUnit
    var lengthText: String
    var lengthUnit: LengthUnit
    var quantity: Int
    var selectedMaterialID: String
    var densityText: String
    var wasteText: String
    var priceBasis: PriceBasis
    var unitPriceText: String
    var processingFeeText: String
    var otherFeeText: String
    var priceSource: PriceSource
    var priceSourceName: String
    var priceRegion: String
    var materialGrade: String
    var priceIncludesTax: Bool
    var priceEffectiveAt: Date
    var itemDescription: String
    var internalNote: String

    init(profile: ProfileKind, unitSystem: UnitSystem = .metric) {
        self.profile = profile
        self.geometryUnit = unitSystem.lengthUnit
        self.areaUnit = unitSystem == .metric ? .squareMillimeter : .squareInch
        self.lengthUnit = unitSystem.stockLengthUnit
        self.lengthText = unitSystem == .metric ? "6" : "20"
        self.quantity = 1
        self.selectedMaterialID = "carbon-steel"
        self.densityText = "7850"
        self.wasteText = "0"
        self.priceBasis = unitSystem == .metric ? .perKilogram : .perPound
        self.unitPriceText = "0"
        self.processingFeeText = "0"
        self.otherFeeText = "0"
        self.priceSource = .manual
        self.priceSourceName = ""
        self.priceRegion = ""
        self.materialGrade = ""
        self.priceIncludesTax = false
        self.priceEffectiveAt = .now
        self.itemDescription = ""
        self.internalNote = ""

        let defaults = Self.defaults(for: profile, system: unitSystem)
        self.dimensionTexts = defaults.mapValues { String($0) }
    }

    func geometry(locale: Locale) -> GeometryInput? {
        var values: [DimensionField: Double] = [:]
        for field in profile.dimensionFields {
            guard let text = dimensionTexts[field], let value = DecimalParser.double(text, locale: locale) else { return nil }
            values[field] = value
        }
        return GeometryInput(values: values, lengthUnit: geometryUnit, areaUnit: areaUnit)
    }

    func request(locale: Locale) -> CalculationRequest? {
        guard let geometry = geometry(locale: locale),
              let length = DecimalParser.double(lengthText, locale: locale),
              let density = DecimalParser.double(densityText, locale: locale),
              let waste = DecimalParser.double(wasteText, locale: locale) else { return nil }
        return .init(
            profile: profile,
            geometry: geometry,
            lengthValue: length,
            lengthUnit: lengthUnit,
            quantity: quantity,
            densityKgPerM3: density,
            wastePercent: waste
        )
    }

    func result(locale: Locale) -> Result<CalculationResult, CalculationError>? {
        guard let request = request(locale: locale) else { return nil }
        do { return .success(try CalculationEngine.calculate(request)) }
        catch let error as CalculationError { return .failure(error) }
        catch { return .failure(.nonFiniteResult) }
    }

    func makeItem(materialName: String, locale: Locale, sortIndex: Int) -> CalculationItemEntity? {
        guard let geometry = geometry(locale: locale),
              let length = DecimalParser.double(lengthText, locale: locale),
              let density = DecimalParser.double(densityText, locale: locale),
              let waste = DecimalParser.double(wasteText, locale: locale), waste >= 0, waste <= 1_000,
              let unitPrice = PricingInputValidator.nonnegative(unitPriceText, locale: locale),
              let processingFee = PricingInputValidator.nonnegative(processingFeeText, locale: locale),
              let otherFee = PricingInputValidator.nonnegative(otherFeeText, locale: locale) else { return nil }
        return CalculationItemEntity(
            profile: profile,
            geometry: geometry,
            materialID: selectedMaterialID,
            materialName: materialName,
            densityKgPerM3: density,
            lengthValue: length,
            lengthUnit: lengthUnit,
            quantity: quantity,
            wastePercent: waste,
            priceBasis: priceBasis,
            unitPrice: unitPrice,
            processingFee: processingFee,
            otherFee: otherFee,
            priceSource: priceSource,
            priceSourceName: priceSourceName,
            priceRegion: priceRegion,
            materialGrade: materialGrade,
            priceIncludesTax: priceIncludesTax,
            priceEffectiveAt: priceEffectiveAt,
            description: itemDescription,
            internalNote: internalNote,
            sortIndex: sortIndex
        )
    }

    func pricing(locale: Locale, result: CalculationResult, currencyCode: String) -> PricingResult? {
        guard let unitPrice = PricingInputValidator.nonnegative(unitPriceText, locale: locale),
              let processingFee = PricingInputValidator.nonnegative(processingFeeText, locale: locale),
              let otherFee = PricingInputValidator.nonnegative(otherFeeText, locale: locale),
              let length = DecimalParser.double(lengthText, locale: locale), length.finitePositive else { return nil }
        let subtotal = PricingCalculator.lineSubtotal(
            unitPrice: unitPrice,
            basis: priceBasis,
            result: result,
            lengthMeters: lengthUnit.toMeters(length),
            quantity: quantity,
            currencyCode: currencyCode
        )
        return PricingCalculator.total(
            subtotal: subtotal,
            processingFee: processingFee,
            otherFee: otherFee,
            markupPercent: 0,
            taxPercent: 0,
            currencyCode: currencyCode
        )
    }

    func apply(priceEntry: PriceBookEntryEntity) {
        unitPriceText = priceEntry.unitPrice.description
        priceBasis = priceEntry.priceBasis
        priceSource = .history
        priceSourceName = priceEntry.supplier.isEmpty ? priceEntry.name : priceEntry.supplier
        priceRegion = priceEntry.region
        materialGrade = priceEntry.materialGrade
        priceIncludesTax = priceEntry.includesTax
        priceEffectiveAt = priceEntry.effectiveAt
    }

    func apply(material: MaterialEntity) {
        selectedMaterialID = material.id
        densityText = AppFormatters.number(material.densityKgPerM3, maximumFractionDigits: 1)
    }

    func convertGeometry(to newUnit: LengthUnit, locale: Locale) {
        guard newUnit != geometryUnit else { return }
        for field in profile.dimensionFields where field != .customArea {
            guard let text = dimensionTexts[field], let value = DecimalParser.double(text, locale: locale) else { continue }
            let meters = geometryUnit.toMeters(value)
            dimensionTexts[field] = AppFormatters.number(newUnit.fromMeters(meters), maximumFractionDigits: 6, locale: locale)
        }
        geometryUnit = newUnit
    }

    func convertLength(to newUnit: LengthUnit, locale: Locale) {
        guard newUnit != lengthUnit, let value = DecimalParser.double(lengthText, locale: locale) else { return }
        lengthText = AppFormatters.number(newUnit.fromMeters(lengthUnit.toMeters(value)), maximumFractionDigits: 6, locale: locale)
        lengthUnit = newUnit
    }

    private static func defaults(for profile: ProfileKind, system: UnitSystem) -> [DimensionField: Double] {
        let metric: [DimensionField: Double]
        switch profile {
        case .plate: metric = [.width: 100, .thickness: 10]
        case .roundBar: metric = [.diameter: 20]
        case .squareBar: metric = [.side: 20]
        case .hexBar: metric = [.acrossFlats: 20]
        case .roundTube: metric = [.outerDiameter: 60.3, .wallThickness: 3.2]
        case .squareTube: metric = [.outerSide: 50, .wallThickness: 3]
        case .rectangularTube: metric = [.width: 80, .height: 40, .wallThickness: 3]
        case .angle: metric = [.width: 50, .height: 50, .wallThickness: 5]
        case .channel: metric = [.height: 100, .flangeWidth: 50, .webThickness: 5, .flangeThickness: 7]
        case .iSection: metric = [.height: 200, .flangeWidth: 100, .webThickness: 6, .flangeThickness: 9]
        case .customArea: return [.customArea: system == .metric ? 1_000 : 1.55]
        }
        guard system == .imperial else { return metric }
        return metric.mapValues { LengthUnit.inch.fromMeters(LengthUnit.millimeter.toMeters($0)) }
    }
}
