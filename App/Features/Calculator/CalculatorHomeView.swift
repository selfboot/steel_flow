import SwiftUI
import SwiftData

struct CalculatorHomeView: View {
    @Query(sort: \CalculationItemEntity.updatedAt, order: .reverse) private var recentItems: [CalculationItemEntity]
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    private var columns: [GridItem] {
        if dynamicTypeSize.isAccessibilitySize {
            return [GridItem(.flexible())]
        }
        if horizontalSizeClass == .regular {
            return [GridItem(.adaptive(minimum: 190), spacing: 12)]
        }
        return [GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10)]
    }

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 18) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("calculator.hero.title")
                        .font(dynamicTypeSize.isAccessibilitySize ? .headline : .title2.bold())
                    Text("calculator.hero.subtitle")
                        .font(dynamicTypeSize.isAccessibilitySize ? .caption : .subheadline)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                LazyVGrid(columns: columns, alignment: .leading, spacing: 10) {
                    ForEach(ProfileKind.allCases) { profile in
                        NavigationLink(value: profile) {
                            ProfileCard(profile: profile)
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel(Text(profile.localizationKey))
                        .accessibilityIdentifier("profile.\(profile.rawValue)")
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
        HStack(alignment: .center, spacing: 10) {
            Image(systemName: profile.symbol)
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(SteelFlowTheme.steelBlue)
                .frame(width: 36, height: 36)
                .background(SteelFlowTheme.steelBlue.opacity(0.1), in: RoundedRectangle(cornerRadius: 9))
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 2) {
                Text(profile.localizationKey)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)
                    .lineLimit(2)
                Text(profile.summaryKey)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
            .multilineTextAlignment(.leading)
            .layoutPriority(1)
        }
        .frame(maxWidth: .infinity, minHeight: 58, alignment: .leading)
        .padding(.horizontal, 12)
        .padding(.vertical, 9)
        .background(SteelFlowTheme.surface, in: RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(.separator.opacity(0.22)))
    }
}

private struct RecentCalculationRow: View {
    let item: CalculationItemEntity
    @Environment(\.locale) private var locale

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: item.profile.symbol)
                .foregroundStyle(SteelFlowTheme.steelBlue)
                .frame(width: 34, height: 34)
                .background(SteelFlowTheme.steelBlue.opacity(0.1), in: RoundedRectangle(cornerRadius: 8))
            VStack(alignment: .leading) {
                Text(item.profile.localizationKey).font(.subheadline.weight(.semibold))
                Text("\(AppFormatters.number(item.lengthValue, locale: locale)) \(item.lengthUnit.rawValue) × \(item.quantity)")
                    .font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
            if let result = try? item.calculation() {
                Text("\(AppFormatters.number(result.totalMassKg, maximumFractionDigits: 2, locale: locale)) kg")
                    .font(.subheadline.monospacedDigit())
            }
        }
        .padding(12)
        .background(.background, in: RoundedRectangle(cornerRadius: 12))
    }
}
