import Foundation

enum ProfileKind: String, Codable, CaseIterable, Identifiable, Sendable {
    case plate
    case roundBar
    case squareBar
    case hexBar
    case octagonalBar
    case roundTube
    case squareTube
    case rectangularTube
    case angle
    case channel
    case iSection
    case tSection
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
        case .octagonalBar: "octagon.fill"
        case .roundTube: "circle.circle"
        case .squareTube: "square.dashed"
        case .rectangularTube: "rectangle.dashed"
        case .angle: "angle"
        case .channel: "square.split.2x1"
        case .iSection: "i.square"
        case .tSection: "t.square"
        case .customArea: "scribble.variable"
        }
    }

    var dimensionFields: [DimensionField] {
        switch self {
        case .plate: [.width, .thickness]
        case .roundBar: [.diameter]
        case .squareBar: [.side]
        case .hexBar: [.acrossFlats]
        case .octagonalBar: [.acrossFlats]
        case .roundTube: [.outerDiameter, .wallThickness]
        case .squareTube: [.outerSide, .wallThickness]
        case .rectangularTube: [.width, .height, .wallThickness]
        case .angle: [.width, .height, .wallThickness]
        case .channel: [.height, .flangeWidth, .webThickness, .flangeThickness]
        case .iSection: [.height, .flangeWidth, .webThickness, .flangeThickness]
        case .tSection: [.height, .flangeWidth, .webThickness, .flangeThickness]
        case .customArea: [.customArea]
        }
    }

    var usesIdealizedGeometry: Bool {
        switch self {
        case .squareTube, .rectangularTube, .angle, .channel, .iSection, .tSection: true
        default: false
        }
    }

    var summaryKey: LocalizedStringResource {
        LocalizedStringResource(stringLiteral: "profile.\(rawValue).summary")
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

    private enum CodingKeys: String, CodingKey {
        case values
        case lengthUnit
        case areaUnit
    }

    init(values: [DimensionField: Double] = [:], lengthUnit: LengthUnit = .millimeter, areaUnit: AreaUnit = .squareMillimeter) {
        self.values = values
        self.lengthUnit = lengthUnit
        self.areaUnit = areaUnit
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        lengthUnit = try container.decode(LengthUnit.self, forKey: .lengthUnit)
        areaUnit = try container.decode(AreaUnit.self, forKey: .areaUnit)

        if let stableValues = try? container.decode([String: Double].self, forKey: .values) {
            var decoded: [DimensionField: Double] = [:]
            for (rawKey, value) in stableValues {
                guard let key = DimensionField(rawValue: rawKey) else {
                    throw DecodingError.dataCorruptedError(
                        forKey: .values,
                        in: container,
                        debugDescription: "Unknown geometry dimension: \(rawKey)"
                    )
                }
                decoded[key] = value
            }
            values = decoded
        } else {
            // Compatibility with v1 records synthesized by Swift, which encoded
            // enum-keyed dictionaries as an alternating unkeyed array.
            values = try container.decode([DimensionField: Double].self, forKey: .values)
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        let stableValues = Dictionary(uniqueKeysWithValues: values.map { ($0.key.rawValue, $0.value) })
        try container.encode(stableValues, forKey: .values)
        try container.encode(lengthUnit, forKey: .lengthUnit)
        try container.encode(areaUnit, forKey: .areaUnit)
    }

    func meters(_ field: DimensionField) -> Double? {
        guard let value = values[field] else { return nil }
        return lengthUnit.toMeters(value)
    }
}
