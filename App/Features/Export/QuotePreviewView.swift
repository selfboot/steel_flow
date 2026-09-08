import SwiftUI
import SwiftData
import PDFKit

struct QuotePreviewView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(\.locale) private var locale
    @Environment(\.horizontalSizeClass) private var sizeClass
    @Environment(\.dynamicTypeSize) private var typeSize
    @Query private var companies: [CompanyProfileEntity]
    let project: ProjectEntity
    @State private var snapshot: QuoteSnapshotPayload?
    @State private var snapshotData: Data?
    @State private var versionSaved = false
    @State private var csvKind = QuoteCSVKind.customer
    @State private var pdfURL: URL?
    @State private var csvURL: URL?
    @State private var exportError: String?
    @State private var preparing = true
#if DEBUG
    @State private var simulatedFailureConsumed = false
#endif
    @State private var sharing: ShareFile?
    @State private var purchaseManager = PurchaseManager.shared
    @State private var paywallReason: ProPaywallReason?
    private var wide: Bool { sizeClass == .regular && !typeSize.isAccessibilitySize }
    private var quoteLocale: Locale { Locale(identifier: project.quoteLanguage) }
    var body: some View {
        NavigationStack {
            HStack(spacing: 0) {
                List {
                    if !wide { Section("quote.document") { documentPreview } }
                    if let snapshot {
                        Section {
                            LabeledContent("project.number", value: snapshot.projectNumber)
                            LabeledContent("project.customer", value: snapshot.customerName)
                            LabeledContent("project.total") {
                                Text(AppFormatters.decimal(snapshot.totals.total, currencyCode: snapshot.currencyCode, locale: quoteLocale)).font(.title3.bold()).foregroundStyle(.primary).monospacedDigit()
                            }
                            LabeledContent("quote.valid_until", value: AppFormatters.date(snapshot.validUntil, locale: quoteLocale))
                        }
                    }
                    if let exportError {
                        Section {
                            Label(exportError, systemImage: "exclamationmark.triangle").foregroundStyle(.red)
                            Button("ui.retry") { Task { await prepareExports() } }.accessibilityIdentifier("quote.retry")
                        }
                    }
                    Section("workflow.quote_versions") {
                        if versionSaved { Label("workflow.version_saved", systemImage: "checkmark.seal.fill").accessibilityIdentifier("quote.version_saved") }
                        Text("ui.share_version_help").font(.caption).foregroundStyle(.secondary)
                    }
                    Section {
                        DisclosureGroup("ui.more_exports") {
                            Button("workflow.save_version") { _ = saveVersion() }.disabled(snapshotData == nil || versionSaved)
                            if let pdfURL { ShareLink(item: pdfURL) { Label("ui.share_without_version", systemImage: "square.and.arrow.up") } }
                            if purchaseManager.isPro {
                                Picker("workflow.export_purpose", selection: $csvKind) { ForEach(QuoteCSVKind.allCases) { Text(LocalizedStringKey($0.title)).tag($0) } }
                                Text("workflow.export_help").font(.caption).foregroundStyle(.secondary)
                                if let csvURL { ShareLink(item: csvURL) { Label(LocalizedStringKey("ui.export." + csvKind.rawValue), systemImage: "tablecells") } }
                            } else { Button("purchase.limit.csv") { paywallReason = .csv } }
                        }
                    }
                }
                if wide { documentPreview.frame(maxWidth: .infinity, maxHeight: .infinity).padding().accessibilityIdentifier("quote.side_preview") }
            }
            .safeAreaInset(edge: .bottom) {
                Button {
                    if saveVersion(), let pdfURL { sharing = ShareFile(url: pdfURL) }
                } label: { Label(versionSaved ? "quote.share_pdf" : "ui.save_share_pdf", systemImage: "square.and.arrow.up").frame(maxWidth: .infinity) }
                    .buttonStyle(.borderedProminent).controlSize(.large).padding().background(.bar)
                    .disabled(preparing || pdfURL == nil || snapshotData == nil).accessibilityIdentifier("quote.save_share")
            }
            .navigationTitle("quote.preview").navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .confirmationAction) { Button("common.done") { dismiss() } } }
            .task { await prepareExports() }
            .onChange(of: csvKind) { _, _ in prepareCSV() }
            .onChange(of: purchaseManager.isPro) { _, pro in if pro { snapshot = nil; snapshotData = nil; versionSaved = false; Task { await prepareExports() } } }
            .proPaywall(reason: $paywallReason)
            .sheet(item: $sharing) { FileShareSheet(url: $0.url) }
        }
    }
    private var pageCountText: String {
        let count = pdfURL.flatMap { PDFDocument(url: $0)?.pageCount } ?? 0
        return count == 1 ? AppLocalization.text("ui.page_single", locale: locale) : AppLocalization.format("ui.page_count", locale: locale, count)
    }
    @ViewBuilder private var documentPreview: some View {
        if let pdfURL {
            VStack(alignment: .leading) {
                PDFKitView(url: pdfURL).frame(minHeight: wide ? 450 : 300).accessibilityLabel("quote.document")
                NavigationLink { GeneratedPDFPreview(url: pdfURL) } label: {
                    Label(AppLocalization.text("quote.open_pdf_preview", locale: locale) + " · " + pageCountText, systemImage: "arrow.up.left.and.arrow.down.right")
                }.frame(minHeight: 44)
            }
        } else if preparing { ProgressView("quote.preparing").frame(maxWidth: .infinity, minHeight: 150) }
        else { ContentUnavailableView("export.error.title", systemImage: "doc.badge.ellipsis") }
    }
    private func prepareExports() async {
        preparing = true; exportError = nil
        await Task.yield()
        do {
#if DEBUG
            if ProcessInfo.processInfo.arguments.contains("--ui-export-error") && !simulatedFailureConsumed { simulatedFailureConsumed = true; throw CocoaError(.fileWriteUnknown) }
#endif
            if snapshot == nil {
                let data = try QuoteExportService.snapshotData(for: project, company: purchaseManager.isPro ? companies.first : nil, generatedAt: .now, includeBranding: !purchaseManager.isPro)
                snapshotData = data; snapshot = try QuoteExportService.decodeSnapshot(data)
            }
            if let snapshot { pdfURL = try QuoteExportService.pdfURL(snapshot: snapshot) }
            prepareCSV()
        } catch { exportError = error.localizedDescription }
        preparing = false
    }
    private func prepareCSV() {
        guard purchaseManager.isPro, let snapshot else { return }
        do { csvURL = try QuoteCSVRenderer.url(snapshot, kind: csvKind) }
        catch { csvURL = nil; exportError = error.localizedDescription }
    }
    @discardableResult private func saveVersion() -> Bool {
        if versionSaved { return true }
        guard let snapshotData else { return false }
        let entity = QuoteSnapshotEntity(projectID: project.id, payload: snapshotData)
        modelContext.insert(entity)
        versionSaved = PersistenceErrorCenter.shared.save(modelContext)
        if !versionSaved { modelContext.delete(entity) }
        return versionSaved
    }
}

struct GeneratedPDFPreview: View {
    let url: URL

    var body: some View {
        PDFKitView(url: url)
            .background(Color(uiColor: .secondarySystemBackground))
            .navigationTitle("quote.document")
        .toolbar { Text("\(PDFDocument(url: url)?.pageCount ?? 0)").accessibilityLabel("workflow.page_count") }
            .navigationBarTitleDisplayMode(.inline)
    }
}

struct PDFKitView: UIViewRepresentable {
    let url: URL

    func makeUIView(context: Context) -> PDFView {
        let view = PDFView()
        view.autoScales = true
        view.displayMode = .singlePageContinuous
        view.displayDirection = .vertical
        view.document = PDFDocument(url: url)
        return view
    }

    func updateUIView(_ view: PDFView, context: Context) {
        if view.document?.documentURL != url { view.document = PDFDocument(url: url) }
    }
}
