import SwiftUI
import SwiftData

struct RootTabView: View {
    @State private var selectedTab = 0
    @Environment(\.colorScheme) private var colorScheme
    @State private var persistenceErrors = PersistenceErrorCenter.shared

    var body: some View {
        TabView(selection: $selectedTab) {
            NavigationStack { CalculatorHomeView() }
                .tabItem { tabLabel("tab.calculate", symbol: "function", index: 0) }
                .tag(0)
            ProjectsWorkspaceView()
                .tabItem { tabLabel("tab.projects", symbol: "folder.fill", index: 1) }
                .tag(1)
            NavigationStack { MaterialsView() }
                .tabItem { tabLabel("tab.materials", symbol: "shippingbox.fill", index: 2) }
                .tag(2)
            NavigationStack { SettingsView() }
                .tabItem { tabLabel("tab.settings", symbol: "gearshape.fill", index: 3) }
                .tag(3)
        }
#if DEBUG
        .preferredColorScheme(ProcessInfo.processInfo.arguments.contains("--ui-dark") ? .dark : nil)
#endif
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

    private func tabLabel(_ title: LocalizedStringKey, symbol: String, index: Int) -> some View {
        Label {
            Text(title)
        } icon: {
            Image(uiImage: SteelTabImage.image(symbol, selected: selectedTab == index, dark: colorScheme == .dark))
                .renderingMode(.original)
        }
        .labelStyle(.titleAndIcon)
    }

}

struct ProjectsWorkspaceView: View {
    @Environment(\.horizontalSizeClass) private var sizeClass
    @Environment(\.dynamicTypeSize) private var typeSize
    @Query private var projects: [ProjectEntity]
    @State private var selectedProject: ProjectEntity?
    @State private var columns: NavigationSplitViewVisibility = .all
    var body: some View {
        if sizeClass == .regular && !typeSize.isAccessibilitySize {
            NavigationSplitView(columnVisibility: $columns) {
                ProjectsView { selectedProject = $0 }
                    .navigationSplitViewColumnWidth(min: 260, ideal: 300, max: 360)
            } detail: {
                NavigationStack {
                    if let selectedProject, projects.contains(where: { $0.id == selectedProject.id }) { ProjectDetailView(project: selectedProject).id(selectedProject.id) }
                    else { ContentUnavailableView("ui.choose_project", systemImage: "folder") }
                }
            }.navigationSplitViewStyle(.balanced)
        } else { NavigationStack { ProjectsView() } }
    }
}
