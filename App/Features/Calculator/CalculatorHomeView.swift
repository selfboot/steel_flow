import SwiftUI
import SwiftData

struct CalculatorHomeView: View {
    @Query(sort: \CalculationItemEntity.updatedAt, order: .reverse) private var recentItems: [CalculationItemEntity]
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    private let columns = [GridItem(.adaptive(minimum: 145), spacing: 12)]

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 22) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("calculator.hero.title").font(.title2.bold())
                    Text("calculator.hero.subtitle").font(.subheadline).foregroundStyle(.secondary)
                }

                LazyVGrid(columns: columns, spacing: 12) {
                    ForEach(ProfileKind.allCases) { profile in
                        NavigationLink(value: profile) {
                            ProfileCard(profile: profile)
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel(Text(profile.localizationKey))
                    }
                }

                if !recentItems.isEmpty {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("calculator.recent").font(.headline)
                        ForEach(recentItems.prefix(5)) { item in
                            RecentCalculationRow(item: item)
                        }
                    }
                }
            }
            .padding()
            .frame(maxWidth: horizontalSizeClass == .regular ? 760 : .infinity)
            .frame(maxWidth: .infinity)
        }
        .background(Color(uiColor: .systemGroupedBackground))
        .navigationTitle("tab.calculate")
        .navigationDestination(for: ProfileKind.self) { CalculatorEditorView(profile: $0) }
    }
}

private struct ProfileCard: View {
    let profile: ProfileKind

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Image(systemName: profile.symbol)
                .font(.system(size: 28, weight: .semibold))
                .foregroundStyle(SteelFlowTheme.steelBlue)
                .frame(height: 32)
            Text(profile.localizationKey)
                .font(.headline)
                .foregroundStyle(.primary)
                .multilineTextAlignment(.leading)
        }
        .frame(maxWidth: .infinity, minHeight: 100, alignment: .leading)
        .padding(16)
        .background(SteelFlowTheme.surface, in: RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(.separator.opacity(0.25)))
    }
}

private struct RecentCalculationRow: View {
    let item: CalculationItemEntity

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: item.profile.symbol)
                .foregroundStyle(SteelFlowTheme.steelBlue)
                .frame(width: 34, height: 34)
                .background(SteelFlowTheme.steelBlue.opacity(0.1), in: RoundedRectangle(cornerRadius: 8))
            VStack(alignment: .leading) {
                Text(item.profile.localizationKey).font(.subheadline.weight(.semibold))
                Text("\(AppFormatters.number(item.lengthValue)) \(item.lengthUnit.rawValue) × \(item.quantity)")
                    .font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
            if let result = try? item.calculation() {
                Text("\(AppFormatters.number(result.totalMassKg, maximumFractionDigits: 2)) kg")
                    .font(.subheadline.monospacedDigit())
            }
        }
        .padding(12)
        .background(.background, in: RoundedRectangle(cornerRadius: 12))
    }
}
