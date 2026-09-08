import SwiftUI
import SwiftData

struct ProjectsView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.locale) private var locale
    @Query(sort: \ProjectEntity.updatedAt, order: .reverse) private var projects: [ProjectEntity]
    var onSelect: ((ProjectEntity) -> Void)? = nil
    @State private var openedProject: ProjectEntity?
    @State private var createAfterTemplate = false
    @State private var pendingCreated: ProjectEntity?
    @State private var showArchived = false
    @State private var search = ""
    @State private var searchPresented = false
    @State private var sortByName = false
    @State private var showTemplates = false
    @State private var showTemplatePicker = false
    @State private var showNewProject = false
    @State private var paywallReason: ProPaywallReason?
    @State private var purchaseManager = PurchaseManager.shared
    @State private var pendingProAction: (() -> Void)?
    @State private var pendingDeletion: ProjectEntity?
    @State private var showDeleteConfirmation = false

    private var visibleProjects: [ProjectEntity] {
        projects.filter { $0.isArchived == showArchived && $0.isTemplate == showTemplates && (search.isEmpty || [$0.name, $0.customerName, $0.projectNumber].contains { $0.localizedStandardContains(search) }) }
            .sorted { a, b in
                if a.isPinned != b.isPinned { return a.isPinned }
                return sortByName ? a.name.localizedStandardCompare(b.name) == .orderedAscending : a.updatedAt > b.updatedAt
            }
    }

    var body: some View {
        Group {
            if visibleProjects.isEmpty {
                ContentUnavailableView {
                    Label(!search.isEmpty ? "ui.no_matches" : showTemplates ? "workflow.templates_empty" : showArchived ? "project.no_archived" : "project.empty", systemImage: !search.isEmpty ? "magnifyingglass" : "folder")
                } description: {
                    Text(search.isEmpty ? (showTemplates ? "ui.no_templates_help" : showArchived ? "project.no_archived.description" : "project.empty.description") : "ui.search_help")
                    if !search.isEmpty { Text(search) }
                } actions: {
                    if !search.isEmpty { Button("ui.clear_filters") { search = ""; searchPresented = false; showTemplates = false; showArchived = false } }
                    else if !showArchived && !showTemplates { Button("project.create") { attemptNewProject() }.buttonStyle(PrimaryActionStyle()) }
                }
            } else {
                List {
                    ForEach(visibleProjects) { project in
                        projectLink(project)
                            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                Button {
                                    if project.isArchived,
                                       !ProPolicy.canActivateProject(
                                        activeProjectCount: projects.filter({ !$0.isArchived && !$0.isTemplate }).count,
                                        isPro: purchaseManager.isPro
                                       ) {
                                        pendingProAction = { project.isArchived = false; project.updatedAt = .now; _ = PersistenceErrorCenter.shared.save(modelContext) }
                                        paywallReason = .projects
                                        return
                                    }
                                    project.isArchived.toggle()
                                    project.updatedAt = .now
                                    PersistenceErrorCenter.shared.save(modelContext)
                                } label: {
                                    Label(project.isArchived ? "project.restore" : "project.archive", systemImage: project.isArchived ? "arrow.uturn.backward" : "archivebox")
                                }
                                .tint(.orange)
                                Button(role: .destructive) {
                                    pendingDeletion = project
                                    showDeleteConfirmation = true
                                } label: {
                                    Label("common.delete", systemImage: "trash")
                                }
                            }
                            .contextMenu {
                                Button(project.isPinned ? "ui.unpin" : "ui.pin", systemImage: project.isPinned ? "pin.slash" : "pin") { project.isPinned.toggle(); _ = PersistenceErrorCenter.shared.save(modelContext) }
                            }
                            .swipeActions(edge: .leading) {
                                Button { duplicate(project) } label: { Label("project.duplicate", systemImage: "plus.square.on.square") }
                                    .tint(SteelFlowTheme.steelBlue)
                            }
                    }
                    if showArchived {
                        Section {
                            Text("project.archive.help").font(.caption).foregroundStyle(.secondary)
                        }
                    }
                }
                .contentMargins(.top, 8, for: .scrollContent)
            }
        }
        .searchable(text: $search, isPresented: $searchPresented, placement: .navigationBarDrawer(displayMode: .always), prompt: "workflow.project_search")
        .navigationTitle("tab.projects")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Menu {
                    Toggle("ui.show_archived", isOn: $showArchived)
                    Toggle("workflow.templates", isOn: $showTemplates)
                    Toggle("workflow.sort_name", isOn: $sortByName)
                } label: { Label("ui.filters", systemImage: "line.3.horizontal.decrease.circle") }
                .accessibilityIdentifier("projects.filters")
            }
            ToolbarItem(placement: .primaryAction) {
                Menu {
                    Button("project.create", systemImage: "plus") { attemptNewProject() }
                    Button("workflow.from_template", systemImage: "doc.on.doc") { showTemplatePicker = true }
                } label: { Label("project.create", systemImage: "plus") }.accessibilityIdentifier("projects.menu")
            }
        }
        .sheet(isPresented: $showNewProject) { ProjectEditorSheet() }
        .sheet(isPresented: $showTemplatePicker, onDismiss: { openCreated() }) { TemplatePickerView(onCreated: { pendingCreated = $0 }, onNewProject: { createAfterTemplate = true }) }
        .navigationDestination(item: $openedProject) { ProjectDetailView(project: $0) }
        .proPaywall(reason: $paywallReason) { if let action = pendingProAction { pendingProAction = nil; action() } }
        .alert("project.delete.confirm.title", isPresented: $showDeleteConfirmation) {
            Button("common.delete", role: .destructive) { confirmDeletion() }
            Button("common.cancel", role: .cancel) { pendingDeletion = nil }
        } message: {
            Text("project.delete.confirm.message")
        }
    }

    @ViewBuilder private func projectLink(_ project: ProjectEntity) -> some View {
        if let onSelect { Button { onSelect(project) } label: { ProjectRow(project: project) }.buttonStyle(.plain) }
        else { NavigationLink { ProjectDetailView(project: project) } label: { ProjectRow(project: project) } }
    }
    private func openCreated() {
        if createAfterTemplate { createAfterTemplate = false; attemptNewProject(); return }
        guard let project = pendingCreated else { return }
        pendingCreated = nil
        if let onSelect { onSelect(project) } else { openedProject = project }
    }

    private func attemptNewProject() {
        let activeCount = projects.filter { !$0.isArchived && !$0.isTemplate }.count
        if !ProPolicy.canActivateProject(activeProjectCount: activeCount, isPro: purchaseManager.isPro) { pendingProAction = { showNewProject = true }; paywallReason = .projects }
        else { showNewProject = true }
    }

    private func duplicate(_ source: ProjectEntity) {
        guard purchaseManager.isPro else {
            pendingProAction = { duplicate(source) }
            paywallReason = .duplicate
            return
        }
        if !ProPolicy.canActivateProject(
            activeProjectCount: projects.filter({ !$0.isArchived && !$0.isTemplate }).count,
            isPro: purchaseManager.isPro
        ) {
            paywallReason = .projects
            return
        }
        let copy = ProjectEntity(
            name: source.name + " " + AppLocalization.text("project.copy_suffix", locale: locale),
            customerName: source.customerName,
            quoteLanguage: source.quoteLanguage,
            unitSystem: source.unitSystem,
            currencyCode: source.currencyCode,
            paperSize: source.paperSize
        )
        copy.taxPercentText = source.taxPercentText
        copy.markupPercentText = source.markupPercentText
        copy.profitModeRaw = source.profitModeRaw
        copy.validDays = source.validDays
        copy.terms = source.terms
        copy.notes = source.notes
        copy.customerContact = source.customerContact
        copy.showQuoteMass = source.showQuoteMass
        copy.showQuoteUnitPrice = source.showQuoteUnitPrice
        for item in source.items.sorted(by: { $0.sortIndex < $1.sortIndex }) {
            let cloned = CalculationItemEntity(
                profile: item.profile,
                geometry: item.geometry,
                materialID: item.materialID,
                materialName: item.materialName,
                densityKgPerM3: item.densityKgPerM3,
                lengthValue: item.lengthValue,
                lengthUnit: item.lengthUnit,
                quantity: item.quantity,
                wastePercent: item.wastePercent,
                priceBasis: item.priceBasis,
                unitPrice: item.unitPrice,
                processingFee: item.processingFee,
                otherFee: item.otherFee,
                priceSource: item.priceSource,
                priceSourceName: item.priceSourceName,
                priceRegion: item.priceRegion,
                materialGrade: item.materialGrade,
                priceIncludesTax: item.priceIncludesTax,
                priceEffectiveAt: item.priceEffectiveAt,
                description: item.descriptionText,
                internalNote: item.internalNote,
                sortIndex: item.sortIndex
            )
            copy.items.append(cloned)
        }
        modelContext.insert(copy)
        PersistenceErrorCenter.shared.save(modelContext)
    }

    private func confirmDeletion() {
        guard let pendingDeletion else { return }
        modelContext.delete(pendingDeletion)
        _ = PersistenceErrorCenter.shared.save(modelContext)
        self.pendingDeletion = nil
    }
}

