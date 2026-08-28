import SwiftUI
import SwiftData
import PDFKit

struct QuotePreviewView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(\.locale) private var locale
    @Query private var companies: [CompanyProfileEntity]
    let project: ProjectEntity
    @State private var pdfURL: URL?
    @State private var csvURL: URL?
    @State private var exportError: String?
    @State private var purchaseManager = PurchaseManager.shared

    private var summary: ProjectSummary { ProjectCalculator.summarize(project) }
    private var quoteLocale: Locale { Locale(identifier: project.quoteLanguage) }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            VStack(alignment: .leading) {
                                Text(purchaseManager.isPro ? (companies.first.flatMap { $0.companyName.isEmpty ? nil : $0.companyName } ?? "SteelFlow") : "SteelFlow").font(.headline)
                                Text(project.projectNumber).font(.caption.monospaced()).foregroundStyle(.secondary)
                            }
                            Spacer()
                            Text(AppLocalization.text("quote.title", locale: quoteLocale)).font(.title2.bold()).foregroundStyle(SteelFlowTheme.steelBlue)
                        }
                        Divider()
                        metadataRow(
                            label: AppLocalization.text("project.customer", locale: quoteLocale),
                            value: project.customerName.isEmpty ? "—" : project.customerName
                        )
                        metadataRow(
                            label: AppLocalization.text("project.quote_language", locale: locale),
                            value: AppLocalization.text(project.quoteLanguage == "zh-Hans" ? "language.chinese" : "language.english", locale: locale)
                        )
                        metadataRow(
                            label: AppLocalization.text("settings.paper", locale: locale),
                            value: AppLocalization.text(project.paperSize == .a4 ? "paper.a4" : "paper.letter", locale: locale)
                        )
                    }
                }
                Section(AppLocalization.text("project.items", locale: quoteLocale)) {
                    ForEach(summary.lines) { line in
                        QuoteLineRow(
                            title: line.item.descriptionText.isEmpty ? AppLocalization.text("profile.\(line.item.profile.rawValue)", locale: quoteLocale) : line.item.descriptionText,
                            subtitle: "\(MaterialCatalog.localizedName(materialID: line.item.materialID, fallback: line.item.materialName, locale: quoteLocale)) · × \(line.item.quantity)",
                            mass: "\(AppFormatters.number(line.result.totalMassKg, maximumFractionDigits: 2, locale: quoteLocale)) kg",
                            amount: AppFormatters.decimal(line.customerQuoteAmount, currencyCode: project.currencyCode, locale: quoteLocale)
                        )
                    }
                }
                Section(AppLocalization.text("project.summary", locale: quoteLocale)) {
                    quoteTotalRow("quote.subtotal", value: summary.pricing.preTax)
                    quoteTotalRow("project.tax", value: summary.pricing.tax)
                    quoteTotalRow("project.total", value: summary.pricing.total).font(.headline)
                }
                if let pdfURL {
                    Section("quote.document") {
                        NavigationLink {
                            GeneratedPDFPreview(url: pdfURL)
                        } label: {
                            Label("quote.open_pdf_preview", systemImage: "doc.text.image")
                        }
                    }
                }
                Section("quote.export") {
                    if let pdfURL {
                        ShareLink(item: pdfURL, preview: SharePreview(pdfURL.lastPathComponent)) {
                            Label("quote.share_pdf", systemImage: "doc.richtext").frame(maxWidth: .infinity)
                        }
                    }
                    if let csvURL, purchaseManager.isPro {
                        ShareLink(item: csvURL, preview: SharePreview(csvURL.lastPathComponent)) {
                            Label("quote.share_csv", systemImage: "tablecells").frame(maxWidth: .infinity)
                        }
                    } else if !purchaseManager.isPro {
                        Label("purchase.limit.csv", systemImage: "lock.fill").foregroundStyle(.secondary)
                    }
                    if pdfURL == nil && csvURL == nil { ProgressView("quote.preparing") }
                }
            }
            .navigationTitle("quote.preview")
            .toolbar { ToolbarItem(placement: .confirmationAction) { Button("common.done") { dismiss() } } }
            .task { prepareExports() }
            .alert("export.error.title", isPresented: Binding(get: { exportError != nil }, set: { if !$0 { exportError = nil } })) {
                Button("common.ok", role: .cancel) {}
            } message: { Text(exportError ?? "") }
        }
    }

    private func quoteTotalRow(_ key: String, value: Decimal) -> some View {
        LabeledContent {
            Text(AppFormatters.decimal(value, currencyCode: project.currencyCode, locale: quoteLocale))
        } label: {
            Text(AppLocalization.text(key, locale: quoteLocale))
        }
    }

    private func metadataRow(label: String, value: String) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 12) {
            Text(label)
            Spacer(minLength: 8)
            Text(value)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.trailing)
                .lineLimit(2)
                .minimumScaleFactor(0.8)
        }
    }

    private func prepareExports() {
        do {
            let generatedAt = Date.now
            let company = purchaseManager.isPro ? companies.first : nil
            let includeBranding = !purchaseManager.isPro
            let snapshot = try QuoteExportService.snapshotData(for: project, company: company, generatedAt: generatedAt, includeBranding: includeBranding)
            pdfURL = try QuoteExportService.pdfURL(for: project, company: company, generatedAt: generatedAt, includeBranding: includeBranding)
            csvURL = purchaseManager.isPro ? try QuoteExportService.csvURL(for: project, generatedAt: generatedAt) : nil
            modelContext.insert(QuoteSnapshotEntity(projectID: project.id, payload: snapshot))
            try modelContext.save()
        } catch { exportError = error.localizedDescription }
    }
}

private struct GeneratedPDFPreview: View {
    let url: URL

    var body: some View {
        PDFKitView(url: url)
            .background(Color(uiColor: .secondarySystemBackground))
            .navigationTitle("quote.document")
            .navigationBarTitleDisplayMode(.inline)
    }
}

private struct PDFKitView: UIViewRepresentable {
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

private struct QuoteLineRow: View {
    let title: String
    let subtitle: String
    let mass: String
    let amount: String
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    var body: some View {
        if dynamicTypeSize.isAccessibilitySize || horizontalSizeClass == .compact {
            VStack(alignment: .leading, spacing: 6) {
                description
                HStack {
                    Text(mass).font(.caption.monospacedDigit()).fixedSize(horizontal: true, vertical: false)
                    Spacer()
                    Text(amount).font(.subheadline.monospacedDigit()).fixedSize(horizontal: true, vertical: false)
                }
            }
        } else {
            HStack(alignment: .top, spacing: 12) {
                description
                    .frame(maxWidth: .infinity, alignment: .leading)
                VStack(alignment: .trailing, spacing: 3) {
                    Text(mass).font(.caption.monospacedDigit())
                    Text(amount).font(.subheadline.monospacedDigit())
                }
                .fixedSize(horizontal: true, vertical: true)
            }
        }
    }

    private var description: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(title)
                .font(.subheadline.weight(.semibold))
                .fixedSize(horizontal: false, vertical: true)
            Text(subtitle)
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}
