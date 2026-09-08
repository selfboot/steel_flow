#if DEBUG
import Foundation
import SwiftData

@MainActor enum WorkflowTestFixture {
    static func seed(_ context: ModelContext) throws {
        guard ProcessInfo.processInfo.arguments.contains("--workflow-tests") else { return }
        if ProcessInfo.processInfo.arguments.contains("--ui-no-projects") { return }
        let project = ProjectEntity(name: "Workflow Quote", projectNumber: "Q-WORKFLOW", customerName: "Acme", quoteLanguage: "en", currencyCode: "CNY")
        for (index, material) in ["carbon-steel", "aluminum"].enumerated() {
            project.items.append(CalculationItemEntity(profile: .squareTube, geometry: .init(values: [.outerSide: 50, .wallThickness: 3], lengthUnit: .millimeter),
                materialID: material, materialName: material, densityKgPerM3: index == 0 ? 7850 : 2700,
                lengthValue: Double(index + 2), lengthUnit: .meter, quantity: 4, wastePercent: 0,
                priceBasis: .perKilogram, unitPrice: index == 0 ? 5 : 8, materialGrade: index == 0 ? "Q235B" : "6061",
                description: index == 0 ? "Steel tube" : "Aluminum tube", sortIndex: index))
        }
        if ProcessInfo.processInfo.arguments.contains("--ui-empty-project") { project.items = [] }
        context.insert(project)
        context.insert(CustomerEntity(name: "Saved Customer", email: "quotes@example.com", phone: "12345", address: "Workshop Road"))
        try context.save()
    }
}
#endif
