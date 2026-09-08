import SwiftUI
import SwiftData

struct RootTabView: View {
    @State private var selectedTab = 0
    @State private var persistenceErrors = PersistenceErrorCenter.shared

    var body: some View {
        TabView(selection: $selectedTab) {
            NavigationStack { CalculatorHomeView() }
                .tabItem { Label("tab.calculate", systemImage: "function") }
                .tag(0)
            ProjectsWorkspaceView()
                .tabItem { Label("tab.projects", systemImage: "folder") }
                .tag(1)
            NavigationStack { MaterialsView() }
                .tabItem { Label("tab.materials", systemImage: "shippingbox") }
                .tag(2)
            NavigationStack { SettingsView() }
                .tabItem { Label("tab.settings", systemImage: "gearshape") }
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
