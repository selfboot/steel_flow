import SwiftUI

struct ProfilePreviewInput: Equatable {
    let model: SectionPreviewModel
    let lengthMeters: Double
    let lengthLabel: String
    let dimensions: [ProfilePreviewDimension]

    static func make(
        profile: ProfileKind,
        geometry: GeometryInput,
        lengthValue: Double,
        lengthUnit: LengthUnit,
        locale: Locale
    ) -> ProfilePreviewInput? {
        guard lengthValue.finitePositive else { return nil }
        let lengthMeters = lengthUnit.toMeters(lengthValue)
        guard lengthMeters.finitePositive,
              let model = SectionPreviewModel.make(profile: profile, geometry: geometry) else { return nil }

        let dimensions = profile.dimensionFields.compactMap { field -> ProfilePreviewDimension? in
            guard let value = geometry.values[field] else { return nil }
            let unit = field == .customArea ? geometry.areaUnit.rawValue : geometry.lengthUnit.rawValue
            return ProfilePreviewDimension(
                field: field,
                valueLabel: "\(AppFormatters.number(value, maximumFractionDigits: 3, locale: locale)) \(unit)"
            )
        }

        return ProfilePreviewInput(
            model: model,
            lengthMeters: lengthMeters,
            lengthLabel: "\(AppFormatters.number(lengthValue, maximumFractionDigits: 3, locale: locale)) \(lengthUnit.rawValue)",
            dimensions: dimensions
        )
    }
}

struct ProfilePreviewDimension: Identifiable, Equatable {
    let field: DimensionField
    let valueLabel: String
    var id: DimensionField { field }

    var drawingLabel: String {
        "\(field.drawingSymbol) \(valueLabel)"
    }
}

private extension DimensionField {
    var drawingSymbol: String {
        switch self {
        case .width: "W"
        case .height: "H"
        case .thickness: "t"
        case .diameter: "Ø"
        case .side: "a"
        case .acrossFlats: "AF"
        case .outerDiameter: "OD"
        case .outerSide: "A"
        case .wallThickness: "t"
        case .flangeWidth: "B"
        case .webThickness: "tw"
        case .flangeThickness: "tf"
        case .customArea: "A"
        }
    }
}

struct SectionDimensionGuide: Equatable {
    enum Style: Equatable {
        case span
        case area
    }

    let field: DimensionField
    let start: CGPoint
    let end: CGPoint
    let lineOffset: CGVector
    let labelOffset: CGVector
    let style: Style
}

struct SectionPreviewModel: Equatable {
    struct Contour: Equatable {
        let points: [CGPoint]
        let isHole: Bool
    }

    let profile: ProfileKind
    let contours: [Contour]
    let dimensionGuides: [SectionDimensionGuide]
    let usesEquivalentSquare: Bool

    var bounds: CGRect {
        let points = contours.flatMap(\.points)
        guard let first = points.first else { return .zero }
        return points.dropFirst().reduce(CGRect(origin: first, size: .zero)) { partial, point in
            partial.union(CGRect(origin: point, size: .zero))
        }
    }

    var maximumDimension: Double {
        max(Double(bounds.width), Double(bounds.height))
    }

    var polygonArea: Double {
        contours.reduce(0) { sum, contour in
            let area = Self.signedArea(contour.points).magnitude
            return sum + (contour.isHole ? -area : area)
        }
    }

