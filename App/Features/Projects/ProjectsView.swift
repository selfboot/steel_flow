import SwiftUI
import SwiftData

struct ProjectsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \ProjectEntity.updatedAt, order: .reverse) private var projects: [ProjectEntity]
    @State private var showArchived = false
    @State private var showNewProject = false
    @State private var showProLimit = false
    @State private var purchaseManager = PurchaseManager.shared

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
                            .swipeActions(edge: .trailing) {
                                Button {
                                    project.isArchived.toggle()
                                    project.updatedAt = .now
                                    PersistenceErrorCenter.shared.save(modelContext)
                                } label: {
                                    Label(project.isArchived ? "project.restore" : "project.archive", systemImage: project.isArchived ? "arrow.uturn.backward" : "archivebox")
                                }
                                .tint(.orange)
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
        .alert("purchase.limit.title", isPresented: $showProLimit) { Button("common.ok", role: .cancel) {} } message: { Text("purchase.limit.projects") }
    }

    private func attemptNewProject() {
        let activeCount = projects.filter { !$0.isArchived }.count
        if !purchaseManager.isPro && activeCount >= ProPolicy.freeActiveProjectLimit { showProLimit = true }
        else { showNewProject = true }
    }

    private func duplicate(_ source: ProjectEntity) {
        if !purchaseManager.isPro && projects.filter({ !$0.isArchived }).count >= ProPolicy.freeActiveProjectLimit {
            showProLimit = true
            return
        }
        let copy = ProjectEntity(
            name: source.name + " " + String(localized: "project.copy_suffix"),
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
}

private struct ProjectRow: View {
    let project: ProjectEntity
    @Environment(\.locale) private var locale

    var body: some View {
        let summary = ProjectCalculator.summarize(project)
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(project.name).font(.headline)
                Spacer()
                Text(AppFormatters.decimal(summary.pricing.total, currencyCode: project.currencyCode, locale: locale))
                    .font(.subheadline.weight(.semibold)).monospacedDigit()
            }
            HStack(spacing: 8) {
                Text(project.projectNumber)
                if !project.customerName.isEmpty { Text("•"); Text(project.customerName) }
                Spacer()
                Text(String.localizedStringWithFormat(String(localized: "project.item_count"), project.items.count))
            }
            .font(.caption).foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
    }
}

struct ProjectEditorSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @AppStorage("app.unitSystem") private var defaultUnitRaw = UnitSystem.metric.rawValue
    @AppStorage("app.currency") private var defaultCurrency = "USD"
    @AppStorage("app.language") private var appLanguage = "system"
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
                TextField("settings.currency", text: $currency).textInputAutocapitalization(.characters)
                if normalizedCurrency == nil { Label("error.invalid_currency", systemImage: "exclamationmark.triangle.fill").foregroundStyle(.red) }
                Picker("settings.paper", selection: $paper) {
                    Text("paper.a4").tag(PaperSize.a4)
                    Text("paper.letter").tag(PaperSize.letter)
                }
            }
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
                quoteLanguage = appLanguage == "zh-Hans" ? "zh-Hans" : "en"
                paper = unitSystem == .metric ? .a4 : .letter
            }
        }
    }
}
