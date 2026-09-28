import SwiftUI
import SwiftData
import PhotosUI
import UIKit

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.locale) private var locale
    @Environment(\.dynamicTypeSize) private var typeSize
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
            Section {
                if purchaseManager.isPro {
                    membershipCard
                } else {
                    Button { paywallReason = .general } label: { membershipCard }
                        .buttonStyle(.plain)
                        .accessibilityIdentifier("settings.membership")
                }
            }
            .listRowInsets(EdgeInsets())
            .listRowBackground(Color.clear)

            Section("settings.region") {
                Picker(selection: $languageCode) {
                    Text("language.system").tag("system")
                    ForEach(AppLanguage.allCases) { language in
                        Text(verbatim: language.nativeName).tag(language.rawValue)
                    }
                } label: {
                    SettingsLabel("settings.language", systemImage: "globe")
                }
                .accessibilityIdentifier("settings.language")
                Picker(selection: $unitSystemRaw) {
                    ForEach(UnitSystem.allCases) { Text($0.localizationKey).tag($0.rawValue) }
                } label: {
                    SettingsLabel("settings.unit_system", systemImage: "ruler")
                }
                NavigationLink {
                    CurrencySelectionView(selection: $currencyCode)
                } label: {
                    LabeledContent {
                        Text(currencyCode)
                    } label: {
                        SettingsLabel("settings.currency", systemImage: "banknote")
                    }
                }
                Picker(selection: $paperRaw) {
                    Text("paper.a4").tag(PaperSize.a4.rawValue)
                    Text("paper.letter").tag(PaperSize.letter.rawValue)
                } label: {
                    SettingsLabel("settings.paper", systemImage: "doc")
                }
            }
            .pickerStyle(.navigationLink)

            Section("settings.quote") {
                Button { showCustomers = true } label: {
                    SettingsActionLabel("workflow.customers", systemImage: "person.2")
                }
                Button {
                    if purchaseManager.isPro {
                        showCompany = true
                    } else {
                        pendingProAction = { showCompany = true }
                        paywallReason = .companyProfile
                    }
                } label: {
                    SettingsActionLabel("settings.company_profile", systemImage: "building.2", locked: !purchaseManager.isPro)
                }
            }

            Section {
                Button {
                    if purchaseManager.isPro { exportBackup() } else { pendingProAction = { exportBackup() }; paywallReason = .backups }
                } label: {
                    SettingsActionLabel("backup.export", systemImage: "square.and.arrow.up", locked: !purchaseManager.isPro)
                }
                Button {
                    if purchaseManager.isPro { showImporter = true } else { pendingProAction = { showImporter = true }; paywallReason = .backups }
                } label: {
                    SettingsActionLabel("backup.import", systemImage: "square.and.arrow.down", locked: !purchaseManager.isPro)
                }
                Button(role: .destructive) { showDeleteConfirmation = true } label: {
                    SettingsLabel("settings.delete_all", systemImage: "trash", destructive: true)
                }
            } header: {
                Text("settings.data")
            } footer: {
                if lastBackup > 0 || lastRestore > 0 {
                    VStack(alignment: .leading, spacing: 4) {
                        if lastBackup > 0 {
                            Text("\(AppLocalization.text("workflow.last_backup", locale: locale)): \(AppFormatters.date(Date(timeIntervalSince1970: lastBackup), locale: locale))")
                        }
                        if lastRestore > 0 {
                            Text("\(AppLocalization.text("workflow.last_restore", locale: locale)): \(AppFormatters.date(Date(timeIntervalSince1970: lastRestore), locale: locale))")
                        }
                    }
                }
            }

            Section("settings.about") {
                Link(destination: AppReviewPrompt.reviewURL) {
                    SettingsActionLabel("settings.rate_app", systemImage: "star.bubble")
                }
                .accessibilityIdentifier("settings.rate_app")
                NavigationLink { FeedbackView() } label: {
                    SettingsLabel("feedback.entry", systemImage: "envelope")
                }
                NavigationLink { DisclaimerView() } label: {
                    SettingsLabel("settings.calculation_disclaimer", systemImage: "doc.text")
                }
                LabeledContent {
                    Text(AppLocalization.text("settings.privacy.value", locale: locale))
                } label: {
                    SettingsLabel("settings.privacy", systemImage: "hand.raised")
                }
                LabeledContent {
                    Text(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0")
                } label: {
                    SettingsLabel("settings.version", systemImage: "info.circle")
                }
            }
        }
        .environment(\.defaultMinListRowHeight, 54)
        .navigationDestination(isPresented: $showCompany) { CompanyProfileView() }
        .localizedNavigationTitle("tab.settings")
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

    private var membershipCard: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(spacing: 12) {
                if !typeSize.isAccessibilitySize {
                    ProEmblem(isActive: purchaseManager.isPro, size: 44)
                }
                Text("settings.pro")
                    .font(.title3.weight(.bold))
                    .fixedSize(horizontal: false, vertical: true)
                Spacer(minLength: 0)
                PolishedSymbol(systemName: purchaseManager.isPro ? "checkmark.circle.fill" : "arrow.up.right")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(SteelFlowTheme.proHighlight)
                    .accessibilityHidden(true)
            }
            VStack(alignment: .leading, spacing: 6) {
                Text(purchaseManager.isPro ? "purchase.pro_active" : "purchase.entry.title")
                    .font(.headline)
                Text(purchaseManager.isPro ? "purchase.paywall.active_subtitle" : "purchase.entry.subtitle")
                    .font(.subheadline)
                    .foregroundStyle(Color.white.opacity(0.8))
            }
            .fixedSize(horizontal: false, vertical: true)
            if !purchaseManager.isPro {
                let layout = typeSize.isAccessibilitySize
                    ? AnyLayout(VStackLayout(alignment: .leading, spacing: 12))
                    : AnyLayout(HStackLayout())
                layout {
                    Text("purchase.paywall.one_time")
                        .font(.caption)
                        .foregroundStyle(Color.white.opacity(0.8))
                    if !typeSize.isAccessibilitySize { Spacer(minLength: 8) }
                    Text("purchase.entry.action")
                        .font(.caption.weight(.semibold))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 7)
                        .background(Color.white.opacity(0.12), in: Capsule())
                }
            }
        }
        .foregroundStyle(.white)
        .padding(20)
        .background(SteelFlowTheme.proGradient, in: RoundedRectangle(cornerRadius: 22))
        .overlay {
            RoundedRectangle(cornerRadius: 22).strokeBorder(Color.white.opacity(0.12))
        }
        .contentShape(RoundedRectangle(cornerRadius: 22))
        .accessibilityElement(children: .combine)
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

