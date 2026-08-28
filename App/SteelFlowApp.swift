import SwiftUI
import SwiftData

@main
struct SteelFlowApp: App {
    @AppStorage("app.language") private var languageCode = "system"

    private let container: ModelContainer = {
        let schema = Schema([
            MaterialEntity.self,
            PriceBookEntryEntity.self,
            ProjectEntity.self,
            CalculationItemEntity.self,
            CustomerEntity.self,
            CompanyProfileEntity.self,
            QuoteSnapshotEntity.self,
            AppPreferenceEntity.self
        ])
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        do {
            return try ModelContainer(for: schema, configurations: [configuration])
        } catch {
            fatalError("Unable to create SteelFlow data store: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            RootTabView()
                .environment(\.locale, languageCode == "system" ? .autoupdatingCurrent : Locale(identifier: languageCode))
                .task { SeedData.ensure(in: container.mainContext) }
        }
        .modelContainer(container)
    }
}
