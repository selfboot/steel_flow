#if DEBUG
import SwiftUI
import SwiftData
import UIKit

enum MarketingCaptureScreen: String {
    case home
    case calculation
    case pricing
    case projects
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

    var body: some View {
        captureContent
            // iPad's system date follows SpringBoard rather than the capture locale.
            .statusBarHidden(UIDevice.current.userInterfaceIdiom == .pad)
    }

    @ViewBuilder
    private var captureContent: some View {
        switch screen {
        case .home:
            NavigationStack { CalculatorHomeView() }
        case .calculation, .pricing:
            NavigationStack { CalculatorEditorView(profile: calculationProfile, marketingPreset: true) }
        case .projects:
            NavigationStack { ProjectsView() }
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
    static var language: String {
        let args = ProcessInfo.processInfo.arguments
        guard let i = args.firstIndex(of: "--marketing-locale"), args.indices.contains(i + 1) else { return "en" }
        return AppLanguage.resolve(Locale(identifier: args[i + 1])).rawValue
    }
    static var projectName: String { text("project") }
    static var currency: String { ["zh-Hans": "CNY", "zh-Hant": "TWD", "ja": "JPY", "ko": "KRW", "de": "EUR", "es": "EUR", "fr": "EUR"][language] ?? "USD" }
    static var priceMultiplier: Decimal { ["zh-Hant": Decimal(32), "ja": Decimal(145), "ko": Decimal(1350)][language] ?? 1 }
    static func text(_ key: String) -> String { copy[language]?[key] ?? copy["en"]![key]! }
    private static let copy: [String: [String: String]] = [
        "en": ["project": "Harbor Canopy", "customer": "Northline Fabrication", "source": "Regional spot", "region": "US Midwest", "plate": "Base plate 200 × 12", "supplier": "Supplier quote", "tube": "Column tube Ø88.9", "angle": "Connection angle L75 × 6", "material": "Weathering steel", "materialNote": "Project-specific material", "priceName": "Q235B regional spot", "supplierName": "Northline Metals", "company": "Northline Fabrication", "contact": "Estimating team"],
        "zh-Hans": ["project": "港区雨棚", "customer": "北辰钢构", "source": "华东现货", "region": "上海", "plate": "底板 200 × 12", "supplier": "供应商报价", "tube": "立柱圆管 Ø88.9", "angle": "连接角钢 L75 × 6", "material": "耐候钢", "materialNote": "项目自定义材料", "priceName": "Q235B 华东现货", "supplierName": "联盛金属", "company": "北辰钢构", "contact": "业务部"],
        "zh-Hant": ["project": "港區雨棚", "customer": "北辰鋼構", "source": "供應商現貨", "region": "台北", "plate": "底板 200 × 12", "supplier": "供應商報價", "tube": "立柱圓管 Ø88.9", "angle": "連接角鋼 L75 × 6", "material": "耐候鋼", "materialNote": "專案自訂材料", "priceName": "Q235B 供應商現貨", "supplierName": "聯盛金屬", "company": "北辰鋼構", "contact": "業務部"],
        "ja": ["project": "港のキャノピー", "customer": "北辰金属工業", "source": "地域参考価格", "region": "大阪", "plate": "ベースプレート 200 × 12", "supplier": "仕入先見積", "tube": "支柱パイプ Ø88.9", "angle": "接合用山形鋼 L75 × 6", "material": "耐候性鋼", "materialNote": "プロジェクト専用材料", "priceName": "Q235B 参考価格", "supplierName": "北辰金属", "company": "北辰金属工業", "contact": "見積担当"],
        "ko": ["project": "항만 캐노피", "customer": "북진 금속", "source": "지역 참고 가격", "region": "부산", "plate": "베이스 플레이트 200 × 12", "supplier": "공급업체 견적", "tube": "기둥 강관 Ø88.9", "angle": "연결 앵글 L75 × 6", "material": "내후성강", "materialNote": "프로젝트 사용자 재료", "priceName": "Q235B 참고 가격", "supplierName": "북진 금속", "company": "북진 금속", "contact": "견적 담당"],
        "de": ["project": "Hafenüberdachung", "customer": "Nord Metallbau", "source": "Regionaler Richtpreis", "region": "Hamburg", "plate": "Grundplatte 200 × 12", "supplier": "Lieferantenangebot", "tube": "Stützenrohr Ø88,9", "angle": "Anschlusswinkel L75 × 6", "material": "Wetterfester Stahl", "materialNote": "Projekteigenes Material", "priceName": "Q235B Richtpreis", "supplierName": "Nord Metall", "company": "Nord Metallbau", "contact": "Kalkulation"],
        "es": ["project": "Marquesina del puerto", "customer": "Metalúrgica Norte", "source": "Precio de referencia", "region": "Valencia", "plate": "Placa base 200 × 12", "supplier": "Oferta del proveedor", "tube": "Tubo de soporte Ø88,9", "angle": "Ángulo de unión L75 × 6", "material": "Acero patinable", "materialNote": "Material del proyecto", "priceName": "Q235B precio de referencia", "supplierName": "Metales Norte", "company": "Metalúrgica Norte", "contact": "Presupuestos"],
        "fr": ["project": "Auvent du port", "customer": "Métallerie du Nord", "source": "Prix indicatif local", "region": "Lyon", "plate": "Platine 200 × 12", "supplier": "Devis fournisseur", "tube": "Tube de poteau Ø88,9", "angle": "Cornière de liaison L75 × 6", "material": "Acier patinable", "materialNote": "Matériau du projet", "priceName": "Q235B prix indicatif", "supplierName": "Métaux du Nord", "company": "Métallerie du Nord", "contact": "Service devis"],
    ]

    static func ensure(in context: ModelContext) {
        let existingProjects = (try? context.fetch(FetchDescriptor<ProjectEntity>())) ?? []
        if existingProjects.contains(where: { $0.projectNumber == projectNumber && $0.name == projectName }) { return }

        let chinese = language == "zh-Hans"
        let project = ProjectEntity(
            name: projectName,
            projectNumber: projectNumber,
            customerName: text("customer"),
            quoteLanguage: language,
            unitSystem: .metric,
            currencyCode: currency,
            paperSize: .a4
        )
        project.taxPercentText = chinese ? "13" : "8.25"
        project.markupPercentText = chinese ? "12" : "18"
        project.validDays = 21

        let priceScale = (chinese ? Decimal(string: "5.32")! : Decimal(string: "0.74")!) * priceMultiplier
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
            priceSourceName: text("source"),
            priceRegion: text("region"),
            materialGrade: "Q235B",
            priceEffectiveAt: Date(timeIntervalSince1970: 1_787_875_200),
            description: text("plate"),
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
            unitPrice: (chinese ? 5.68 : 0.81) * priceMultiplier,
            processingFee: chinese ? 960 : 135,
            priceSource: .manual,
            priceSourceName: text("supplier"),
            priceRegion: text("region"),
            materialGrade: "Q355B",
            priceEffectiveAt: Date(timeIntervalSince1970: 1_787_875_200),
            description: text("tube"),
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
            unitPrice: (chinese ? 5.46 : 0.78) * priceMultiplier,
            processingFee: chinese ? 520 : 72,
            priceSource: .manual,
            priceSourceName: text("supplier"),
            priceRegion: text("region"),
            materialGrade: "Q235B",
            priceEffectiveAt: Date(timeIntervalSince1970: 1_787_875_200),
            description: text("angle"),
            sortIndex: 2
        )
        project.items = [plate, tube, angle]
        context.insert(project)

        let customMaterial = MaterialEntity(
            id: "weathering-steel-demo-" + language,
            name: text("material"),
            densityKgPerM3: 7_850,
            note: text("materialNote")
        )
        context.insert(customMaterial)
        context.insert(PriceBookEntryEntity(
            name: text("priceName"),
            materialID: "carbon-steel",
            materialName: "Carbon steel",
            materialGrade: "Q235B",
            supplier: text("supplierName"),
            region: text("region"),
            currencyCode: currency,
            priceBasis: .perKilogram,
            unitPrice: priceScale,
            effectiveAt: Date(timeIntervalSince1970: 1_787_875_200)
        ))

        if let company = ((try? context.fetch(FetchDescriptor<CompanyProfileEntity>())) ?? []).first {
            company.companyName = text("company")
            company.contactName = text("contact")
            company.email = "quotes@steelflow.app"
        }
        PersistenceErrorCenter.shared.save(context)
    }
}
#endif