    static func make(profile: ProfileKind, geometry: GeometryInput) -> SectionPreviewModel? {
        guard (try? CalculationEngine.area(for: profile, geometry: geometry)) != nil else { return nil }

        func value(_ field: DimensionField) -> Double? {
            if field == .customArea {
                return geometry.values[field].map { $0 * geometry.areaUnit.squareMetersPerUnit }
            }
            return geometry.meters(field)
        }
        func rectangle(width: Double, height: Double, inset: Double = 0) -> Contour {
            Contour(points: [
                CGPoint(x: inset, y: inset),
                CGPoint(x: width - inset, y: inset),
                CGPoint(x: width - inset, y: height - inset),
                CGPoint(x: inset, y: height - inset)
            ], isHole: inset > 0)
        }
        func regularPolygon(sides: Int, acrossFlats: Double) -> Contour {
            let radius = acrossFlats / (2 * cos(.pi / Double(sides)))
            let startAngle = .pi / 2 - .pi / Double(sides)
            return Contour(points: (0..<sides).map { index in
                let angle = startAngle + 2 * .pi * Double(index) / Double(sides)
                return CGPoint(x: radius * cos(angle), y: radius * sin(angle))
            }, isHole: false)
        }
        func circle(diameter: Double, isHole: Bool) -> Contour {
            let radius = diameter / 2
            return Contour(points: (0..<96).map { index in
                let angle = 2 * .pi * Double(index) / 96
                return CGPoint(x: radius * cos(angle), y: radius * sin(angle))
            }, isHole: isHole)
        }
        func guide(
            _ field: DimensionField,
            _ start: CGPoint,
            _ end: CGPoint,
            lineOffset: CGVector = .zero,
            labelOffset: CGVector = .zero,
            style: SectionDimensionGuide.Style = .span
        ) -> SectionDimensionGuide {
            SectionDimensionGuide(
                field: field,
                start: start,
                end: end,
                lineOffset: lineOffset,
                labelOffset: labelOffset,
                style: style
            )
        }

        let contours: [Contour]
        let guides: [SectionDimensionGuide]
        var equivalentSquare = false
        switch profile {
        case .plate:
            guard let width = value(.width), let thickness = value(.thickness) else { return nil }
            contours = [rectangle(width: width, height: thickness)]
            guides = [
                guide(.width, CGPoint(x: 0, y: 0), CGPoint(x: width, y: 0), lineOffset: CGVector(dx: 0, dy: 14), labelOffset: CGVector(dx: 0, dy: 10)),
                guide(.thickness, CGPoint(x: 0, y: 0), CGPoint(x: 0, y: thickness), lineOffset: CGVector(dx: -15, dy: 0), labelOffset: CGVector(dx: -18, dy: 0))
            ]
        case .roundBar:
            guard let diameter = value(.diameter) else { return nil }
            contours = [circle(diameter: diameter, isHole: false)]
            guides = [guide(.diameter, CGPoint(x: -diameter / 2, y: 0), CGPoint(x: diameter / 2, y: 0), labelOffset: CGVector(dx: 0, dy: -12))]
        case .squareBar:
            guard let side = value(.side) else { return nil }
            contours = [rectangle(width: side, height: side)]
            guides = [guide(.side, CGPoint(x: 0, y: 0), CGPoint(x: side, y: 0), lineOffset: CGVector(dx: 0, dy: 14), labelOffset: CGVector(dx: 0, dy: 10))]
        case .hexBar:
            guard let flats = value(.acrossFlats) else { return nil }
            contours = [regularPolygon(sides: 6, acrossFlats: flats)]
            guides = [guide(.acrossFlats, CGPoint(x: 0, y: -flats / 2), CGPoint(x: 0, y: flats / 2), lineOffset: CGVector(dx: -12, dy: 0), labelOffset: CGVector(dx: -21, dy: 0))]
        case .octagonalBar:
            guard let flats = value(.acrossFlats) else { return nil }
            contours = [regularPolygon(sides: 8, acrossFlats: flats)]
            guides = [guide(.acrossFlats, CGPoint(x: 0, y: -flats / 2), CGPoint(x: 0, y: flats / 2), lineOffset: CGVector(dx: -12, dy: 0), labelOffset: CGVector(dx: -21, dy: 0))]
        case .roundTube:
            guard let diameter = value(.outerDiameter), let wall = value(.wallThickness) else { return nil }
            contours = [circle(diameter: diameter, isHole: false), circle(diameter: diameter - 2 * wall, isHole: true)]
            guides = [
                guide(.outerDiameter, CGPoint(x: -diameter / 2, y: 0), CGPoint(x: diameter / 2, y: 0), labelOffset: CGVector(dx: 0, dy: -12)),
                guide(.wallThickness, CGPoint(x: 0, y: diameter / 2 - wall), CGPoint(x: 0, y: diameter / 2), lineOffset: CGVector(dx: 13, dy: 0), labelOffset: CGVector(dx: 25, dy: -4))
            ]
        case .squareTube:
            guard let side = value(.outerSide), let wall = value(.wallThickness) else { return nil }
            contours = [rectangle(width: side, height: side), rectangle(width: side, height: side, inset: wall)]
            guides = [
                guide(.outerSide, CGPoint(x: 0, y: 0), CGPoint(x: side, y: 0), lineOffset: CGVector(dx: 0, dy: 14), labelOffset: CGVector(dx: 0, dy: 10)),
                guide(.wallThickness, CGPoint(x: 0, y: side / 2), CGPoint(x: wall, y: side / 2), labelOffset: CGVector(dx: 0, dy: -12))
            ]
        case .rectangularTube:
            guard let width = value(.width), let height = value(.height), let wall = value(.wallThickness) else { return nil }
            contours = [rectangle(width: width, height: height), rectangle(width: width, height: height, inset: wall)]
            guides = [
                guide(.width, CGPoint(x: 0, y: 0), CGPoint(x: width, y: 0), lineOffset: CGVector(dx: 0, dy: 14), labelOffset: CGVector(dx: 0, dy: 10)),
                guide(.height, CGPoint(x: 0, y: 0), CGPoint(x: 0, y: height), lineOffset: CGVector(dx: -14, dy: 0), labelOffset: CGVector(dx: -20, dy: 0)),
                guide(.wallThickness, CGPoint(x: 0, y: height / 2), CGPoint(x: wall, y: height / 2), labelOffset: CGVector(dx: 0, dy: -12))
            ]
        case .angle:
            guard let width = value(.width), let height = value(.height), let wall = value(.wallThickness) else { return nil }
            contours = [Contour(points: [
                CGPoint(x: 0, y: 0), CGPoint(x: width, y: 0), CGPoint(x: width, y: wall),
                CGPoint(x: wall, y: wall), CGPoint(x: wall, y: height), CGPoint(x: 0, y: height)
            ], isHole: false)]
            guides = [
                guide(.width, CGPoint(x: 0, y: 0), CGPoint(x: width, y: 0), lineOffset: CGVector(dx: 0, dy: 14), labelOffset: CGVector(dx: 0, dy: 10)),
                guide(.height, CGPoint(x: 0, y: 0), CGPoint(x: 0, y: height), lineOffset: CGVector(dx: -14, dy: 0), labelOffset: CGVector(dx: -20, dy: 0)),
                guide(.wallThickness, CGPoint(x: 0, y: wall), CGPoint(x: wall, y: wall), labelOffset: CGVector(dx: 7, dy: -12))
            ]
        case .channel:
            guard let height = value(.height), let flange = value(.flangeWidth),
                  let web = value(.webThickness), let flangeThickness = value(.flangeThickness) else { return nil }
            contours = [Contour(points: [
                CGPoint(x: 0, y: 0), CGPoint(x: flange, y: 0), CGPoint(x: flange, y: flangeThickness),
                CGPoint(x: web, y: flangeThickness), CGPoint(x: web, y: height - flangeThickness),
                CGPoint(x: flange, y: height - flangeThickness), CGPoint(x: flange, y: height), CGPoint(x: 0, y: height)
            ], isHole: false)]
            guides = [
                guide(.height, CGPoint(x: 0, y: 0), CGPoint(x: 0, y: height), lineOffset: CGVector(dx: -14, dy: 0), labelOffset: CGVector(dx: -20, dy: 0)),
                guide(.flangeWidth, CGPoint(x: 0, y: 0), CGPoint(x: flange, y: 0), lineOffset: CGVector(dx: 0, dy: 14), labelOffset: CGVector(dx: 0, dy: 10)),
                guide(.webThickness, CGPoint(x: 0, y: height / 2), CGPoint(x: web, y: height / 2), labelOffset: CGVector(dx: 8, dy: -12)),
                guide(.flangeThickness, CGPoint(x: flange, y: 0), CGPoint(x: flange, y: flangeThickness), lineOffset: CGVector(dx: 12, dy: 0), labelOffset: CGVector(dx: 27, dy: -15))
            ]
        case .iSection:
            guard let height = value(.height), let flange = value(.flangeWidth),
                  let web = value(.webThickness), let flangeThickness = value(.flangeThickness) else { return nil }
            let leftWeb = (flange - web) / 2
            let rightWeb = leftWeb + web
            contours = [Contour(points: [
                CGPoint(x: 0, y: 0), CGPoint(x: flange, y: 0), CGPoint(x: flange, y: flangeThickness),
                CGPoint(x: rightWeb, y: flangeThickness), CGPoint(x: rightWeb, y: height - flangeThickness),
                CGPoint(x: flange, y: height - flangeThickness), CGPoint(x: flange, y: height), CGPoint(x: 0, y: height),
                CGPoint(x: 0, y: height - flangeThickness), CGPoint(x: leftWeb, y: height - flangeThickness),
                CGPoint(x: leftWeb, y: flangeThickness), CGPoint(x: 0, y: flangeThickness)
            ], isHole: false)]
            guides = [
                guide(.height, CGPoint(x: 0, y: 0), CGPoint(x: 0, y: height), lineOffset: CGVector(dx: -14, dy: 0), labelOffset: CGVector(dx: -20, dy: 0)),
                guide(.flangeWidth, CGPoint(x: 0, y: 0), CGPoint(x: flange, y: 0), lineOffset: CGVector(dx: 0, dy: 14), labelOffset: CGVector(dx: 0, dy: 10)),
                guide(.webThickness, CGPoint(x: leftWeb, y: height / 2), CGPoint(x: rightWeb, y: height / 2), labelOffset: CGVector(dx: 0, dy: -12)),
                guide(.flangeThickness, CGPoint(x: flange, y: 0), CGPoint(x: flange, y: flangeThickness), lineOffset: CGVector(dx: 12, dy: 0), labelOffset: CGVector(dx: 27, dy: -15))
            ]
        case .tSection:
            guard let height = value(.height), let flange = value(.flangeWidth),
                  let web = value(.webThickness), let flangeThickness = value(.flangeThickness) else { return nil }
            let leftWeb = (flange - web) / 2
            let rightWeb = leftWeb + web
            contours = [Contour(points: [
                CGPoint(x: 0, y: 0), CGPoint(x: flange, y: 0), CGPoint(x: flange, y: flangeThickness),
                CGPoint(x: rightWeb, y: flangeThickness), CGPoint(x: rightWeb, y: height),
                CGPoint(x: leftWeb, y: height), CGPoint(x: leftWeb, y: flangeThickness), CGPoint(x: 0, y: flangeThickness)
            ], isHole: false)]
            guides = [
                guide(.height, CGPoint(x: 0, y: 0), CGPoint(x: 0, y: height), lineOffset: CGVector(dx: -14, dy: 0), labelOffset: CGVector(dx: -20, dy: 0)),
                guide(.flangeWidth, CGPoint(x: 0, y: 0), CGPoint(x: flange, y: 0), lineOffset: CGVector(dx: 0, dy: 14), labelOffset: CGVector(dx: 0, dy: 10)),
                guide(.webThickness, CGPoint(x: leftWeb, y: height * 0.7), CGPoint(x: rightWeb, y: height * 0.7), labelOffset: CGVector(dx: 0, dy: -12)),
                guide(.flangeThickness, CGPoint(x: flange, y: 0), CGPoint(x: flange, y: flangeThickness), lineOffset: CGVector(dx: 12, dy: 0), labelOffset: CGVector(dx: 27, dy: -15))
            ]
        case .customArea:
            guard let area = value(.customArea) else { return nil }
            let side = sqrt(area)
            contours = [rectangle(width: side, height: side)]
            guides = [guide(
                .customArea,
                CGPoint(x: side / 2, y: side / 2),
                CGPoint(x: side / 2, y: side / 2),
                labelOffset: CGVector(dx: 0, dy: -10),
                style: .area
            )]
            equivalentSquare = true
        }

        return SectionPreviewModel(
            profile: profile,
            contours: contours,
            dimensionGuides: guides,
            usesEquivalentSquare: equivalentSquare
        )
    }

