import SwiftUI
import SwiftData

struct CalculatorHomeView: View {
    @Query private var projects: [ProjectEntity]
    @Query(sort: \CalculationItemEntity.updatedAt, order: .reverse) private var recentItems: [CalculationItemEntity]
    @State private var library = CalculationLibrary.shared
    @State private var openedDraft: DraftState?
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
                                SavedCalculationRow(record: SavedCalculation(state: draft), isEmbedded: true)
                                PolishedSymbol(systemName: "chevron.right").font(.caption.weight(.semibold)).foregroundStyle(.secondary)
                            }.padding(12).background(SteelFlowTheme.surface, in: RoundedRectangle(cornerRadius: 16))
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
                    VStack(spacing: 0) {
                        ForEach(Array(recentItems.prefix(5).enumerated()), id: \.element.id) { index, item in
                            if index > 0 { Divider().padding(.leading, 60) }
                            NavigationLink {
                                CalculatorEditorView(profile: item.profile, restoredState: DraftState(item: item, currency: projects.first(where: { $0.items.contains(where: { $0.id == item.id }) })?.currencyCode ?? "USD", locale: locale))
                            } label: { RecentCalculationRow(item: item) }
                            .buttonStyle(PressableCardStyle())
                        }
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
        .navigationDestination(item: $openedDraft) { state in
            CalculatorEditorView(profile: state.profile, restoredState: state)
        }
    }
    private func librarySection(favorites: Bool, limit: Int) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(favorites ? "workflow.favorites" : "calculator.recent").font(.headline)
                Spacer()
                NavigationLink("ui.view_all") { CalculationLibraryList(favorites: favorites) }.frame(minHeight: 44)
            }
            VStack(spacing: 0) {
                ForEach(Array(library.records.filter { $0.isFavorite == favorites }.prefix(limit).enumerated()), id: \.element.id) { index, record in
                    if index > 0 { Divider().padding(.leading, 60) }
                    HStack(spacing: 8) {
                        Button { openedDraft = record.state } label: {
                            SavedCalculationRow(record: record, isEmbedded: true, showsFavorite: false)
                                .contentShape(Rectangle())
                        }
                        .buttonStyle(PressableCardStyle())
                        if favorites {
                            Button { library.toggleFavorite(record.id) } label: {
                                PolishedSymbol(systemName: "star.fill")
                                    .font(.body.weight(.medium))
                                    .foregroundStyle(.orange)
                                    .frame(width: 44, height: 44)
                                    .contentShape(Rectangle())
                            }
                            .buttonStyle(.borderless)
                            .accessibilityLabel("ui.unfavorite")
                            .accessibilityIdentifier("home.favorite.\(record.id)")
                        }
                    }
                    .padding(.vertical, 8)
                }
            }
        }
    }

}

struct ProfileCard: View {
    let profile: ProfileKind

    var body: some View {
        HStack(alignment: .center, spacing: 8) {
            ProfileMaterialIcon(profile: profile, width: 52, height: 56)
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
        .frame(maxWidth: .infinity, minHeight: 58, maxHeight: .infinity, alignment: .leading)
        .padding(.horizontal, 12)
        .padding(.vertical, 9)
        .background(SteelFlowTheme.surface, in: RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(.separator.opacity(0.22)))
    }
}

/// One shared layout for resumed drafts, saved calculations and project history.
private struct CalculationSummaryLabel: View {
    let profile: ProfileKind
    let title: String
    let subtitle: String
    var isFavorite = false
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        HStack(spacing: 12) {
            ProfileMaterialIcon(profile: profile, width: 48, height: 48)
            VStack(alignment: .leading, spacing: 5) {
                HStack(spacing: 6) {
                    Text(title)
                        .font(.subheadline.weight(.semibold))
                        .lineLimit(dynamicTypeSize.isAccessibilitySize ? nil : 1)
                    if isFavorite {
                        PolishedSymbol(systemName: "star.fill")
                            .font(.caption)
                            .foregroundStyle(.orange)
                            .accessibilityLabel("workflow.favorites")
                    }
                }
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(dynamicTypeSize.isAccessibilitySize ? nil : 1)
                    .truncationMode(.middle)
            }
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .foregroundStyle(.primary)
        .multilineTextAlignment(.leading)
        .accessibilityElement(children: .combine)
    }
}

private struct RecentCalculationRow: View {
    let item: CalculationItemEntity
    @Environment(\.locale) private var locale