/// A fixed icon column keeps labels aligned across pickers, links and actions.
private struct SettingsLabel: View {
    let title: LocalizedStringKey
    let systemImage: String
    var destructive = false

    init(_ title: LocalizedStringKey, systemImage: String, destructive: Bool = false) {
        self.title = title
        self.systemImage = systemImage
        self.destructive = destructive
    }

    var body: some View {
        HStack(spacing: 12) {
            SteelIconTile(
                systemName: systemImage,
                base: destructive ? Color.red.opacity(0.12) : SteelFlowTheme.settingsIconFill,
                foreground: destructive ? .red : .white
            )
            Text(title)
                .foregroundStyle(destructive ? Color.red : Color.primary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .alignmentGuide(.listRowSeparatorLeading) { dimensions in dimensions[.leading] + 44 }
    }
}

private struct SettingsActionLabel: View {
    let title: LocalizedStringKey
    let systemImage: String
    var locked = false

    init(_ title: LocalizedStringKey, systemImage: String, locked: Bool = false) {
        self.title = title
        self.systemImage = systemImage
        self.locked = locked
    }

    var body: some View {
        HStack(spacing: 12) {
            SettingsLabel(title, systemImage: systemImage)
            Spacer(minLength: 8)
            if locked {
                Text("Pro")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(SteelFlowTheme.steelBlue)
                    .padding(.horizontal, 7)
                    .padding(.vertical, 3)
                    .background(SteelFlowTheme.steelBlue.opacity(0.1), in: Capsule())
            }
            SettingsChevron()
        }
        .contentShape(Rectangle())
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(title)
        .accessibilityValue(locked ? "Pro" : "")
    }
}

private struct SettingsChevron: View {
    var body: some View {
        PolishedSymbol(systemName: "chevron.right")
            .font(.system(size: 13, weight: .semibold))
            .foregroundStyle(Color(uiColor: .tertiaryLabel))
            .accessibilityHidden(true)
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
        .localizedNavigationTitle("settings.company_profile")
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
        .localizedNavigationTitle("settings.calculation_disclaimer")
    }
}
