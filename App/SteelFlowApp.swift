import SwiftUI
import SwiftData
import Observation

@main
struct SteelFlowApp: App {
    @AppStorage("app.language") private var languageCode = "system"
    @State private var dataStore = AppDataStore()

    var body: some Scene {
        WindowGroup {
            Group {
                if let container = dataStore.container {
                    appRoot
                        .modelContainer(container)
                        .task {
#if DEBUG
                            if MarketingCaptureScreen.requested != nil {
                                MarketingDemoData.ensure(in: container.mainContext)
                            }
#endif
                        }
                } else {
                    DataStoreFailureView(errorDescription: dataStore.errorDescription) {
                        dataStore.retry()
                    }
                }
            }
            .environment(\.locale, languageCode == "system" ? .autoupdatingCurrent : Locale(identifier: languageCode))
        }
    }

    @ViewBuilder
    private var appRoot: some View {
#if DEBUG
        if let screen = MarketingCaptureScreen.requested {
            MarketingCaptureRoot(screen: screen)
        } else {
            RootTabView()
        }
#else
        RootTabView()
#endif
    }
}

@MainActor
@Observable
final class AppDataStore {
    typealias ContainerFactory = @MainActor () throws -> ModelContainer

    private(set) var container: ModelContainer?
    private(set) var errorDescription = ""
    private let makeContainer: ContainerFactory

    init(makeContainer: @escaping ContainerFactory = AppDataStore.makePersistentContainer) {
        self.makeContainer = makeContainer
        retry()
    }

    func retry() {
        do {
            let container = try makeContainer()
            try SeedData.ensure(in: container.mainContext)
            self.container = container
            errorDescription = ""
        } catch {
            container = nil
            errorDescription = error.localizedDescription
        }
    }

    static func makePersistentContainer() throws -> ModelContainer {
#if DEBUG
        if ProcessInfo.processInfo.arguments.contains("--simulate-data-store-failure") {
            throw NSError(domain: "SteelFlow.DataStore", code: 1, userInfo: [NSLocalizedDescriptionKey: "Simulated data-store failure"])
        }
#endif
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
        return try ModelContainer(for: schema, configurations: [configuration])
    }
}

private struct DataStoreFailureView: View {
    let errorDescription: String
    let retry: () -> Void

    var body: some View {
        ContentUnavailableView {
            Label("data.store_unavailable.title", systemImage: "externaldrive.badge.exclamationmark")
        } description: {
            VStack(spacing: 8) {
                Text("data.store_unavailable.message")
                Text(errorDescription).font(.caption).textSelection(.enabled)
            }
        } actions: {
            Button("common.retry", action: retry).buttonStyle(.borderedProminent)
        }
    }
}
