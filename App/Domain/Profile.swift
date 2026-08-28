import Foundation

enum ProfileKind: String, Codable, CaseIterable, Identifiable, Sendable {
    case plate
    case roundBar
    case squareBar
    case hexBar
    case roundTube
    case squareTube
    case rectangularTube
    case angle
    case channel
    case iSection
    case customArea

    var id: String { rawValue }

    var localizationKey: LocalizedStringResource {
        LocalizedStringResource(stringLiteral: "profile.\(rawValue)")
    }

    var symbol: String {
        switch self {
        case .plate: "rectangle.fill"
        case .roundBar: "circle.fill"
        case .squareBar: "square.fill"
        case .hexBar: "hexagon.fill"
        case .roundTube: "circle.circle"
        case .squareTube: "square.dashed"
        case .rectangularTube: "rectangle.dashed"
        case .angle: "angle"
        case .channel: "square.split.2x1"
        case .iSection: "i.square"
        case .customArea: "scribble.variable"
        }
    }

    var dimensionFields: [DimensionField] {
        switch self {
        case .plate: [.width, .thickness]
        case .roundBar: [.diameter]
        case .squareBar: [.side]
        case .hexBar: [.acrossFlats]
        case .roundTube: [.outerDiameter, .wallThickness]
        case .squareTube: [.outerSide, .wallThickness]
        case .rectangularTube: [.width, .height, .wallThickness]
        case .angle: [.width, .height, .wallThickness]
        case .channel: [.height, .flangeWidth, .webThickness, .flangeThickness]
        case .iSection: [.height, .flangeWidth, .webThickness, .flangeThickness]
        case .customArea: [.customArea]
        }
    }

    var usesIdealizedGeometry: Bool {
        switch self {
        case .squareTube, .rectangularTube, .angle, .channel, .iSection: true
        default: false
        }
    }
}

enum DimensionField: String, Codable, CaseIterable, Identifiable, Sendable {
    case width
    case height
    case thickness
    case diameter
    case side
    case acrossFlats
    case outerDiameter
    case outerSide
    case wallThickness
    case flangeWidth
    case webThickness
    case flangeThickness
    case customArea

    var id: String { rawValue }
    var localizationKey: LocalizedStringResource {
        LocalizedStringResource(stringLiteral: "dimension.\(rawValue)")
    }
}

struct GeometryInput: Codable, Hashable, Sendable {
    var values: [DimensionField: Double]
    var lengthUnit: LengthUnit
    var areaUnit: AreaUnit

    init(values: [DimensionField: Double] = [:], lengthUnit: LengthUnit = .millimeter, areaUnit: AreaUnit = .squareMillimeter) {
        self.values = values
        self.lengthUnit = lengthUnit
        self.areaUnit = areaUnit
    }

    func meters(_ field: DimensionField) -> Double? {
        guard let value = values[field] else { return nil }
        return lengthUnit.toMeters(value)
    }
}
