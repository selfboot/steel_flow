import SwiftUI

/// An original geometric mark used only in clearly labelled examples and marketing fixtures.
struct BrandSampleLogo: View {
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 14).fill(Color(red: 0.12, green: 0.28, blue: 0.38))
            Image(systemName: "building.2.fill")
                .font(.system(size: 48, weight: .semibold))
                .foregroundStyle(.white)
        }
        .frame(width: 96, height: 96)
    }

    @MainActor static func pngData() -> Data? {
        let renderer = ImageRenderer(content: BrandSampleLogo())
        renderer.scale = 2
        return renderer.uiImage?.pngData()
    }
}
