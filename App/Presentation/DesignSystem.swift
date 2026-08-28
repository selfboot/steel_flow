import SwiftUI

enum SteelFlowTheme {
    static let steelBlue = Color(red: 0.04, green: 0.43, blue: 0.62)
    static let deepSteel = Color(red: 0.03, green: 0.20, blue: 0.27)
    static let surface = Color(uiColor: .secondarySystemGroupedBackground)
}

struct ResultMetric: View {
    let title: LocalizedStringResource
    let value: String
    let emphasized: Bool

    init(_ title: LocalizedStringResource, value: String, emphasized: Bool = false) {
        self.title = title
        self.value = value
        self.emphasized = emphasized
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title).font(.caption).foregroundStyle(.secondary)
            Text(value)
                .font(emphasized ? .title2.bold() : .headline)
                .foregroundStyle(emphasized ? SteelFlowTheme.steelBlue : .primary)
                .minimumScaleFactor(0.72)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(SteelFlowTheme.surface, in: RoundedRectangle(cornerRadius: 14))
    }
}