private struct ProjectRow: View {
    let project: ProjectEntity
    @Environment(\.locale) private var locale
    @Environment(\.dynamicTypeSize) private var typeSize

    var body: some View {
        let summary = ProjectCalculator.summarize(project)
        VStack(alignment: .leading, spacing: 8) {
            let layout = typeSize.isAccessibilitySize ? AnyLayout(VStackLayout(alignment: .leading)) : AnyLayout(HStackLayout())
            layout {
                Text(project.name).font(.headline).lineLimit(2).layoutPriority(1)
                if project.isPinned { Image(systemName: "pin.fill").accessibilityLabel("ui.pinned") }
                Spacer()
                Text(AppFormatters.decimal(summary.pricing.total, currencyCode: project.currencyCode, locale: locale))
                    .font(.subheadline.weight(.semibold)).monospacedDigit().fixedSize(horizontal: true, vertical: false)
            }
            HStack(spacing: 8) {
                Text(project.projectNumber).lineLimit(1)
                if !project.customerName.isEmpty { Text("•"); Text(project.customerName).lineLimit(1) }
                Spacer()
                Text(AppLocalization.count("project.item_count", value: project.items.count, locale: locale)).fixedSize(horizontal: true, vertical: false)
            }
            .font(.caption).foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
    }
}

struct ProjectEditorSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(\.locale) private var locale
    @AppStorage("app.unitSystem") private var defaultUnitRaw = UnitSystem.metric.rawValue
    @AppStorage("app.currency") private var defaultCurrency = "USD"
    @AppStorage("app.language") private var appLanguage = "system"
    @AppStorage("app.paper") private var defaultPaperRaw = PaperSize.a4.rawValue
    @Query private var companies: [CompanyProfileEntity]
    @State private var showCustomers = false
    @State private var customerContact = ""
    @State private var name = ""
    @State private var customer = ""
    @State private var currency = "USD"
    @State private var quoteLanguage = "en"
    @State private var unitSystem = UnitSystem.metric
    @State private var paper = PaperSize.a4
    private var normalizedCurrency: String? { CurrencyRules.normalizedCode(currency) }

