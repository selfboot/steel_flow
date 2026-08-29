#if DEBUG
import SwiftUI
import SwiftData

enum MarketingCaptureScreen: String {
    case home
    case calculation
    case pricing
    case project
    case quote
    case materials

    static var requested: Self? {
        let arguments = ProcessInfo.processInfo.arguments
        guard let index = arguments.firstIndex(of: "--marketing-screen"),
              arguments.indices.contains(index + 1) else { return nil }
        return Self(rawValue: arguments[index + 1])
    }
}

struct MarketingCaptureRoot: View {
    let screen: MarketingCaptureScreen
    @Query(sort: \ProjectEntity.createdAt) private var projects: [ProjectEntity]

    private var calculationProfile: ProfileKind {
        let arguments = ProcessInfo.processInfo.arguments
        guard let index = arguments.firstIndex(of: "--marketing-profile"),
              arguments.indices.contains(index + 1),
              let profile = ProfileKind(rawValue: arguments[index + 1]) else { return .plate }
        return profile
    }

    private var demoProject: ProjectEntity? {
        projects.first(where: {
            $0.projectNumber == MarketingDemoData.projectNumber && $0.name == MarketingDemoData.projectName
        })
    }

    @ViewBuilder
    var body: some View {
        switch screen {
        case .home:
            NavigationStack { CalculatorHomeView() }
        case .calculation, .pricing:
            NavigationStack { CalculatorEditorView(profile: calculationProfile, marketingPreset: true) }
        case .project:
            if let project = demoProject {
                NavigationStack { ProjectDetailView(project: project) }
            } else {
                ProgressView().accessibilityIdentifier("marketing.loading")
            }
        case .quote:
            if let project = demoProject {
                QuotePreviewView(project: project)
            } else {
                ProgressView().accessibilityIdentifier("marketing.loading")
            }
        case .materials:
            NavigationStack { MaterialsView() }
        }
    }
}

@MainActor
enum MarketingDemoData {
    static let projectNumber = "Q-2026-0828"
    static var projectName: String { isChinese ? "港区雨棚" : "Harbor Canopy" }

    private static var isChinese: Bool {
        let arguments = ProcessInfo.processInfo.arguments
        guard let index = arguments.firstIndex(of: "--marketing-locale"),
              arguments.indices.contains(index + 1) else { return false }
        return arguments[index + 1].hasPrefix("zh")
    }

    static func ensure(in context: ModelContext) {
        let existingProjects = (try? context.fetch(FetchDescriptor<ProjectEntity>())) ?? []
        if existingProjects.contains(where: { $0.projectNumber == projectNumber && $0.name == projectName }) { return }

        let chinese = isChinese
        let currency = chinese ? "CNY" : "USD"
        let project = ProjectEntity(
            name: projectName,
            projectNumber: projectNumber,
            customerName: chinese ? "北辰钢构" : "Northline Fabrication",
            quoteLanguage: chinese ? "zh-Hans" : "en",
            unitSystem: .metric,
            currencyCode: currency,
            paperSize: .a4
        )
        project.taxPercentText = chinese ? "13" : "8.25"
        project.markupPercentText = chinese ? "12" : "18"
        project.validDays = 21
        project.terms = chinese ? "报价有效期 21 天" : "Quote valid for 21 days"

        let priceScale = chinese ? Decimal(string: "5.32")! : Decimal(string: "0.74")!
        let plate = CalculationItemEntity(
            profile: .plate,
            geometry: GeometryInput(values: [.width: 200, .thickness: 12]),
            materialID: "carbon-steel",
            materialName: "Carbon steel",
            densityKgPerM3: 7_850,
            lengthValue: 6,
            lengthUnit: .meter,
            quantity: 18,
            wastePercent: 5,
            priceBasis: .perKilogram,
            unitPrice: priceScale,
            processingFee: chinese ? 680 : 95,
            otherFee: chinese ? 120 : 18,
            priceSource: .manual,
            priceSourceName: chinese ? "华东现货" : "Regional spot",
            priceRegion: chinese ? "上海" : "US Midwest",
            materialGrade: "Q235B",
            priceEffectiveAt: Date(timeIntervalSince1970: 1_787_875_200),
            description: chinese ? "底板 200 × 12" : "Base plate 200 × 12",
            sortIndex: 0
        )
        let tube = CalculationItemEntity(
            profile: .roundTube,
            geometry: GeometryInput(values: [.outerDiameter: 88.9, .wallThickness: 4]),
            materialID: "carbon-steel",
            materialName: "Carbon steel",
            densityKgPerM3: 7_850,
            lengthValue: 6,
            lengthUnit: .meter,
            quantity: 24,
            wastePercent: 4,
            priceBasis: .perKilogram,
            unitPrice: chinese ? 5.68 : 0.81,
            processingFee: chinese ? 960 : 135,
            priceSource: .manual,
            priceSourceName: chinese ? "供应商报价" : "Supplier quote",
            priceRegion: chinese ? "江苏" : "US Midwest",
            materialGrade: "Q355B",
            priceEffectiveAt: Date(timeIntervalSince1970: 1_787_875_200),
            description: chinese ? "立柱圆管 Ø88.9" : "Column tube Ø88.9",
            sortIndex: 1
        )
        let angle = CalculationItemEntity(
            profile: .angle,
            geometry: GeometryInput(values: [.width: 75, .height: 75, .wallThickness: 6]),
            materialID: "carbon-steel",
            materialName: "Carbon steel",
            densityKgPerM3: 7_850,
            lengthValue: 6,
            lengthUnit: .meter,
            quantity: 30,
            wastePercent: 6,
            priceBasis: .perKilogram,
            unitPrice: chinese ? 5.46 : 0.78,
            processingFee: chinese ? 520 : 72,
            priceSource: .manual,
            priceSourceName: chinese ? "供应商报价" : "Supplier quote",
            priceRegion: chinese ? "江苏" : "US Midwest",
            materialGrade: "Q235B",
            priceEffectiveAt: Date(timeIntervalSince1970: 1_787_875_200),
            description: chinese ? "连接角钢 L75 × 6" : "Connection angle L75 × 6",
            sortIndex: 2
        )
        project.items = [plate, tube, angle]
        context.insert(project)

        let customMaterial = MaterialEntity(
            id: chinese ? "weathering-steel-demo-zh" : "weathering-steel-demo-en",
            name: chinese ? "耐候钢" : "Weathering steel",
            densityKgPerM3: 7_850,
            note: chinese ? "项目自定义材料" : "Project-specific material"
        )
        context.insert(customMaterial)
        context.insert(PriceBookEntryEntity(
            name: chinese ? "Q235B 华东现货" : "Q235B regional spot",
            materialID: "carbon-steel",
            materialName: "Carbon steel",
            materialGrade: "Q235B",
            supplier: chinese ? "联盛金属" : "Northline Metals",
            region: chinese ? "上海" : "US Midwest",
            currencyCode: currency,
            priceBasis: .perKilogram,
            unitPrice: priceScale,
            effectiveAt: Date(timeIntervalSince1970: 1_787_875_200)
        ))

        if let company = ((try? context.fetch(FetchDescriptor<CompanyProfileEntity>())) ?? []).first {
            company.companyName = chinese ? "SteelFlow 钢材报价" : "SteelFlow Fabrication"
            company.contactName = chinese ? "业务部" : "Estimating team"
            company.email = "quotes@steelflow.app"
        }
        PersistenceErrorCenter.shared.save(context)
    }
}
#endif
