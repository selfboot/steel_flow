import SwiftUI

struct RootTabView: View {
    @State private var selectedTab = 0
    @State private var persistenceErrors = PersistenceErrorCenter.shared

    var body: some View {
        TabView(selection: $selectedTab) {
            NavigationStack { CalculatorHomeView() }
                .tabItem { Label("tab.calculate", systemImage: "function") }
                .tag(0)
            NavigationStack { ProjectsView() }
                .tabItem { Label("tab.projects", systemImage: "folder") }
                .tag(1)
            NavigationStack { MaterialsView() }
                .tabItem { Label("tab.materials", systemImage: "shippingbox") }
                .tag(2)
            NavigationStack { SettingsView() }
                .tabItem { Label("tab.settings", systemImage: "gearshape") }
                .tag(3)
        }
        .tint(SteelFlowTheme.steelBlue)
        .alert("data.error.title", isPresented: Binding(
            get: { persistenceErrors.message != nil },
            set: { if !$0 { persistenceErrors.message = nil } }
        )) {
            Button("common.ok", role: .cancel) {}
        } message: {
            Text(persistenceErrors.message ?? "")
        }
    }
}