    var body: some View {
        NavigationStack {
            Form {
                TextField("project.name", text: $name)
                TextField("project.customer", text: $customer)
                Button("workflow.choose_customer") { showCustomers = true }
                Picker("project.quote_language", selection: $quoteLanguage) {
                    Text("language.english").tag("en")
                    Text("language.chinese").tag("zh-Hans")
                }
                Picker("settings.unit_system", selection: $unitSystem) {
                    ForEach(UnitSystem.allCases) { Text($0.localizationKey).tag($0) }
                }
                CurrencyPickerRow(selection: $currency)
                Picker("settings.paper", selection: $paper) {
                    Text("paper.a4").tag(PaperSize.a4)
                    Text("paper.letter").tag(PaperSize.letter)
                }
            }
            .keyboardDismissSupport()
            .navigationTitle("project.create")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("common.cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("common.create") {
                        let project = ProjectEntity(
                            name: name.trimmingCharacters(in: .whitespacesAndNewlines),
                            customerName: customer,
                            quoteLanguage: quoteLanguage,
                            unitSystem: unitSystem,
                            currencyCode: normalizedCurrency ?? defaultCurrency,
                            paperSize: paper
                        )
                        project.customerContact = customerContact
                        if PurchaseManager.shared.isPro { project.terms = companies.first?.defaultTerms ?? "" }
                        modelContext.insert(project)
                        if PersistenceErrorCenter.shared.save(modelContext) { dismiss() }
                    }
                    .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || normalizedCurrency == nil)
                }
            }
            .sheet(isPresented: $showCustomers) { CustomerPickerView { value in
                customer = value.name; customerContact = [value.phone, value.email, value.address].filter { !$0.isEmpty }.joined(separator: " · ")
            } }
            .onAppear {
                currency = defaultCurrency
                unitSystem = UnitSystem(rawValue: defaultUnitRaw) ?? .metric
                quoteLanguage = appLanguage == "zh-Hans" || (appLanguage == "system" && locale.language.languageCode?.identifier == "zh") ? "zh-Hans" : "en"
                paper = PaperSize(rawValue: defaultPaperRaw) ?? .a4
            }
        }
    }
}
