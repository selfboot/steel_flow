import SwiftUI
import SwiftData
import PDFKit

struct QuoteHistoryView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.locale) private var locale
    @Query(sort: \QuoteSnapshotEntity.createdAt, order: .reverse) private var snapshots: [QuoteSnapshotEntity]
    let project: ProjectEntity
    private var versions: [QuoteSnapshotEntity] { snapshots.filter { $0.projectID == project.id } }
    var body: some View {
        NavigationStack {
            List {
                if versions.isEmpty { ContentUnavailableView("workflow.history_empty", systemImage: "clock") }
                ForEach(Array(versions.enumerated()), id: \.element.id) { index, entry in
                    if let payload = try? QuoteExportService.decodeSnapshot(entry.payload) {
                        NavigationLink {
                            FrozenQuoteView(snapshot: payload, previous: index + 1 < versions.count ? try? QuoteExportService.decodeSnapshot(versions[index + 1].payload) : nil)
                        } label: {
                            VStack(alignment: .leading, spacing: 5) {
                                Text("v\(versions.count - index) · " + AppFormatters.date(payload.generatedAt, locale: locale)).font(.headline)
                                Text(AppFormatters.decimal(payload.totals.total, currencyCode: payload.currencyCode, locale: locale))
                                Text(payload.customerName).font(.caption).foregroundStyle(.secondary)
                            }
                        }
                    } else { Label("backup.error.corrupt", systemImage: "exclamationmark.triangle") }
                }
            }
            .navigationTitle("workflow.quote_history")
            .toolbar { ToolbarItem(placement: .confirmationAction) { Button("common.done") { dismiss() } } }
        }
    }
}

struct FrozenQuoteView: View {
    let snapshot: QuoteSnapshotPayload
    let previous: QuoteSnapshotPayload?
    @Environment(\.modelContext) private var modelContext
    @Environment(\.locale) private var locale
    @Query private var projects: [ProjectEntity]
    @State private var url: URL?
    @State private var error: String?
    @State private var copied = false
    @State private var paywallReason: ProPaywallReason?
    var body: some View {
        List {
            Section {
                LabeledContent("project.number", value: snapshot.projectNumber)
                LabeledContent("quote.valid_until", value: AppFormatters.date(snapshot.validUntil, locale: locale))
                LabeledContent("project.total", value: AppFormatters.decimal(snapshot.totals.total, currencyCode: snapshot.currencyCode, locale: locale))
                Text("workflow.frozen_help").font(.caption).foregroundStyle(.secondary)
            }
            if let previous {
                Section("workflow.version_comparison") {
                    if previous.currencyCode == snapshot.currencyCode {
                        LabeledContent("workflow.total_change", value: AppFormatters.decimal(snapshot.totals.total - previous.totals.total, currencyCode: snapshot.currencyCode, locale: locale))
                    } else { Text(previous.currencyCode + " → " + snapshot.currencyCode) }
                    LabeledContent("workflow.before", value: String(previous.lines.count))
                    LabeledContent("workflow.after", value: String(snapshot.lines.count))
                    ForEach(snapshot.lines, id: \.itemID) { line in
                        let old = previous.lines.first { $0.itemID == line.itemID }
                        if old == nil || old?.customerQuoteAmount != line.customerQuoteAmount || old?.quantity != line.quantity || old?.lengthValue != line.lengthValue || old?.geometry != line.geometry || old?.materialGrade != line.materialGrade {
                            Text((line.descriptionText.isEmpty ? AppLocalization.text("profile." + line.profile, locale: locale) : line.descriptionText) + " · " + AppFormatters.decimal(line.customerQuoteAmount, currencyCode: snapshot.currencyCode, locale: locale))
                        }
                    }
                }
            }
            if let url {
                NavigationLink { GeneratedPDFPreview(url: url) } label: { Label("quote.open_pdf_preview", systemImage: "doc.text") }
                ShareLink(item: url) { Label("quote.share_pdf", systemImage: "square.and.arrow.up") }
            } else if let error { Text(error) } else { ProgressView() }
            Button("workflow.copy_revision", systemImage: "doc.badge.plus") { copyRevision() }
                .disabled(copied)
            if copied { Text("calculator.saved") }
        }
        .navigationTitle("workflow.quote_history")
        .task { do { url = try QuoteExportService.pdfURL(snapshot: snapshot) } catch { self.error = error.localizedDescription } }
        .proPaywall(reason: $paywallReason) { copyRevision() }
    }
    private func copyRevision() {
        guard PurchaseManager.shared.isPro else { paywallReason = .duplicate; return }
        let project = QuoteSnapshotRestorer.project(snapshot)
        modelContext.insert(project)
        copied = PersistenceErrorCenter.shared.save(modelContext)
    }
}

@MainActor enum QuoteSnapshotRestorer {
    static func project(_ snapshot: QuoteSnapshotPayload) -> ProjectEntity {
        let project = ProjectEntity(name: snapshot.projectName, customerName: snapshot.customerName,
            quoteLanguage: snapshot.quoteLanguage, unitSystem: UnitSystem(rawValue: snapshot.unitSystemRaw ?? "") ?? .metric,
            currencyCode: snapshot.currencyCode, paperSize: PaperSize(rawValue: snapshot.paperSize) ?? .a4)
        project.customerContact = snapshot.customerContact ?? ""; project.terms = snapshot.terms
        project.taxPercentText = snapshot.taxPercent.description; project.markupPercentText = snapshot.profitPercent.description
        project.profitMode = ProfitMode(rawValue: snapshot.profitMode) ?? .markup
        project.validDays = max(1, Calendar.current.dateComponents([.day], from: snapshot.generatedAt, to: snapshot.validUntil).day ?? 30)
        project.showQuoteMass = snapshot.showMass ?? true; project.showQuoteUnitPrice = snapshot.showUnitPrice ?? false
        project.items = snapshot.lines.enumerated().compactMap { index, line in
            guard let profile = ProfileKind(rawValue: line.profile), let unit = LengthUnit(rawValue: line.lengthUnit), let basis = PriceBasis(rawValue: line.priceBasis) else { return nil }
            return CalculationItemEntity(profile: profile, geometry: line.geometry, materialID: line.materialID, materialName: line.materialName,
                densityKgPerM3: line.densityKgPerM3, lengthValue: line.lengthValue, lengthUnit: unit, quantity: line.quantity,
                wastePercent: line.wastePercent, priceBasis: basis, unitPrice: line.unitPrice, processingFee: line.processingFee,
                otherFee: line.otherFee, priceSource: PriceSource(rawValue: line.priceSource) ?? .manual, priceSourceName: line.priceSourceName,
                priceRegion: line.priceRegion, materialGrade: line.materialGrade, priceIncludesTax: line.priceIncludesTax,
                priceEffectiveAt: line.priceEffectiveAt, description: line.descriptionText, internalNote: line.internalNote, sortIndex: index)
        }
        return project
    }
}
