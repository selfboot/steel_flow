import SwiftUI
import SwiftData

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

    var body: some View {
        NavigationStack {
            List {
                Section {
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            VStack(alignment: .leading) {
                                Text(companies.first.flatMap { $0.companyName.isEmpty ? nil : $0.companyName } ?? "SteelFlow").font(.headline)
                                Text(project.projectNumber).font(.caption.monospaced()).foregroundStyle(.secondary)
                            }
                            Spacer()
                            Text("quote.title").font(.title2.bold()).foregroundStyle(SteelFlowTheme.steelBlue)
                        }
                        Divider()
                        LabeledContent("project.customer", value: project.customerName.isEmpty ? "—" : project.customerName)
                        LabeledContent("project.quote_language", value: project.quoteLanguage == "zh-Hans" ? String(localized: "language.chinese") : String(localized: "language.english"))
                        LabeledContent("settings.paper", value: project.paperSize == .a4 ? "A4" : "US Letter")
                    }
                }
                Section("project.items") {
                    ForEach(summary.lines) { line in
                        QuoteLineRow(
                            title: line.item.descriptionText.isEmpty ? String(localized: line.item.profile.localizationKey) : line.item.descriptionText,
                            subtitle: "\(MaterialCatalog.localizedName(materialID: line.item.materialID, fallback: line.item.materialName, locale: locale)) · × \(line.item.quantity)",
                            mass: "\(AppFormatters.number(line.result.totalMassKg, maximumFractionDigits: 2, locale: locale)) kg",
                            amount: AppFormatters.decimal(line.materialSubtotal, currencyCode: project.currencyCode, locale: locale)
                        )
                    }
                }
                Section("project.summary") {
                    LabeledContent("project.material_subtotal", value: money(summary.pricing.materialSubtotal))
                    LabeledContent("project.fees", value: money(summary.pricing.fees))
                    LabeledContent(project.profitMode == .markup ? "project.markup" : "project.margin", value: money(summary.pricing.profit))
                    LabeledContent("project.tax", value: money(summary.pricing.tax))
                    LabeledContent("project.total", value: money(summary.pricing.total)).font(.headline)
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

    private func money(_ value: Decimal) -> String { AppFormatters.decimal(value, currencyCode: project.currencyCode, locale: locale) }
    private func prepareExports() {
        do {
            let generatedAt = Date.now
            let snapshot = try QuoteExportService.snapshotData(for: project, generatedAt: generatedAt)
            pdfURL = try QuoteExportService.pdfURL(for: project, company: companies.first, generatedAt: generatedAt)
            csvURL = try QuoteExportService.csvURL(for: project, generatedAt: generatedAt)
            modelContext.insert(QuoteSnapshotEntity(projectID: project.id, payload: snapshot))
            try modelContext.save()
        } catch { exportError = error.localizedDescription }
    }
}

private struct QuoteLineRow: View {
    let title: String
    let subtitle: String
    let mass: String
    let amount: String
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        if dynamicTypeSize.isAccessibilitySize {
            VStack(alignment: .leading, spacing: 6) {
                description
                HStack {
                    Text(mass).font(.caption.monospacedDigit())
                    Spacer()
                    Text(amount).font(.subheadline.monospacedDigit())
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