    private var subtitle: String {
        let dimensions = item.profile.dimensionFields.compactMap { field in
            item.geometry.values[field].map { AppFormatters.number($0, maximumFractionDigits: 12, locale: locale) }
        }.joined(separator: " × ")
        let unit = item.profile == .customArea ? item.geometry.areaUnit.rawValue : item.geometry.lengthUnit.rawValue
        let material = MaterialCatalog.localizedName(materialID: item.materialID, fallback: item.materialName, locale: locale)
        return dimensions + " " + unit + " · " + AppFormatters.number(item.lengthValue, locale: locale) + " " + item.lengthUnit.rawValue + " · " + material
    }

    var body: some View {
        CalculationSummaryLabel(
            profile: item.profile,
            title: item.descriptionText.isEmpty ? AppLocalization.text("profile." + item.profile.rawValue, locale: locale) : item.descriptionText,
            subtitle: subtitle
        )
        .padding(.vertical, 8)
        .contentShape(Rectangle())
    }
}

private struct SavedCalculationRow: View {
    let record: SavedCalculation
    var isEmbedded = false
    var showsFavorite = true
    @Environment(\.locale) private var locale
    @Query private var materials: [MaterialEntity]

    private var subtitle: String {
        let draft = record.state.makeDraft(locale: locale)
        let geometry = draft.profile.dimensionFields.compactMap { draft.dimensionTexts[$0] }.joined(separator: " × ")
        let unit = draft.profile == .customArea ? draft.areaUnit.rawValue : draft.geometryUnit.rawValue
        let name = materials.first { $0.id == record.state.materialID }?.name ?? record.state.materialID
        let material = MaterialCatalog.localizedName(materialID: record.state.materialID, fallback: name, locale: locale)
        return geometry + " " + unit + " · " + draft.lengthText + " " + draft.lengthUnit.rawValue + " · " + material
    }

    var body: some View {
        CalculationSummaryLabel(
            profile: record.state.profile,
            title: record.state.description.isEmpty ? AppLocalization.text("profile." + record.state.profile.rawValue, locale: locale) : record.state.description,
            subtitle: subtitle,
            isFavorite: showsFavorite && record.isFavorite
        )
        .padding(isEmbedded ? 0 : 12)
        .background(isEmbedded ? Color.clear : SteelFlowTheme.surface, in: RoundedRectangle(cornerRadius: 14))
    }
}

private struct CalculationLibraryList: View {
    let favorites: Bool
    @State private var library = CalculationLibrary.shared
    @State private var search = ""
    @State private var openedDraft: DraftState?
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
                HStack(spacing: 8) {
                    Button {
                        openedDraft = record.state
                    } label: {
                        HStack(spacing: 10) {
                            ProfileMaterialIcon(profile: record.state.profile, width: 32, height: 32)
                            Text(record.state.description.isEmpty ? AppLocalization.text("profile." + record.state.profile.rawValue, locale: locale) : record.state.description)
                                .font(.body)
                                .lineLimit(1)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .frame(minHeight: 44)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    Button {
                        library.toggleFavorite(record.id)
                    } label: {
                        PolishedSymbol(systemName: record.isFavorite ? "star.fill" : "star")
                            .font(.body.weight(.medium))
                            .foregroundStyle(record.isFavorite ? Color.orange : Color.secondary)
                            .frame(width: 44, height: 44)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.borderless)
                    .accessibilityLabel(record.isFavorite ? "ui.unfavorite" : "workflow.favorite")
                    .accessibilityIdentifier("library.favorite.\(record.id)")
                    Button {
                        openedDraft = record.state
                    } label: {
                        PolishedSymbol(systemName: "chevron.right")
                            .font(.footnote.weight(.semibold))
                            .foregroundStyle(Color(uiColor: .tertiaryLabel))
                            .frame(width: 20, height: 44)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.borderless)
                    .accessibilityHidden(true)
                }
                .swipeActions { Button("common.delete", role: .destructive) { library.remove(record.id) } }
            }
        }
        .searchable(text: $search)
        .navigationTitle(favorites ? "workflow.favorites" : "calculator.recent")
        .navigationDestination(item: $openedDraft) { state in
            CalculatorEditorView(profile: state.profile, restoredState: state)
        }
    }
}