    private static func signedArea(_ points: [CGPoint]) -> Double {
        guard points.count > 2 else { return 0 }
        return points.indices.reduce(0) { sum, index in
            let next = points[(index + 1) % points.count]
            return sum + Double(points[index].x * next.y - next.x * points[index].y)
        } / 2
    }
}

enum SectionPreviewLengthScale {
    static func projectedUnits(lengthMeters: Double, sectionMaximumDimension: Double) -> Double {
        guard lengthMeters.finitePositive, sectionMaximumDimension.finitePositive else { return 0.8 }
        let physicalRatio = lengthMeters / sectionMaximumDimension
        return min(max(pow(physicalRatio, 0.35), 0.8), 9)
    }
}

struct ProfileSection3DPreview: View {
    let input: ProfilePreviewInput
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Canvas { context, size in
                let projection = PreviewProjection(model: input.model, lengthMeters: input.lengthMeters, size: size)
                drawBody(context: &context, projection: projection)
                drawCrossSectionDimensions(context: &context, projection: projection)
                drawLength(context: &context, projection: projection)
            }
            .frame(height: 250)
            .background(
                LinearGradient(
                    colors: [Color.accentColor.opacity(colorScheme == .dark ? 0.13 : 0.08), Color.secondary.opacity(0.025)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                in: RoundedRectangle(cornerRadius: 16, style: .continuous)
            )

            LazyVGrid(
                columns: dynamicTypeSize.isAccessibilitySize ? [GridItem(.flexible())] : [GridItem(.adaptive(minimum: 118), alignment: .leading)],
                alignment: .leading,
                spacing: 8
            ) {
                ForEach(input.dimensions) { dimension in
                    HStack(spacing: 6) {
                        Text(dimension.field.localizationKey)
                            .foregroundStyle(.secondary)
                        Spacer(minLength: 4)
                        Text(dimension.valueLabel)
                            .fontWeight(.semibold)
                            .monospacedDigit()
                    }
                    .font(.caption)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 7)
                    .background(Color.secondary.opacity(0.08), in: Capsule())
                }
            }

            if input.model.usesEquivalentSquare {
                Label("preview.equivalent_square_note", systemImage: "info.circle")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Text("preview.scale_note")
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(Text("preview.accessibility_label"))
        .accessibilityValue(accessibilityValue)
        .accessibilityIdentifier("calculator.profile_preview")
    }

    private var accessibilityValue: Text {
        let values = input.dimensions.map(\.valueLabel).joined(separator: ", ")
        return Text("\(input.lengthLabel), \(values)")
    }

    private func drawBody(context: inout GraphicsContext, projection: PreviewProjection) {
        let backPath = facePath(projection: projection, back: true)
        context.fill(backPath, with: .color(Color.accentColor.opacity(0.24)), style: FillStyle(eoFill: true))

        for contour in input.model.contours {
            guard contour.points.count > 1 else { continue }
            for index in contour.points.indices {
                let next = (index + 1) % contour.points.count
                let frontStart = projection.front(contour.points[index])
                let frontEnd = projection.front(contour.points[next])
                let facing = (frontEnd.x - frontStart.x) * projection.depth.dy
                    - (frontEnd.y - frontStart.y) * projection.depth.dx
                let isVisible = contour.isHole ? facing < 0 : facing > 0
                guard isVisible else { continue }
                var side = Path()
                side.move(to: frontStart)
                side.addLine(to: projection.back(contour.points[index]))
                side.addLine(to: projection.back(contour.points[next]))
                side.addLine(to: frontEnd)
                side.closeSubpath()
                let shade = contour.isHole ? 0.30 : 0.46
                context.fill(side, with: .color(Color.accentColor.opacity(shade)))
                if contour.points.count <= 16 {
                    context.stroke(side, with: .color(Color.primary.opacity(0.16)), lineWidth: 0.7)
                }
            }
        }

        let frontPath = facePath(projection: projection, back: false)
        context.fill(frontPath, with: .color(Color.accentColor.opacity(colorScheme == .dark ? 0.72 : 0.62)), style: FillStyle(eoFill: true))
        for contour in input.model.contours {
            var outline = Path()
            guard let first = contour.points.first else { continue }
            outline.move(to: projection.front(first))
            contour.points.dropFirst().forEach { outline.addLine(to: projection.front($0)) }
            outline.closeSubpath()
            context.stroke(outline, with: .color(Color.primary.opacity(0.58)), lineWidth: contour.isHole ? 1.4 : 1.7)
        }
    }

    private func facePath(projection: PreviewProjection, back: Bool) -> Path {
        var path = Path()
        for contour in input.model.contours {
            guard let first = contour.points.first else { continue }
            let project = back ? projection.back : projection.front
            path.move(to: project(first))
            contour.points.dropFirst().forEach { path.addLine(to: project($0)) }
            path.closeSubpath()
        }
        return path
    }

    private func drawLength(context: inout GraphicsContext, projection: PreviewProjection) {
        let start = projection.dimensionStart
        let end = projection.dimensionEnd
        let color = Color.primary.opacity(0.70)
        var line = Path()
        line.move(to: start)
        line.addLine(to: end)
        context.stroke(line, with: .color(color), style: StrokeStyle(lineWidth: 1.2, dash: [4, 3]))

        drawArrowHead(context: &context, tip: start, toward: end, color: color)
        drawArrowHead(context: &context, tip: end, toward: start, color: color)

        let midpoint = CGPoint(x: (start.x + end.x) / 2, y: (start.y + end.y) / 2 + 13)
        context.draw(
            Text(input.lengthLabel).font(.caption.bold()).foregroundStyle(color),
            at: midpoint,
            anchor: .center
        )
    }

    private func drawCrossSectionDimensions(context: inout GraphicsContext, projection: PreviewProjection) {
        let color = Color.primary.opacity(0.82)
        for guide in input.model.dimensionGuides {
            guard let dimension = input.dimensions.first(where: { $0.field == guide.field }) else { continue }
            let startAnchor = projection.front(guide.start)
            let endAnchor = projection.front(guide.end)
            let start = CGPoint(x: startAnchor.x + guide.lineOffset.dx, y: startAnchor.y + guide.lineOffset.dy)
            let end = CGPoint(x: endAnchor.x + guide.lineOffset.dx, y: endAnchor.y + guide.lineOffset.dy)

            if guide.style == .span {
                if guide.lineOffset != .zero {
                    var extensions = Path()
                    extensions.move(to: startAnchor)
                    extensions.addLine(to: start)
                    extensions.move(to: endAnchor)
                    extensions.addLine(to: end)
                    context.stroke(extensions, with: .color(color.opacity(0.65)), lineWidth: 0.8)
                }

                var line = Path()
                line.move(to: start)
                line.addLine(to: end)
                context.stroke(line, with: .color(color), lineWidth: 1)
                drawArrowHead(context: &context, tip: start, toward: end, color: color, maximumLength: 5)
                drawArrowHead(context: &context, tip: end, toward: start, color: color, maximumLength: 5)
            }

            let midpoint = CGPoint(
                x: (start.x + end.x) / 2 + guide.labelOffset.dx,
                y: (start.y + end.y) / 2 + guide.labelOffset.dy
            )
            drawMeasurementLabel(dimension.drawingLabel, at: midpoint, context: &context, color: color)
        }
    }

    private func drawMeasurementLabel(
        _ label: String,
        at point: CGPoint,
        context: inout GraphicsContext,
        color: Color
    ) {
        let text = context.resolve(Text(label).font(.caption2.bold()).foregroundStyle(color))
        let measured = text.measure(in: CGSize(width: 150, height: 30))
        let backgroundRect = CGRect(
            x: point.x - measured.width / 2 - 4,
            y: point.y - measured.height / 2 - 2,
            width: measured.width + 8,
            height: measured.height + 4
        )
        context.fill(
            Path(roundedRect: backgroundRect, cornerRadius: 5),
            with: .color((colorScheme == .dark ? Color.black : Color.white).opacity(0.84))
        )
        context.draw(text, at: point, anchor: .center)
    }

    private func drawArrowHead(
        context: inout GraphicsContext,
        tip: CGPoint,
        toward: CGPoint,
        color: Color,
        maximumLength: CGFloat = 8
    ) {
        let angle = atan2(toward.y - tip.y, toward.x - tip.x)
        let segmentLength = hypot(toward.x - tip.x, toward.y - tip.y)
        let length = min(maximumLength, max(2, segmentLength / 3))
        let spread: CGFloat = 0.55
        var arrow = Path()
        arrow.move(to: CGPoint(x: tip.x + length * cos(angle + spread), y: tip.y + length * sin(angle + spread)))
        arrow.addLine(to: tip)
        arrow.addLine(to: CGPoint(x: tip.x + length * cos(angle - spread), y: tip.y + length * sin(angle - spread)))
        context.stroke(arrow, with: .color(color), lineWidth: 1.2)
    }
}

private struct PreviewProjection {
    let translation: CGPoint
    let scale: CGFloat
    let depth: CGVector
    let bounds: CGRect

