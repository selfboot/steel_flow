import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \ProjectEntity.createdAt) private var projects: [ProjectEntity]
    @Query(sort: \MaterialEntity.createdAt) private var materials: [MaterialEntity]
    @Query private var companies: [CompanyProfileEntity]
    @Query private var priceBook: [PriceBookEntryEntity]
    @AppStorage("app.language") private var languageCode = "system"
    @AppStorage("app.unitSystem") private var unitSystemRaw = UnitSystem.metric.rawValue
    @AppStorage("app.currency") private var currencyCode = "USD"
    @AppStorage("app.paper") private var paperRaw = PaperSize.a4.rawValue
    @State private var purchaseManager = PurchaseManager.shared
    @State private var showExporter = false
    @State private var showImporter = false
    @State private var backupDocument = SteelFlowBackupDocument()
    @State private var backupMessage: String?
    @State private var pendingImportData: Data?
    @State private var pendingImportCounts: (projects: Int, materials: Int)?
    @State private var showImportConfirmation = false
    @State private var showDeleteConfirmation = false
    @State private var currencyDraft = ""

    var body: some View {
        Form {
            Section("settings.region") {
                Picker("settings.language", selection: $languageCode) {
                    Text("language.system").tag("system")
                    Text("language.chinese").tag("zh-Hans")
                    Text("language.english").tag("en")
                }
                Picker("settings.unit_system", selection: $unitSystemRaw) {
                    ForEach(UnitSystem.allCases) { Text($0.localizationKey).tag($0.rawValue) }
                }
                TextField("settings.currency", text: $currencyDraft).textInputAutocapitalization(.characters)
                if CurrencyRules.normalizedCode(currencyDraft) == nil { Label("error.invalid_currency", systemImage: "exclamationmark.triangle.fill").foregroundStyle(.red) }
                Picker("settings.paper", selection: $paperRaw) {
                    Text("paper.a4").tag(PaperSize.a4.rawValue)
                    Text("paper.letter").tag(PaperSize.letter.rawValue)
                }
            }

            Section("settings.quote") {
                NavigationLink("settings.company_profile") { CompanyProfileView() }
            }

            Section("settings.pro") {
                HStack {
                    Label(purchaseManager.isPro ? "purchase.pro_active" : "purchase.free", systemImage: purchaseManager.isPro ? "checkmark.seal.fill" : "seal")
                    Spacer()
                    if let product = purchaseManager.product, !purchaseManager.isPro { Text(product.displayPrice).foregroundStyle(.secondary) }
                }
                if !purchaseManager.isPro {
                    Button("purchase.buy") { Task { await purchaseManager.purchase() } }
                        .disabled(purchaseManager.product == nil || purchaseManager.isLoading)
                }
                Button("purchase.restore") { Task { await purchaseManager.restore() } }
                    .disabled(purchaseManager.isLoading)
                if purchaseManager.isLoading { ProgressView() }
                Text("purchase.help").font(.caption).foregroundStyle(.secondary)
            }

            Section("settings.data") {
                Button { exportBackup() } label: { Label("backup.export", systemImage: "square.and.arrow.up") }
                Button { showImporter = true } label: { Label("backup.import", systemImage: "square.and.arrow.down") }
                Button(role: .destructive) { showDeleteConfirmation = true } label: { Label("settings.delete_all", systemImage: "trash") }
            }

            Section("settings.about") {
                LabeledContent("settings.version", value: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0")
                NavigationLink("settings.calculation_disclaimer") { DisclaimerView() }
                LabeledContent("settings.privacy", value: String(localized: "settings.privacy.value"))
            }
        }
        .navigationTitle("tab.settings")
        .task { await purchaseManager.load() }
        .fileExporter(isPresented: $showExporter, document: backupDocument, contentType: .steelFlowBackup, defaultFilename: "SteelFlow-Backup") { result in
            if case .failure(let error) = result { backupMessage = error.localizedDescription }
        }
        .fileImporter(isPresented: $showImporter, allowedContentTypes: [.steelFlowBackup, .json]) { result in importBackup(result) }
        .alert("backup.import.confirm", isPresented: $showImportConfirmation) {
            Button("common.cancel", role: .cancel) { pendingImportData = nil; pendingImportCounts = nil }
            Button("backup.import_copy") { confirmImport() }
        } message: {
            if let counts = pendingImportCounts {
                Text(String.localizedStringWithFormat(String(localized: "backup.import.preview"), counts.projects, counts.materials))
            }
        }
        .alert("backup.status", isPresented: Binding(get: { backupMessage != nil }, set: { if !$0 { backupMessage = nil } })) {
            Button("common.ok", role: .cancel) {}
        } message: { Text(backupMessage ?? "") }
        .alert("settings.delete_all.confirm", isPresented: $showDeleteConfirmation) {
            Button("common.cancel", role: .cancel) {}
            Button("common.delete", role: .destructive) { deleteAllUserData() }
        } message: { Text(String.localizedStringWithFormat(String(localized: "settings.delete_all.message"), projects.count)) }
        .onAppear { currencyDraft = currencyCode }
        .onChange(of: currencyDraft) { _, value in
            if let code = CurrencyRules.normalizedCode(value) { currencyCode = code }
        }
        .alert("purchase.error", isPresented: Binding(get: { purchaseManager.errorMessage != nil }, set: { if !$0 { purchaseManager.errorMessage = nil } })) {
            Button("common.ok", role: .cancel) {}
        } message: { Text(purchaseManager.errorMessage ?? "") }
    }

    private func exportBackup() {
        do {
            backupDocument = try BackupService.makeDocument(projects: projects, materials: materials, company: companies.first, priceBook: priceBook)
            showExporter = true
        } catch { backupMessage = error.localizedDescription }
    }

    private func importBackup(_ result: Result<URL, Error>) {
        do {
            let url = try result.get()
            let access = url.startAccessingSecurityScopedResource()
            defer { if access { url.stopAccessingSecurityScopedResource() } }
            let data = try Data(contentsOf: url)
            pendingImportCounts = try BackupService.preview(data: data)
            pendingImportData = data
            showImportConfirmation = true
        } catch { backupMessage = error.localizedDescription }
    }

    private func confirmImport() {
        guard let data = pendingImportData else { return }
        do {
            let imported = try BackupService.importCopy(data: data, into: modelContext)
            backupMessage = String.localizedStringWithFormat(String(localized: "backup.import.success"), imported.projects, imported.materials)
        } catch { backupMessage = error.localizedDescription }
        pendingImportData = nil
        pendingImportCounts = nil
    }

    private func deleteAllUserData() {
        let customers: [CustomerEntity]
        let snapshots: [QuoteSnapshotEntity]
        do {
            customers = try modelContext.fetch(FetchDescriptor<CustomerEntity>())
            snapshots = try modelContext.fetch(FetchDescriptor<QuoteSnapshotEntity>())
        } catch {
            PersistenceErrorCenter.shared.message = error.localizedDescription
            return
        }

        for project in projects { modelContext.delete(project) }
        for material in materials where !material.isBuiltIn { modelContext.delete(material) }
        customers.forEach(modelContext.delete)
        snapshots.forEach(modelContext.delete)
        priceBook.forEach(modelContext.delete)
        if let company = companies.first {
            company.companyName = ""; company.contactName = ""; company.email = ""; company.phone = ""; company.address = ""; company.updatedAt = .now
        }
        if PersistenceErrorCenter.shared.save(modelContext) {
            backupMessage = String(localized: "settings.delete_all.done")
        }
    }
}

