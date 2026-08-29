import SwiftUI
import SwiftData

struct ProjectsView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.locale) private var locale
    @Query(sort: \ProjectEntity.updatedAt, order: .reverse) private var projects: [ProjectEntity]
    @State private var showArchived = false
    @State private var showNewProject = false
    @State private var paywallReason: ProPaywallReason?
    @State private var purchaseManager = PurchaseManager.shared
    @State private var pendingDeletion: ProjectEntity?
    @State private var showDeleteConfirmation = false

    private var visibleProjects: [ProjectEntity] { projects.filter { $0.isArchived == showArchived } }

    var body: some View {
        Group {
            if visibleProjects.isEmpty {
                ContentUnavailableView {
                    Label(showArchived ? "project.no_archived" : "project.empty", systemImage: "folder")
                } description: {
                    Text(showArchived ? "project.no_archived.description" : "project.empty.description")
                } actions: {
                    if !showArchived { Button("project.create") { attemptNewProject() }.buttonStyle(.borderedProminent) }
                }
            } else {
                List {
                    ForEach(visibleProjects) { project in
                        NavigationLink { ProjectDetailView(project: project) } label: { ProjectRow(project: project) }
                            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                Button {
                                    if project.isArchived,
                                       !ProPolicy.canActivateProject(
                                        activeProjectCount: projects.filter({ !$0.isArchived }).count,
                                        isPro: purchaseManager.isPro
                                       ) {
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
            }
        }
        .navigationTitle("tab.projects")
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button(showArchived ? "project.show_active" : "project.show_archived") { showArchived.toggle() }
            }
            ToolbarItem(placement: .primaryAction) { Button { attemptNewProject() } label: { Image(systemName: "plus") } }
        }
        .sheet(isPresented: $showNewProject) { ProjectEditorSheet() }
        .proPaywall(reason: $paywallReason)
        .alert("project.delete.confirm.title", isPresented: $showDeleteConfirmation) {
            Button("common.delete", role: .destructive) { confirmDeletion() }
            Button("common.cancel", role: .cancel) { pendingDeletion = nil }
        } message: {
            Text("project.delete.confirm.message")
        }
    }

    private func attemptNewProject() {
        let activeCount = projects.filter { !$0.isArchived }.count
        if !ProPolicy.canActivateProject(activeProjectCount: activeCount, isPro: purchaseManager.isPro) { paywallReason = .projects }
        else { showNewProject = true }
    }

    private func duplicate(_ source: ProjectEntity) {
        guard purchaseManager.isPro else {
            paywallReason = .duplicate
            return
        }
        if !ProPolicy.canActivateProject(
            activeProjectCount: projects.filter({ !$0.isArchived }).count,
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

    var body: some View {
        let summary = ProjectCalculator.summarize(project)
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(project.name).font(.headline).lineLimit(2).layoutPriority(1)
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
                        modelContext.insert(project)
                        if PersistenceErrorCenter.shared.save(modelContext) { dismiss() }
                    }
                    .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || normalizedCurrency == nil)
                }
            }
            .onAppear {
                currency = defaultCurrency
                unitSystem = UnitSystem(rawValue: defaultUnitRaw) ?? .metric
                quoteLanguage = appLanguage == "zh-Hans" || (appLanguage == "system" && locale.language.languageCode?.identifier == "zh") ? "zh-Hans" : "en"
                paper = PaperSize(rawValue: defaultPaperRaw) ?? .a4
            }
        }
    }
}
