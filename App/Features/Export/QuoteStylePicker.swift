import SwiftUI
import PDFKit

struct QuoteStylePicker: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.locale) private var locale
    @Environment(\.dynamicTypeSize) private var typeSize
    let selected: QuoteStyle
    var helpKey = "quote.style.help"
    let onSelect: (QuoteStyle) -> Void
    @State private var thumbnails: [QuoteStyle: UIImage] = [:]
    @State private var failed = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text(LocalizedStringKey(helpKey)).font(.subheadline).foregroundStyle(.secondary)
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: typeSize.isAccessibilitySize ? 280 : 150), spacing: 16)], spacing: 20) {
                        ForEach(QuoteStyle.allCases) { style in
                            Button {
                                onSelect(style)
                                dismiss()
                            } label: {
                                VStack(alignment: .leading, spacing: 10) {
                                    ZStack {
                                        Color.white
                                        if let thumbnail = thumbnails[style] {
                                            Image(uiImage: thumbnail).resizable().scaledToFit()
                                        } else if failed {
                                            Image(systemName: "doc.text").font(.largeTitle).foregroundStyle(.gray)
                                        } else { ProgressView().tint(.gray) }
                                    }
                                    .aspectRatio(595.2 / 841.8, contentMode: .fit)
                                    .clipShape(RoundedRectangle(cornerRadius: 4))
                                    .overlay(RoundedRectangle(cornerRadius: 4).stroke(Color.primary.opacity(0.1)))
                                    HStack(alignment: .top) {
                                        Text(LocalizedStringKey(style.titleKey)).font(.headline)
                                        Spacer(minLength: 4)
                                        Image(systemName: selected == style ? "checkmark.circle.fill" : "circle")
                                            .foregroundStyle(selected == style ? Color.accentColor : Color.secondary)
                                    }
                                    Text(LocalizedStringKey(style.detailKey)).font(.caption).foregroundStyle(.secondary)
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                                .padding(12)
                                .background(Color(uiColor: .secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 14))
                                .overlay(RoundedRectangle(cornerRadius: 14).stroke(selected == style ? Color.accentColor : .clear, lineWidth: 2))
                            }
                            .buttonStyle(.plain)
                            .accessibilityIdentifier("quote.style.\(style.rawValue)")
                            .accessibilityAddTraits(selected == style ? .isSelected : [])
                        }
                    }
                }.padding()
            }
            .background(Color(uiColor: .systemGroupedBackground))
            .localizedNavigationTitle("quote.style.title")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("common.cancel") { dismiss() } } }
            .task(id: locale.identifier) {
                thumbnails = [:]; failed = false
                await loadThumbnails()
            }
        }
    }

    @MainActor private func loadThumbnails() async {
        do {
            var sample = try QuoteStyleSample.snapshot(language: AppLanguage.resolve(locale).rawValue)
            for style in QuoteStyle.allCases {
                guard !Task.isCancelled else { return }
                sample.quoteStyleRaw = style.rawValue
                let url = try QuotePDFRenderer.render(sample)
                defer { try? FileManager.default.removeItem(at: url) }
                if let page = PDFDocument(url: url)?.page(at: 0) {
                    thumbnails[style] = page.thumbnail(of: CGSize(width: 440, height: 623), for: .mediaBox)
                }
                await Task.yield()
            }
        } catch { failed = true }
    }
}

/// A compact illustrative quote, using the same renderer as exported documents.
@MainActor enum QuoteStyleSample {
    static func snapshot(language: String) throws -> QuoteSnapshotPayload {
        let project = ProjectEntity(name: "Sample", projectNumber: "Q-2026-048", customerName: "Atelier 24", quoteLanguage: language, currencyCode: "EUR")
        project.taxPercentText = "10"
        for (index, diameter) in [60.3, 88.9, 114.3].enumerated() {
            project.items.append(CalculationItemEntity(profile: .roundTube,
                geometry: .init(values: [.outerDiameter: diameter, .wallThickness: 3.2], lengthUnit: .millimeter),
                materialID: "carbon-steel", materialName: "Carbon steel", densityKgPerM3: 7850,
                lengthValue: 6, lengthUnit: .meter, quantity: (index + 1) * 4, wastePercent: 0,
                priceBasis: .perKilogram, unitPrice: 2.8, materialGrade: "S235JR", sortIndex: index))
        }
        let company = CompanyProfileEntity(companyName: "NORTHLINE METALS")
        company.email = "quotes@example.com"
        return try QuoteExportService.decodeSnapshot(QuoteExportService.snapshotData(for: project, company: company,
            generatedAt: Date(timeIntervalSince1970: 1_790_553_600), includeBranding: false, locale: Locale(identifier: language)))
    }
}