private struct CompanyProfileView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var companies: [CompanyProfileEntity]

    var body: some View {
        Group {
            if let company = companies.first { CompanyProfileForm(company: company) }
            else {
                ProgressView().task {
                    modelContext.insert(CompanyProfileEntity())
                    PersistenceErrorCenter.shared.save(modelContext)
                }
            }
        }
        .navigationTitle("settings.company_profile")
    }
}

private struct CompanyProfileForm: View {
    @Environment(\.modelContext) private var modelContext
    @Bindable var company: CompanyProfileEntity

    var body: some View {
        Form {
            Section {
                TextField("company.name", text: $company.companyName)
                TextField("company.contact", text: $company.contactName)
                TextField("company.email", text: $company.email).keyboardType(.emailAddress).textInputAutocapitalization(.never)
                TextField("company.phone", text: $company.phone).keyboardType(.phonePad)
                TextField("company.address", text: $company.address, axis: .vertical).lineLimit(2...5)
            }
            Section { Text("company.help").font(.caption).foregroundStyle(.secondary) }
        }
        .onDisappear {
            company.updatedAt = .now
            PersistenceErrorCenter.shared.save(modelContext)
        }
    }
}

private struct DisclaimerView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("disclaimer.title").font(.title.bold())
                Text("disclaimer.body")
                Text("disclaimer.density").font(.headline)
                Text("disclaimer.density.body")
                Text("disclaimer.geometry").font(.headline)
                Text("disclaimer.geometry.body")
                Text("disclaimer.safety").font(.headline)
                Text("disclaimer.safety.body")
            }.padding()
        }
        .navigationTitle("settings.calculation_disclaimer")
    }
}
