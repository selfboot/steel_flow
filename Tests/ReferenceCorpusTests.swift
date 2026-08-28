import XCTest
@testable import SteelFlow

final class ReferenceCorpusTests: XCTestCase {
    private struct ReferenceCase: Decodable {
        let id: String
        let profile: String
        let dimensions: [String: Double]
        let geometryUnit: String
        let areaUnit: String
        let lengthValue: Double
        let lengthUnit: String
        let quantity: Int
        let densityKgPerM3: Double
        let wastePercent: Double
        let expectedAreaSquareMeters: Double
        let expectedTotalMassKg: Double
        let tolerance: Double
    }

    func testVersionedReferenceCorpus() throws {
        let url = try XCTUnwrap(Bundle(for: Self.self).url(forResource: "ReferenceCases", withExtension: "json"))
        let cases = try JSONDecoder().decode([ReferenceCase].self, from: Data(contentsOf: url))
        XCTAssertEqual(cases.count, 100)

        for reference in cases {
            let profile = try XCTUnwrap(ProfileKind(rawValue: reference.profile), reference.id)
            let geometryUnit = try XCTUnwrap(corpusLengthUnit(reference.geometryUnit), reference.id)
            let areaUnit = try XCTUnwrap(corpusAreaUnit(reference.areaUnit), reference.id)
            let lengthUnit = try XCTUnwrap(corpusLengthUnit(reference.lengthUnit), reference.id)
            let dimensions = Dictionary(uniqueKeysWithValues: try reference.dimensions.map { key, value in
                (try XCTUnwrap(DimensionField(rawValue: key), reference.id), value)
            })
            let result = try CalculationEngine.calculate(.init(
                profile: profile,
                geometry: .init(values: dimensions, lengthUnit: geometryUnit, areaUnit: areaUnit),
                lengthValue: reference.lengthValue,
                lengthUnit: lengthUnit,
                quantity: reference.quantity,
                densityKgPerM3: reference.densityKgPerM3,
                wastePercent: reference.wastePercent
            ))
            XCTAssertEqual(result.areaSquareMeters, reference.expectedAreaSquareMeters, accuracy: reference.tolerance, reference.id)
            XCTAssertEqual(result.totalMassKg, reference.expectedTotalMassKg, accuracy: reference.tolerance, reference.id)
        }
    }

    private func corpusLengthUnit(_ value: String) -> LengthUnit? {
        switch value {
        case "millimeter": .millimeter
        case "centimeter": .centimeter
        case "meter": .meter
        case "inch": .inch
        case "foot": .foot
        default: LengthUnit(rawValue: value)
        }
    }

    private func corpusAreaUnit(_ value: String) -> AreaUnit? {
        switch value {
        case "squareMillimeter": .squareMillimeter
        case "squareCentimeter": .squareCentimeter
        case "squareMeter": .squareMeter
        case "squareInch": .squareInch
        default: AreaUnit(rawValue: value)
        }
    }
}
