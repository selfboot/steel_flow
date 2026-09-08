import XCTest
@testable import SteelFlow

final class ProfileSectionPreviewTests: XCTestCase {
    private let cases: [(ProfileKind, [DimensionField: Double])] = [
        (.plate, [.width: 100, .thickness: 10]),
        (.roundBar, [.diameter: 20]),
        (.squareBar, [.side: 20]),
        (.hexBar, [.acrossFlats: 20]),
        (.octagonalBar, [.acrossFlats: 20]),
        (.roundTube, [.outerDiameter: 60.3, .wallThickness: 3.2]),
        (.squareTube, [.outerSide: 50, .wallThickness: 3]),
        (.rectangularTube, [.width: 80, .height: 40, .wallThickness: 3]),
        (.angle, [.width: 50, .height: 50, .wallThickness: 5]),
        (.channel, [.height: 100, .flangeWidth: 50, .webThickness: 5, .flangeThickness: 7]),
        (.iSection, [.height: 200, .flangeWidth: 100, .webThickness: 6, .flangeThickness: 9]),
        (.tSection, [.height: 100, .flangeWidth: 50, .webThickness: 5, .flangeThickness: 7]),
        (.customArea, [.customArea: 1_000])
    ]

    func testEveryProfilePreviewMatchesCalculationCrossSectionArea() throws {
        for (profile, values) in cases {
            let geometry = GeometryInput(values: values, lengthUnit: .millimeter, areaUnit: .squareMillimeter)
            let expected = try CalculationEngine.area(for: profile, geometry: geometry).0
            let model = try XCTUnwrap(SectionPreviewModel.make(profile: profile, geometry: geometry), "Missing preview for \(profile)")
            XCTAssertEqual(model.polygonArea, expected, accuracy: max(expected * 0.001, 1e-12), "Area mismatch for \(profile)")
        }
    }

    func testEveryEnteredCrossSectionLengthHasAnExactDimensionGuide() throws {
        for (profile, values) in cases {
            let geometry = GeometryInput(values: values, lengthUnit: .millimeter, areaUnit: .squareMillimeter)
            let model = try XCTUnwrap(SectionPreviewModel.make(profile: profile, geometry: geometry))
            XCTAssertEqual(Set(model.dimensionGuides.map(\.field)), Set(profile.dimensionFields), "Missing guide for \(profile)")

            for guide in model.dimensionGuides where guide.field != .customArea {
                let expected = try XCTUnwrap(geometry.meters(guide.field))
                let represented = Double(hypot(guide.end.x - guide.start.x, guide.end.y - guide.start.y))
                XCTAssertEqual(represented, expected, accuracy: 1e-12, "Incorrect guide length for \(profile).\(guide.field)")
            }
        }
    }

    func testTubePreviewsExposeTheirInteriorWalls() throws {
        for profile in [ProfileKind.roundTube, .squareTube, .rectangularTube] {
            let values = try XCTUnwrap(cases.first(where: { $0.0 == profile })?.1)
            let model = try XCTUnwrap(SectionPreviewModel.make(
                profile: profile,
                geometry: GeometryInput(values: values, lengthUnit: .millimeter)
            ))
            XCTAssertEqual(model.contours.filter(\.isHole).count, 1, "Missing hollow contour for \(profile)")
        }
    }

    func testCustomAreaUsesAnEqualAreaSquare() throws {
        let geometry = GeometryInput(
            values: [.customArea: 2_500],
            lengthUnit: .millimeter,
            areaUnit: .squareMillimeter
        )
        let model = try XCTUnwrap(SectionPreviewModel.make(profile: .customArea, geometry: geometry))
        XCTAssertTrue(model.usesEquivalentSquare)
        XCTAssertEqual(model.polygonArea, 0.0025, accuracy: 1e-12)
        XCTAssertEqual(model.bounds.width, model.bounds.height, accuracy: 1e-12)
    }

    func testLengthProjectionIsMonotonicCompressedAndBounded() {
        let short = SectionPreviewLengthScale.projectedUnits(lengthMeters: 0.2, sectionMaximumDimension: 0.1)
        let medium = SectionPreviewLengthScale.projectedUnits(lengthMeters: 2, sectionMaximumDimension: 0.1)
        let long = SectionPreviewLengthScale.projectedUnits(lengthMeters: 20, sectionMaximumDimension: 0.1)
        XCTAssertLessThan(short, medium)
        XCTAssertLessThan(medium, long)
        XCTAssertLessThanOrEqual(long, 9)
        XCTAssertEqual(SectionPreviewLengthScale.projectedUnits(lengthMeters: 0, sectionMaximumDimension: 0.1), 0.8)
    }

    func testInvalidGeometryDoesNotCreateAMisleadingPreview() {
        let impossibleTube = GeometryInput(
            values: [.outerDiameter: 20, .wallThickness: 10],
            lengthUnit: .millimeter
        )
        XCTAssertNil(SectionPreviewModel.make(profile: .roundTube, geometry: impossibleTube))
    }

    func testPreviewInputPreservesTheEnteredLengthLabel() throws {
        let input = try XCTUnwrap(ProfilePreviewInput.make(
            profile: .plate,
            geometry: GeometryInput(values: [.width: 100, .thickness: 10], lengthUnit: .millimeter),
            lengthValue: 6,
            lengthUnit: .meter,
            locale: Locale(identifier: "en_US")
        ))
        XCTAssertEqual(input.lengthMeters, 6, accuracy: 1e-12)
        XCTAssertEqual(input.lengthLabel, "6 m")
        XCTAssertEqual(input.dimensions.count, 2)
    }
}
