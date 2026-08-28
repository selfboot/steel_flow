import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.locale) private var locale
    @Query(sort: \ProjectEntity.createdAt) private var projects: [ProjectEntity]
    @Query(sort: \MaterialEntity.createdAt) private var materials: [MaterialEntity]
    @Query private var companies: [CompanyProfileEntity]
    @Query private var priceBook: [PriceBookEntryEntity]
    @Query private var customers: [CustomerEntity]
    @Query private var snapshots: [QuoteSnapshotEntity]
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
    @State private var pendingImportPreview: BackupPreview?
    @State private var showImportConfirmation = false
    @State private var showDeleteConfirmation = false
    @State private var showProLimit = false
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
                if purchaseManager.isPro {
                    NavigationLink("settings.company_profile") { CompanyProfileView() }
                } else {
                    Button { showProLimit = true } label: { Label("settings.company_profile", systemImage: "lock.fill") }
                }
            }

            Section("settings.pro") {
                HStack {
                    Label(purchaseManager.isPro ? "purchase.pro_active" : "purchase.free", systemImage: purchaseManager.isPro ? "checkmark.seal.fill" : "seal")
                    Spacer()
                    if let price = purchaseManager.localizedPrice, !purchaseManager.isPro { Text(price).foregroundStyle(.secondary) }
                }
                if !purchaseManager.isPro {
                    Button("purchase.buy") { Task { await purchaseManager.purchase() } }
                        .disabled(!purchaseManager.isPurchaseAvailable || purchaseManager.isLoading)
                }
                Button("purchase.restore") { Task { await purchaseManager.restore() } }
                    .disabled(purchaseManager.isLoading)
                if purchaseManager.isLoading { ProgressView() }
                if let message = purchaseManager.availabilityMessage {
                    Label(message, systemImage: "exclamationmark.triangle")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Text("purchase.help").font(.caption).foregroundStyle(.secondary)
            }

            Section("settings.data") {
                Button {
                    if purchaseManager.isPro { exportBackup() } else { showProLimit = true }
                } label: {
                    Label("backup.export", systemImage: purchaseManager.isPro ? "square.and.arrow.up" : "lock.fill")
                }
                Button {
                    if purchaseManager.isPro { showImporter = true } else { showProLimit = true }
                } label: {
                    Label("backup.import", systemImage: purchaseManager.isPro ? "square.and.arrow.down" : "lock.fill")
                }
                Button(role: .destructive) { showDeleteConfirmation = true } label: { Label("settings.delete_all", systemImage: "trash") }
            }

            Section("settings.about") {
                LabeledContent("settings.version", value: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0")
                NavigationLink("settings.calculation_disclaimer") { DisclaimerView() }
                LabeledContent("settings.privacy", value: AppLocalization.text("settings.privacy.value", locale: locale))
            }
        }
        .navigationTitle("tab.settings")
        .task { await purchaseManager.load() }
        .fileExporter(isPresented: $showExporter, document: backupDocument, contentType: .steelFlowBackup, defaultFilename: "SteelFlow-Backup") { result in
            if case .failure(let error) = result { backupMessage = error.localizedDescription }
        }
        .fileImporter(isPresented: $showImporter, allowedContentTypes: [.steelFlowBackup, .json]) { result in importBackup(result) }
        .alert("backup.import.confirm", isPresented: $showImportConfirmation) {
            Button("common.cancel", role: .cancel) { clearPendingImport() }
            Button("backup.import_copy") { confirmImport(importPreferences: false) }
            if pendingImportPreview?.hasPreferences == true {
                Button("backup.import_copy_and_settings") { confirmImport(importPreferences: true) }
            }
        } message: {
            if let preview = pendingImportPreview {
                Text(AppLocalization.format(
                    "backup.import.preview",
                    locale: locale,
                    preview.schemaVersion,
                    preview.projects,
                    preview.materials,
                    preview.customers,
                    preview.quoteSnapshots
                ))
            }
        }
        .alert("backup.status", isPresented: Binding(get: { backupMessage != nil }, set: { if !$0 { backupMessage = nil } })) {
            Button("common.ok", role: .cancel) {}
        } message: { Text(backupMessage ?? "") }
        .alert("settings.delete_all.confirm", isPresented: $showDeleteConfirmation) {
            Button("common.cancel", role: .cancel) {}
            Button("common.delete", role: .destructive) { deleteAllUserData() }
        } message: {
            Text(AppLocalization.format(
                "settings.delete_all.message",
                locale: locale,
                projects.count,
                materials.filter { !$0.isBuiltIn }.count,
                priceBook.count,
                customers.count,
                snapshots.count
            ))
        }
        .onAppear { currencyDraft = currencyCode }
        .onChange(of: currencyDraft) { _, value in
            if let code = CurrencyRules.normalizedCode(value) { currencyCode = code }
        }
        .onChange(of: languageCode) { _, _ in Task { await purchaseManager.load() } }
        .alert("purchase.limit.title", isPresented: $showProLimit) {
            Button("common.ok", role: .cancel) {}
        } message: {
            Text("purchase.limit.pro_feature")
        }
        .alert(purchaseManager.alertTitle, isPresented: Binding(get: { purchaseManager.alertMessage != nil }, set: { if !$0 { purchaseManager.alertMessage = nil } })) {
            Button("common.ok", role: .cancel) {}
        } message: { Text(purchaseManager.alertMessage ?? "") }
    }

    private func exportBackup() {
        do {
            backupDocument = try BackupService.makeDocument(
                projects: projects,
                materials: materials,
                company: companies.first,
                priceBook: priceBook,
                customers: customers,
                quoteSnapshots: snapshots,
                preferences: .init(languageCode: languageCode, unitSystemRaw: unitSystemRaw, currencyCode: currencyCode, paperSizeRaw: paperRaw)
            )
            showExporter = true
        } catch { backupMessage = error.localizedDescription }
    }

    private func importBackup(_ result: Result<URL, Error>) {
        do {
            let url = try result.get()
            let access = url.startAccessingSecurityScopedResource()
            defer { if access { url.stopAccessingSecurityScopedResource() } }
            let data = try Data(contentsOf: url)
            pendingImportPreview = try BackupService.preview(data: data)
            pendingImportData = data
            showImportConfirmation = true
        } catch { backupMessage = error.localizedDescription }
    }

    private func confirmImport(importPreferences: Bool) {
        guard let data = pendingImportData else { return }
        do {
            let imported = try BackupService.importCopy(data: data, into: modelContext)
            if importPreferences, let preferences = imported.preferences {
                languageCode = preferences.languageCode
                unitSystemRaw = preferences.unitSystemRaw
                currencyCode = preferences.currencyCode
                currencyDraft = preferences.currencyCode
                paperRaw = preferences.paperSizeRaw
            }
            let messageLocale = importPreferences && imported.preferences?.languageCode != "system"
                ? Locale(identifier: imported.preferences?.languageCode ?? languageCode)
                : locale
            backupMessage = AppLocalization.format(
                "backup.import.success",
                locale: messageLocale,
                imported.projects,
                imported.materials,
                imported.customers,
                imported.quoteSnapshots
            )
        } catch { backupMessage = error.localizedDescription }
        clearPendingImport()
    }

    private func clearPendingImport() {
        pendingImportData = nil
        pendingImportPreview = nil
    }

    private func deleteAllUserData() {
        for project in projects { modelContext.delete(project) }
        for material in materials where !material.isBuiltIn { modelContext.delete(material) }
        customers.forEach(modelContext.delete)
        snapshots.forEach(modelContext.delete)
        priceBook.forEach(modelContext.delete)
        for company in companies {
            company.companyName = ""; company.contactName = ""; company.email = ""; company.phone = ""; company.address = ""; company.updatedAt = .now
        }
        if PersistenceErrorCenter.shared.save(modelContext) {
            backupMessage = AppLocalization.text("settings.delete_all.done", locale: locale)
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
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    let company: CompanyProfileEntity
    @State private var companyName = ""
    @State private var contactName = ""
    @State private var email = ""
    @State private var phone = ""
    @State private var address = ""

    var body: some View {
        Form {
            Section {
                TextField("company.name", text: $companyName)
                TextField("company.contact", text: $contactName)
                TextField("company.email", text: $email).keyboardType(.emailAddress).textInputAutocapitalization(.never)
                TextField("company.phone", text: $phone).keyboardType(.phonePad)
                TextField("company.address", text: $address, axis: .vertical).lineLimit(2...5)
            }
            Section { Text("company.help").font(.caption).foregroundStyle(.secondary) }
        }
        .toolbar {
            ToolbarItem(placement: .cancellationAction) { Button("common.cancel") { dismiss() } }
            ToolbarItem(placement: .confirmationAction) { Button("common.save") { save() } }
        }
        .onAppear {
            companyName = company.companyName
            contactName = company.contactName
            email = company.email
            phone = company.phone
            address = company.address
        }
    }

    private func save() {
        company.companyName = companyName.trimmingCharacters(in: .whitespacesAndNewlines)
        company.contactName = contactName.trimmingCharacters(in: .whitespacesAndNewlines)
        company.email = email.trimmingCharacters(in: .whitespacesAndNewlines)
        company.phone = phone.trimmingCharacters(in: .whitespacesAndNewlines)
        company.address = address.trimmingCharacters(in: .whitespacesAndNewlines)
        company.updatedAt = .now
        if PersistenceErrorCenter.shared.save(modelContext) { dismiss() }
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
