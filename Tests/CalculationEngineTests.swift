import XCTest
@testable import SteelFlow

final class CalculationEngineTests: XCTestCase {
    func testGeometryEncodingIsCanonicalAndDecodesLegacyRecords() throws {
        let first = GeometryInput(values: [.width: 100, .thickness: 10], lengthUnit: .millimeter)
        let second = GeometryInput(values: [.thickness: 10, .width: 100], lengthUnit: .millimeter)
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        XCTAssertEqual(try encoder.encode(first), try encoder.encode(second))

        let legacy = Data(#"{"values":["width",100,"thickness",10],"lengthUnit":"mm","areaUnit":"mm²"}"#.utf8)
        XCTAssertEqual(try JSONDecoder().decode(GeometryInput.self, from: legacy), first)
    }

    private let density = 7_850.0

    func testAllProfileAreas() throws {
        let cases: [(ProfileKind, [DimensionField: Double], Double)] = [
            (.plate, [.width: 100, .thickness: 10], 0.1 * 0.01),
            (.roundBar, [.diameter: 20], .pi * pow(0.02, 2) / 4),
            (.squareBar, [.side: 20], pow(0.02, 2)),
            (.hexBar, [.acrossFlats: 20], sqrt(3) * pow(0.02, 2) / 2),
            (.octagonalBar, [.acrossFlats: 20], 2 * (sqrt(2) - 1) * pow(0.02, 2)),
            (.roundTube, [.outerDiameter: 60.3, .wallThickness: 3.2], .pi * (pow(0.0603, 2) - pow(0.0539, 2)) / 4),
            (.squareTube, [.outerSide: 50, .wallThickness: 3], pow(0.05, 2) - pow(0.044, 2)),
            (.rectangularTube, [.width: 80, .height: 40, .wallThickness: 3], 0.08 * 0.04 - 0.074 * 0.034),
            (.angle, [.width: 50, .height: 50, .wallThickness: 5], 0.05 * 0.005 + 0.05 * 0.005 - 0.005 * 0.005),
            (.channel, [.height: 100, .flangeWidth: 50, .webThickness: 5, .flangeThickness: 7], 2 * 0.05 * 0.007 + 0.086 * 0.005),
            (.iSection, [.height: 200, .flangeWidth: 100, .webThickness: 6, .flangeThickness: 9], 2 * 0.1 * 0.009 + 0.182 * 0.006),
            (.tSection, [.height: 100, .flangeWidth: 50, .webThickness: 5, .flangeThickness: 7], 0.05 * 0.007 + 0.093 * 0.005),
            (.customArea, [.customArea: 1_000], 0.001)
        ]

        for (profile, dimensions, expected) in cases {
            let geometry = GeometryInput(values: dimensions, lengthUnit: .millimeter, areaUnit: .squareMillimeter)
            let area = try CalculationEngine.area(for: profile, geometry: geometry).0
            XCTAssertEqual(area, expected, accuracy: 1e-12, "Failed profile: \(profile)")
        }
    }

    func testPlateReferenceMass() throws {
        let result = try calculate(.plate, [.width: 100, .thickness: 10], length: 6)
        XCTAssertEqual(result.areaSquareMeters, 0.001, accuracy: 1e-12)
        XCTAssertEqual(result.unitMassKg, 47.1, accuracy: 1e-9)
        XCTAssertEqual(result.totalMassKg, 47.1, accuracy: 1e-9)
    }

    @MainActor
    func testEveryProfileDefaultDraftProducesAValidCalculation() throws {
        for profile in ProfileKind.allCases {
            let draft = CalculatorDraft(profile: profile)
            let result = try XCTUnwrap(draft.result(locale: Locale(identifier: "en_US")), "Missing result for \(profile)")
            switch result {
            case .success(let calculation):
                XCTAssertGreaterThan(calculation.areaSquareMeters, 0, "Invalid default area for \(profile)")
            case .failure(let error):
                XCTFail("Default inputs failed for \(profile): \(error)")
            }
        }
    }

    func testBuiltInMaterialDensitiesRemainWithinVerifiedTypicalReferences() throws {
        let presets = Dictionary(uniqueKeysWithValues: MaterialCatalog.presets.map { ($0.id, $0.densityKgPerM3) })
        XCTAssertEqual(presets.count, MaterialCatalog.presets.count)
        XCTAssertEqual(try XCTUnwrap(presets["carbon-steel"]), 7_850)
        XCTAssertEqual(try XCTUnwrap(presets["stainless-304"]), 7_930)
        XCTAssertEqual(try XCTUnwrap(presets["stainless-316"]), 8_000)
        XCTAssertEqual(try XCTUnwrap(presets["aluminum"]), 2_700)
        XCTAssertEqual(try XCTUnwrap(presets["brass"]), 8_500)
        XCTAssertEqual(try XCTUnwrap(presets["copper"]), 8_960)
        XCTAssertEqual(try XCTUnwrap(presets["cast-iron"]), 7_200)
    }

    func testMetricAndImperialInputsAreEquivalent() throws {
        let metric = try CalculationEngine.calculate(.init(
            profile: .roundBar,
            geometry: .init(values: [.diameter: 25.4], lengthUnit: .millimeter),
            lengthValue: 3.048,
            lengthUnit: .meter,
            quantity: 4,
            densityKgPerM3: density,
            wastePercent: 5
        ))
        let imperial = try CalculationEngine.calculate(.init(
            profile: .roundBar,
            geometry: .init(values: [.diameter: 1], lengthUnit: .inch),
            lengthValue: 10,
            lengthUnit: .foot,
            quantity: 4,
            densityKgPerM3: density,
            wastePercent: 5
        ))
        XCTAssertEqual(metric.totalMassKg, imperial.totalMassKg, accuracy: 1e-10)
        XCTAssertEqual(metric.wasteAdjustedMassKg, imperial.wasteAdjustedMassKg, accuracy: 1e-10)
    }

    func testLengthRoundTripDoesNotDrift() {
        let meters = LengthUnit.millimeter.toMeters(25.4)
        XCTAssertEqual(LengthUnit.inch.fromMeters(meters), 1, accuracy: 1e-12)
        XCTAssertEqual(LengthUnit.millimeter.fromMeters(LengthUnit.inch.toMeters(1)), 25.4, accuracy: 1e-12)
    }

    @MainActor
    func testCustomAreaUnitConversionPreservesPhysicalArea() throws {
        let draft = CalculatorDraft(profile: .customArea)
        draft.dimensionTexts[.customArea] = "645.16"
        draft.convertArea(to: .squareInch, locale: Locale(identifier: "en_US"))
        XCTAssertEqual(draft.areaUnit, .squareInch)
        XCTAssertEqual(try XCTUnwrap(DecimalParser.double(draft.dimensionTexts[.customArea] ?? "", locale: Locale(identifier: "en_US"))), 1, accuracy: 1e-9)
        draft.convertArea(to: .squareMillimeter, locale: Locale(identifier: "en_US"))
        XCTAssertEqual(try XCTUnwrap(DecimalParser.double(draft.dimensionTexts[.customArea] ?? "", locale: Locale(identifier: "en_US"))), 645.16, accuracy: 1e-6)
    }

    func testWasteOnlyChangesAdjustedMass() throws {
        let base = try calculate(.squareBar, [.side: 20], length: 6, waste: 0)
        let wasted = try calculate(.squareBar, [.side: 20], length: 6, waste: 12.5)
        XCTAssertEqual(base.totalMassKg, wasted.totalMassKg, accuracy: 1e-12)
        XCTAssertEqual(wasted.wasteAdjustedMassKg, base.totalMassKg * 1.125, accuracy: 1e-12)
    }

    func testRejectsImpossibleTubeAndSectionGeometry() {
        XCTAssertThrowsError(try calculate(.roundTube, [.outerDiameter: 20, .wallThickness: 10], length: 1)) {
            XCTAssertEqual($0 as? CalculationError, .wallTooThick)
        }
        XCTAssertThrowsError(try calculate(.iSection, [.height: 20, .flangeWidth: 30, .webThickness: 3, .flangeThickness: 10], length: 1)) {
            XCTAssertEqual($0 as? CalculationError, .flangeTooThick)
        }
        XCTAssertThrowsError(try calculate(.channel, [.height: 100, .flangeWidth: 20, .webThickness: 21, .flangeThickness: 5], length: 1)) {
            XCTAssertEqual($0 as? CalculationError, .webTooThick)
        }
        XCTAssertThrowsError(try calculate(.iSection, [.height: 100, .flangeWidth: 20, .webThickness: 21, .flangeThickness: 5], length: 1)) {
            XCTAssertEqual($0 as? CalculationError, .webTooThick)
        }
        XCTAssertThrowsError(try calculate(.tSection, [.height: 20, .flangeWidth: 30, .webThickness: 3, .flangeThickness: 20], length: 1)) {
            XCTAssertEqual($0 as? CalculationError, .flangeTooThick)
        }
        XCTAssertThrowsError(try calculate(.tSection, [.height: 100, .flangeWidth: 20, .webThickness: 21, .flangeThickness: 5], length: 1)) {
            XCTAssertEqual($0 as? CalculationError, .webTooThick)
        }
    }

    func testRejectsMissingNegativeAndNonFiniteInputs() {
        XCTAssertThrowsError(try calculate(.plate, [.width: 100], length: 1))
        XCTAssertThrowsError(try calculate(.plate, [.width: -1, .thickness: 2], length: 1))
        XCTAssertThrowsError(try calculate(.plate, [.width: 1, .thickness: 2], length: .infinity))
    }

    func testQuantityAndDensityValidation() {
        let geometry = GeometryInput(values: [.side: 20], lengthUnit: .millimeter)
        XCTAssertThrowsError(try CalculationEngine.calculate(.init(profile: .squareBar, geometry: geometry, lengthValue: 1, lengthUnit: .meter, quantity: 0, densityKgPerM3: density, wastePercent: 0)))
        XCTAssertThrowsError(try CalculationEngine.calculate(.init(profile: .squareBar, geometry: geometry, lengthValue: 1, lengthUnit: .meter, quantity: 1, densityKgPerM3: 0, wastePercent: 0)))
    }

    func testTraceContainsEngineVersionAndNormalizedInputs() throws {
        let result = try calculate(.roundTube, [.outerDiameter: 60.3, .wallThickness: 3.2], length: 6)
        XCTAssertEqual(result.trace.engineVersion, CalculationEngine.version)
        XCTAssertEqual(result.trace.normalizedDimensions[DimensionField.outerDiameter.rawValue] ?? 0, 0.0603, accuracy: 1e-12)
        XCTAssertTrue(result.trace.formula.contains("OD"))
    }

    func testProfilesWithUnmodeledRadiiAreExplicitlyFlagged() {
        XCTAssertTrue(ProfileKind.squareTube.usesIdealizedGeometry)
        XCTAssertTrue(ProfileKind.angle.usesIdealizedGeometry)
        XCTAssertTrue(ProfileKind.channel.usesIdealizedGeometry)
        XCTAssertTrue(ProfileKind.iSection.usesIdealizedGeometry)
        XCTAssertTrue(ProfileKind.tSection.usesIdealizedGeometry)
        XCTAssertFalse(ProfileKind.roundBar.usesIdealizedGeometry)
        XCTAssertFalse(ProfileKind.roundTube.usesIdealizedGeometry)
    }

    private func calculate(_ profile: ProfileKind, _ dimensions: [DimensionField: Double], length: Double, waste: Double = 0) throws -> CalculationResult {
        try CalculationEngine.calculate(.init(
            profile: profile,
            geometry: .init(values: dimensions, lengthUnit: .millimeter),
            lengthValue: length,
            lengthUnit: .meter,
            quantity: 1,
            densityKgPerM3: density,
            wastePercent: waste
        ))
    }
}