    init(model: SectionPreviewModel, lengthMeters: Double, size: CGSize) {
        bounds = model.bounds
        let maximumDimension = max(model.maximumDimension, 0.000_001)
        let depthUnits = SectionPreviewLengthScale.projectedUnits(
            lengthMeters: lengthMeters,
            sectionMaximumDimension: maximumDimension
        )
        let depthInModelUnits = maximumDimension * depthUnits
        let rawDepth = CGVector(dx: depthInModelUnits * 0.78, dy: -depthInModelUnits * 0.38)
        let rawWidth = Double(bounds.width) + abs(rawDepth.dx)
        let rawHeight = Double(bounds.height) + abs(rawDepth.dy)
        let leftMeasurementMargin: CGFloat = 74
        let rightMargin: CGFloat = 16
        let availableWidth = max(size.width - leftMeasurementMargin - rightMargin, 1)
        let availableHeight = max(size.height - 54, 1)
        scale = min(availableWidth / rawWidth, availableHeight / rawHeight)
        depth = CGVector(dx: rawDepth.dx * scale, dy: rawDepth.dy * scale)

        let renderedWidth = CGFloat(rawWidth) * scale
        let renderedHeight = CGFloat(rawHeight) * scale
        let minX = leftMeasurementMargin + (availableWidth - renderedWidth) / 2
        let minY = (availableHeight - renderedHeight) / 2 + 8
        translation = CGPoint(
            x: minX - bounds.minX * scale,
            y: minY + abs(depth.dy) + bounds.maxY * scale
        )
    }

    func front(_ point: CGPoint) -> CGPoint {
        CGPoint(x: translation.x + point.x * scale, y: translation.y - point.y * scale)
    }

    func back(_ point: CGPoint) -> CGPoint {
        let frontPoint = front(point)
        return CGPoint(x: frontPoint.x + depth.dx, y: frontPoint.y + depth.dy)
    }

    var dimensionStart: CGPoint {
        let base = front(CGPoint(x: bounds.maxX, y: bounds.minY))
        return CGPoint(x: base.x, y: base.y + 42)
    }

    var dimensionEnd: CGPoint {
        CGPoint(x: dimensionStart.x + depth.dx, y: dimensionStart.y + depth.dy)
    }
}
