import SwiftUI
import SwiftData

struct CalculatorHomeView: View {
    @Query private var projects: [ProjectEntity]
    @Query(sort: \CalculationItemEntity.updatedAt, order: .reverse) private var recentItems: [CalculationItemEntity]
    @State private var library = CalculationLibrary.shared
    @Environment(\.locale) private var locale
    @AppStorage("app.unitSystem") private var unitRaw = UnitSystem.metric.rawValue
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

                if let draft = library.latestQuickDraft {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("ui.continue_draft").font(.headline)
                        NavigationLink { CalculatorEditorView(profile: draft.profile, restoredState: draft) } label: {
                            HStack(spacing: 12) {
                                Image(systemName: draft.profile.symbol).font(.title2).foregroundStyle(SteelFlowTheme.steelBlue).frame(width: 42, height: 42)
                                SavedCalculationRow(record: SavedCalculation(state: draft), isEmbedded: true)
                                Image(systemName: "chevron.right").font(.caption.weight(.semibold)).foregroundStyle(.secondary)
                            }.padding(14).background(SteelFlowTheme.surface, in: RoundedRectangle(cornerRadius: 16))
                        }.buttonStyle(PressableCardStyle()).accessibilityIdentifier("home.continue")
                    }
                }
                if !library.records.filter(\.isFavorite).isEmpty {
                    librarySection(favorites: true, limit: 3)
                }
                Text("ui.new_calculation").font(.headline)
                LazyVGrid(columns: columns, alignment: .leading, spacing: 10) {
                    ForEach(ProfileKind.allCases) { profile in
                        NavigationLink(value: profile) { ProfileCard(profile: profile) }
                            .buttonStyle(PressableCardStyle())
                            .accessibilityLabel(Text(profile.localizationKey))
                            .accessibilityIdentifier("profile.\(profile.rawValue)")
                    }
                }
                if !library.records.filter({ !$0.isFavorite }).isEmpty { librarySection(favorites: false, limit: 4) }

                if library.records.isEmpty && !recentItems.isEmpty {
                    Text("calculator.recent").font(.headline)
                    ForEach(recentItems.prefix(5)) { item in
                        NavigationLink {
                            CalculatorEditorView(profile: item.profile, restoredState: DraftState(item: item, currency: projects.first(where: { $0.items.contains(where: { $0.id == item.id }) })?.currencyCode ?? "USD", locale: locale))
                        } label: { RecentCalculationRow(item: item) }
                    }
                }

            }
            .padding(.horizontal, 16)
            .padding(.bottom, 16)
            .frame(maxWidth: horizontalSizeClass == .regular ? 760 : .infinity)
            .frame(maxWidth: .infinity)
        }
        .background(Color(uiColor: .systemGroupedBackground))
        .navigationTitle("tab.calculate")
        .modifier(RootTabLayout())
        .navigationDestination(for: ProfileKind.self) { CalculatorEditorView(profile: $0) }
    }
    private func librarySection(favorites: Bool, limit: Int) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(favorites ? "workflow.favorites" : "calculator.recent").font(.headline)
                Spacer()
                NavigationLink("ui.view_all") { CalculationLibraryList(favorites: favorites) }.frame(minHeight: 44)
            }
            ForEach(Array(library.records.filter { $0.isFavorite == favorites }.prefix(limit))) { record in
                NavigationLink { CalculatorEditorView(profile: record.state.profile, restoredState: record.state) } label: { SavedCalculationRow(record: record) }
                    .buttonStyle(PressableCardStyle())
            }
        }
    }

}

struct ProfileCard: View {
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
                    .fixedSize(horizontal: false, vertical: true)
                Text(profile.summaryKey)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
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
        .background(SteelFlowTheme.surface, in: RoundedRectangle(cornerRadius: 14))
    }
}

private struct SavedCalculationRow: View {
    let record: SavedCalculation
    var isEmbedded = false
    @Environment(\.locale) private var locale
    @AppStorage("app.unitSystem") private var unitRaw = UnitSystem.metric.rawValue
    @Query private var materials: [MaterialEntity]
    private var draft: CalculatorDraft { record.state.makeDraft(locale: locale) }
    private var subtitle: String {
        let d = draft
        let geometry = d.profile.dimensionFields.compactMap { d.dimensionTexts[$0] }.joined(separator: " × ")
        return geometry + " " + (d.profile == .customArea ? d.areaUnit.rawValue : d.geometryUnit.rawValue) + " · " + d.lengthText + " " + d.lengthUnit.rawValue + " × " + (d.quantity == Int.min ? "—" : String(d.quantity))
    }
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(record.state.description.isEmpty ? AppLocalization.text("profile." + record.state.profile.rawValue, locale: locale) : record.state.description).font(.headline)
                Spacer()
                if record.isFavorite { Image(systemName: "star.fill").foregroundStyle(.orange).accessibilityLabel("workflow.favorites") }
            }
            Text(subtitle).font(.caption).foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true)
            let name = materials.first { $0.id == record.state.materialID }?.name ?? record.state.materialID
            Text(MaterialCatalog.localizedName(materialID: record.state.materialID, fallback: name, locale: locale)).font(.caption).foregroundStyle(.secondary)
            if case .success(let result) = draft.result(locale: locale) {
                Text(AppFormatters.mass(result.totalMassKg, system: UnitSystem(rawValue: unitRaw) ?? .metric, locale: locale)).font(.subheadline.bold()).monospacedDigit()
            }
        }.foregroundStyle(.primary).frame(maxWidth: .infinity, alignment: .leading).padding(isEmbedded ? 0 : 12)
            .background(isEmbedded ? Color.clear : SteelFlowTheme.surface, in: RoundedRectangle(cornerRadius: 14))
    }
}

private struct CalculationLibraryList: View {
    let favorites: Bool
    @State private var library = CalculationLibrary.shared
    @State private var search = ""
    @Environment(\.locale) private var locale
    @Query private var materials: [MaterialEntity]
    private var visible: [SavedCalculation] {
        library.records.filter { record in
            let name = materials.first(where: { $0.id == record.state.materialID })?.name ?? record.state.materialID
            let terms = [record.state.description, record.state.grade,
                         AppLocalization.text("profile." + record.state.profile.rawValue, locale: locale),
                         MaterialCatalog.localizedName(materialID: record.state.materialID, fallback: name, locale: locale)]
            return (!favorites || record.isFavorite) && (search.isEmpty || terms.contains { $0.localizedStandardContains(search) })
        }
    }
    var body: some View {
        List {
            if visible.isEmpty {
                if search.isEmpty { ContentUnavailableView(favorites ? "ui.favorites_empty" : "ui.recent_empty", systemImage: favorites ? "star" : "clock") }
                else { ContentUnavailableView.search(text: search); Button("ui.clear_search") { search = "" } }
            }
            ForEach(visible) { record in
                VStack {
                    NavigationLink { CalculatorEditorView(profile: record.state.profile, restoredState: record.state) } label: { SavedCalculationRow(record: record) }
                    Button(record.isFavorite ? "ui.unfavorite" : "workflow.favorite", systemImage: record.isFavorite ? "star.slash" : "star") { library.toggleFavorite(record.id) }.frame(minHeight: 44)
                }
                .swipeActions { Button("common.delete", role: .destructive) { library.remove(record.id) } }
            }
        }.searchable(text: $search).navigationTitle(favorites ? "workflow.favorites" : "calculator.recent")
    }
}
