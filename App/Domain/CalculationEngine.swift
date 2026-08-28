import Foundation

enum CalculationError: Error, Equatable, Sendable {
    case missing(DimensionField)
    case invalid(DimensionField)
    case invalidLength
    case invalidQuantity
    case invalidDensity
    case wallTooThick
    case flangeTooThick
    case webTooThick
    case nonFiniteResult
}

struct CalculationRequest: Sendable {
    var profile: ProfileKind
    var geometry: GeometryInput
    var lengthValue: Double
    var lengthUnit: LengthUnit
    var quantity: Int
    var densityKgPerM3: Double
    var wastePercent: Double
}

struct CalculationResult: Sendable, Equatable {
    let areaSquareMeters: Double
    let volumeCubicMeters: Double
    let unitMassKg: Double
    let totalMassKg: Double
    let wasteAdjustedMassKg: Double
    let trace: CalculationTrace
}

struct CalculationTrace: Sendable, Equatable {
    let engineVersion: Int
    let formula: String
    let normalizedDimensions: [String: Double]
    let areaSquareMeters: Double
    let lengthMeters: Double
    let quantity: Int
    let densityKgPerM3: Double
}

enum CalculationEngine {
    static let version = 1

    static func calculate(_ request: CalculationRequest) throws -> CalculationResult {
        guard request.lengthValue.finitePositive else { throw CalculationError.invalidLength }
        guard (1...1_000_000).contains(request.quantity) else { throw CalculationError.invalidQuantity }
        guard request.densityKgPerM3.finitePositive else { throw CalculationError.invalidDensity }
        guard request.wastePercent.isFinite, request.wastePercent >= 0, request.wastePercent <= 1_000 else {
            throw CalculationError.nonFiniteResult
        }

        let (area, formula, normalized) = try area(for: request.profile, geometry: request.geometry)
        let lengthMeters = request.lengthUnit.toMeters(request.lengthValue)
        let unitVolume = area * lengthMeters
        let unitMass = unitVolume * request.densityKgPerM3
        let totalMass = unitMass * Double(request.quantity)
        let adjusted = totalMass * (1 + request.wastePercent / 100)
        guard [area, lengthMeters, unitVolume, unitMass, totalMass, adjusted].allSatisfy({ $0.isFinite && $0 >= 0 }) else {
            throw CalculationError.nonFiniteResult
        }

        let trace = CalculationTrace(
            engineVersion: version,
            formula: formula,
            normalizedDimensions: normalized,
            areaSquareMeters: area,
            lengthMeters: lengthMeters,
            quantity: request.quantity,
            densityKgPerM3: request.densityKgPerM3
        )
        return CalculationResult(
            areaSquareMeters: area,
            volumeCubicMeters: unitVolume * Double(request.quantity),
            unitMassKg: unitMass,
            totalMassKg: totalMass,
            wasteAdjustedMassKg: adjusted,
            trace: trace
        )
    }

    static func area(for profile: ProfileKind, geometry: GeometryInput) throws -> (Double, String, [String: Double]) {
        func value(_ field: DimensionField) throws -> Double {
            let raw: Double?
            if field == .customArea {
                raw = geometry.values[field].map { $0 * geometry.areaUnit.squareMetersPerUnit }
            } else {
                raw = geometry.meters(field)
            }
            guard let raw else { throw CalculationError.missing(field) }
            guard raw.finitePositive, raw <= 1_000 else { throw CalculationError.invalid(field) }
            return raw
        }

        var n: [String: Double] = [:]
        func put(_ field: DimensionField) throws -> Double {
            let v = try value(field)
            n[field.rawValue] = v
            return v
        }

        let area: Double
        let formula: String
        switch profile {
        case .plate:
            let w = try put(.width), t = try put(.thickness)
            area = w * t; formula = "A = width × thickness"
        case .roundBar:
            let d = try put(.diameter)
            area = .pi * d * d / 4; formula = "A = π × diameter² ÷ 4"
        case .squareBar:
            let s = try put(.side)
            area = s * s; formula = "A = side²"
        case .hexBar:
            let f = try put(.acrossFlats)
            area = sqrt(3) * f * f / 2; formula = "A = √3 × across-flats² ÷ 2"
        case .roundTube:
            let d = try put(.outerDiameter), t = try put(.wallThickness)
            guard 2 * t < d else { throw CalculationError.wallTooThick }
            area = .pi * (d * d - pow(d - 2 * t, 2)) / 4
            formula = "A = π × (OD² − ID²) ÷ 4"
        case .squareTube:
            let s = try put(.outerSide), t = try put(.wallThickness)
            guard 2 * t < s else { throw CalculationError.wallTooThick }
            area = s * s - pow(s - 2 * t, 2)
            formula = "A = outer² − inner²"
        case .rectangularTube:
            let w = try put(.width), h = try put(.height), t = try put(.wallThickness)
            guard 2 * t < min(w, h) else { throw CalculationError.wallTooThick }
            area = w * h - (w - 2 * t) * (h - 2 * t)
            formula = "A = W×H − (W−2t)(H−2t)"
        case .angle:
            let w = try put(.width), h = try put(.height), t = try put(.wallThickness)
            guard t < min(w, h) else { throw CalculationError.wallTooThick }
            area = w * t + h * t - t * t
            formula = "A = W×t + H×t − t²"
        case .channel:
            let h = try put(.height), f = try put(.flangeWidth), tw = try put(.webThickness), tf = try put(.flangeThickness)
            guard 2 * tf < h else { throw CalculationError.flangeTooThick }
            guard tw <= f else { throw CalculationError.webTooThick }
            area = 2 * f * tf + (h - 2 * tf) * tw
            formula = "A = 2×flange + web"
        case .iSection:
            let h = try put(.height), f = try put(.flangeWidth), tw = try put(.webThickness), tf = try put(.flangeThickness)
            guard 2 * tf < h else { throw CalculationError.flangeTooThick }
            guard tw <= f else { throw CalculationError.webTooThick }
            area = 2 * f * tf + (h - 2 * tf) * tw
            formula = "A = 2×flange + web"
        case .customArea:
            area = try put(.customArea)
            formula = "A = custom cross-sectional area"
        }

        guard area.finitePositive else { throw CalculationError.nonFiniteResult }
        return (area, formula, n)
    }
}
