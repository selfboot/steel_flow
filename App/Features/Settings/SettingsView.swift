import SwiftUI
import SwiftData
import PhotosUI
import UIKit

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
    @AppStorage("workflow.last_backup") private var lastBackup: Double = 0
    @AppStorage("workflow.last_restore") private var lastRestore: Double = 0
    @State private var showCompany = false
    @State private var pendingProAction: (() -> Void)?
    @State private var showCustomers = false
    @State private var showExporter = false
    @State private var showImporter = false
    @State private var backupDocument = SteelFlowBackupDocument()
    @State private var backupMessage: String?
    @State private var pendingImportData: Data?
    @State private var pendingImportPreview: BackupPreview?
    @State private var showImportConfirmation = false
    @State private var showDeleteConfirmation = false
    @State private var paywallReason: ProPaywallReason?

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
                CurrencyPickerRow(selection: $currencyCode)
                Picker("settings.paper", selection: $paperRaw) {
                    Text("paper.a4").tag(PaperSize.a4.rawValue)
                    Text("paper.letter").tag(PaperSize.letter.rawValue)
                }
            }

            Section("settings.quote") {
                Button("workflow.customers") { showCustomers = true }
                if purchaseManager.isPro {
                    Button("settings.company_profile") { showCompany = true }
                } else {
                    Button { pendingProAction = { showCompany = true }; paywallReason = .companyProfile } label: { Label("settings.company_profile", systemImage: "lock.fill") }
                }
            }

            Section("settings.pro") {
                HStack {
                    Label(purchaseManager.isPro ? "purchase.pro_active" : "purchase.free", systemImage: purchaseManager.isPro ? "checkmark.seal.fill" : "seal")
                    Spacer()
                    if let price = purchaseManager.localizedPrice, !purchaseManager.isPro { Text(price).foregroundStyle(.secondary) }
                }
                if !purchaseManager.isPro {
                    Button("purchase.buy") { paywallReason = .general }
                }
                Text("purchase.help").font(.caption).foregroundStyle(.secondary)
            }

            Section("settings.data") {
                if lastBackup > 0 { LabeledContent("workflow.last_backup", value: AppFormatters.date(Date(timeIntervalSince1970: lastBackup), locale: locale)) }
                else { Text("workflow.backup_never").foregroundStyle(.secondary) }
                if lastRestore > 0 { LabeledContent("workflow.last_restore", value: AppFormatters.date(Date(timeIntervalSince1970: lastRestore), locale: locale)) }
                if !projects.isEmpty && Date.now.timeIntervalSince1970 - lastBackup > 30 * 86400 { Label("workflow.backup_reminder", systemImage: "externaldrive.badge.exclamationmark").font(.caption).foregroundStyle(.orange) }
                Text("workflow.backup_contents").font(.caption).foregroundStyle(.secondary)
                Button {
                    if purchaseManager.isPro { exportBackup() } else { pendingProAction = { exportBackup() }; paywallReason = .backups }
                } label: {
                    Label("backup.export", systemImage: purchaseManager.isPro ? "square.and.arrow.up" : "lock.fill")
                }
                Button {
                    if purchaseManager.isPro { showImporter = true } else { pendingProAction = { showImporter = true }; paywallReason = .backups }
                } label: {
                    Label("backup.import", systemImage: purchaseManager.isPro ? "square.and.arrow.down" : "lock.fill")
                }
                Button(role: .destructive) { showDeleteConfirmation = true } label: { Label("settings.delete_all", systemImage: "trash") }
            }

            Section("settings.support") {
                NavigationLink {
                    FeedbackView()
                } label: {
                    Label("feedback.entry", systemImage: "envelope")
                }
            }

            Section("settings.about") {
                LabeledContent("settings.version", value: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0")
                NavigationLink("settings.calculation_disclaimer") { DisclaimerView() }
                LabeledContent("settings.privacy", value: AppLocalization.text("settings.privacy.value", locale: locale))
            }
        }
        .navigationDestination(isPresented: $showCompany) { CompanyProfileView() }
        .navigationTitle("tab.settings")
        .modifier(RootTabLayout())
        .task { await purchaseManager.load() }
        .proPaywall(reason: $paywallReason) { if let action = pendingProAction { pendingProAction = nil; action() } }
        .fileExporter(isPresented: $showExporter, document: backupDocument, contentType: .steelFlowBackup, defaultFilename: "SteelFlow-Backup") { result in
            switch result { case .success: lastBackup = Date.now.timeIntervalSince1970; case .failure(let error): backupMessage = error.localizedDescription }
        }
        .sheet(isPresented: $showCustomers) { CustomerPickerView() }
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
        .onChange(of: languageCode) { _, _ in Task { await purchaseManager.load() } }
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
                preferences: .init(languageCode: languageCode, unitSystemRaw: unitSystemRaw, currencyCode: currencyCode, paperSizeRaw: paperRaw),
                libraryData: CalculationLibrary.shared.exportData
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
            if let libraryData = imported.libraryData { try CalculationLibrary.shared.merge(libraryData) }
            lastRestore = Date.now.timeIntervalSince1970
            if importPreferences, let preferences = imported.preferences {
                languageCode = preferences.languageCode
                unitSystemRaw = preferences.unitSystemRaw
                currencyCode = preferences.currencyCode
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
            company.logoData = nil; company.defaultTerms = ""
            company.companyName = ""; company.contactName = ""; company.email = ""; company.phone = ""; company.address = ""; company.updatedAt = .now
        }
        if PersistenceErrorCenter.shared.save(modelContext) {
            CalculationLibrary.shared.clear(); lastBackup = 0; lastRestore = 0
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
    @State private var logoData: Data?
    @State private var selectedLogo: PhotosPickerItem?
    @State private var defaultTerms = ""
    @State private var logoError = false
    @State private var companyName = ""
    @State private var contactName = ""
    @State private var email = ""
    @State private var phone = ""
    @State private var address = ""

    var body: some View {
        Form {
            Section {
                LabeledEntry("company.name", text: $companyName)
                LabeledEntry("company.contact", text: $contactName)
                LabeledEntry("company.email", text: $email).keyboardType(.emailAddress).textInputAutocapitalization(.never)
                LabeledEntry("company.phone", text: $phone).keyboardType(.phonePad)
                LabeledEntry("company.address", text: $address, multiline: true).lineLimit(2...5)
            }
            Section("workflow.branding") {
                if let data = logoData, let image = UIImage(data: data) {
                    Image(uiImage: image).resizable().scaledToFit().frame(maxWidth: 180, maxHeight: 80)
                    Button("workflow.remove_logo", role: .destructive) { logoData = nil }
                }
                PhotosPicker(selection: $selectedLogo, matching: .images) { Label("workflow.choose_logo", systemImage: "photo") }
                TextField("workflow.default_terms", text: $defaultTerms, axis: .vertical).lineLimit(3...10)
            }
            Section { Text("company.help").font(.caption).foregroundStyle(.secondary) }
        }
        .keyboardDismissSupport()
        .toolbar {
            ToolbarItem(placement: .cancellationAction) { Button("common.cancel") { dismiss() } }
            ToolbarItem(placement: .confirmationAction) { Button("common.save") { save() } }
        }
        .task(id: selectedLogo) {
            guard let selectedLogo else { return }
            do {
                guard let data = try await selectedLogo.loadTransferable(type: Data.self), data.count <= 20_000_000, let image = UIImage(data: data) else { logoError = true; return }
                let scale = min(1, 600 / max(image.size.width, image.size.height))
                let size = CGSize(width: image.size.width * scale, height: image.size.height * scale)
                let renderer = UIGraphicsImageRenderer(size: size)
                logoData = renderer.pngData { _ in image.draw(in: CGRect(origin: .zero, size: size)) }
            } catch { logoError = true }
        }
        .alert("workflow.logo_error", isPresented: $logoError) { Button("common.ok", role: .cancel) {} }
        .onAppear {
            logoData = company.logoData; defaultTerms = company.defaultTerms
            companyName = company.companyName
            contactName = company.contactName
            email = company.email
            phone = company.phone
            address = company.address
        }
    }

    private func save() {
        company.logoData = logoData; company.defaultTerms = defaultTerms
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
