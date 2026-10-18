import SwiftUI
import PDFKit

/// A real renderer output of this quote, with an explicitly labelled example company.
/// The sample is read-only and is never saved or offered for export.
struct QuoteBrandingPreview: View {
    let snapshot: QuoteSnapshotPayload
    @Environment(\.locale) private var locale
    @State private var preview: UIImage?

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("purchase.quote.sample", systemImage: "doc.richtext")
                .font(.subheadline.weight(.semibold))
            if let preview {
                Image(uiImage: preview)
                    .resizable()
                    .scaledToFit()
                    .frame(maxHeight: 320)
                    .frame(maxWidth: .infinity)
                    .accessibilityLabel(Text("purchase.quote.sample"))
            }
            Text("quote.pro.free_export")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(16)
        .background(SteelFlowTheme.surface, in: RoundedRectangle(cornerRadius: 20))
        .task(id: locale.identifier) {
            var sample = snapshot.localized(for: locale)
            sample.includeBranding = false
            sample.quoteStyleRaw = QuoteStyle.blue.rawValue
            sample.company = .init(
                logoData: BrandSampleLogo.pngData(),
                companyName: AppLocalization.text("purchase.quote.your_company", locale: locale),
                contactName: "", email: "", phone: "", address: ""
            )
            guard let url = try? QuotePDFRenderer.render(sample) else { return }
            defer { try? FileManager.default.removeItem(at: url) }
            preview = PDFDocument(url: url)?.page(at: 0)?.thumbnail(of: CGSize(width: 700, height: 990), for: .mediaBox)
        }
    }
}
