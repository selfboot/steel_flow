import Foundation

enum UnitSystem: String, Codable, CaseIterable, Identifiable, Sendable {
    case metric
    case imperial

    var id: String { rawValue }
    var lengthUnit: LengthUnit { self == .metric ? .millimeter : .inch }
    var stockLengthUnit: LengthUnit { self == .metric ? .meter : .foot }
    var massUnit: MassUnit { self == .metric ? .kilogram : .pound }
    var localizationKey: LocalizedStringResource {
        self == .metric ? "unit_system.metric" : "unit_system.imperial"
    }
}

enum LengthUnit: String, Codable, CaseIterable, Identifiable, Sendable {
    case millimeter = "mm"
    case centimeter = "cm"
    case meter = "m"
    case inch = "in"
    case foot = "ft"

    var id: String { rawValue }
    var metersPerUnit: Double {
        switch self {
        case .millimeter: 0.001
        case .centimeter: 0.01
        case .meter: 1
        case .inch: 0.0254
        case .foot: 0.3048
        }
    }

    func toMeters(_ value: Double) -> Double { value * metersPerUnit }
    func fromMeters(_ value: Double) -> Double { value / metersPerUnit }
}

enum AreaUnit: String, Codable, CaseIterable, Identifiable, Sendable {
    case squareMillimeter = "mm²"
    case squareCentimeter = "cm²"
    case squareMeter = "m²"
    case squareInch = "in²"

    var id: String { rawValue }
    var squareMetersPerUnit: Double {
        switch self {
        case .squareMillimeter: 0.000_001
        case .squareCentimeter: 0.000_1
        case .squareMeter: 1
        case .squareInch: 0.000_645_16
        }
    }
}

enum MassUnit: String, Codable, CaseIterable, Identifiable, Sendable {
    case kilogram = "kg"
    case pound = "lb"

    var id: String { rawValue }
    var kilogramsPerUnit: Double { self == .kilogram ? 1 : 0.453_592_37 }
    func fromKilograms(_ value: Double) -> Double { value / kilogramsPerUnit }
}

enum PriceBasis: String, Codable, CaseIterable, Identifiable, Sendable {
    case perKilogram
    case perPound
    case perMeter
    case perFoot
    case perPiece

    var id: String { rawValue }
    var localizationKey: LocalizedStringResource {
        switch self {
        case .perKilogram: "price_basis.per_kg"
        case .perPound: "price_basis.per_lb"
        case .perMeter: "price_basis.per_m"
        case .perFoot: "price_basis.per_ft"
        case .perPiece: "price_basis.per_piece"
        }
    }
}

extension Double {
    var finitePositive: Bool { isFinite && self > 0 }
}
