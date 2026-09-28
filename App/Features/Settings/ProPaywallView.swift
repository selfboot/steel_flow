import SwiftUI

enum ProPaywallReason: String, Identifiable {
    case general = "purchase.help"
    case projects = "purchase.limit.projects"
    case duplicate = "purchase.limit.duplicate"
    case bulkPricing = "purchase.limit.bulk_pricing"
    case items = "purchase.limit.items"
    case materials = "purchase.limit.materials"
    case csv = "purchase.limit.csv"
    case terms = "purchase.limit.terms"
    case companyProfile = "purchase.limit.company_profile"
    case backups = "purchase.limit.backups"

    var id: String { rawValue }
}

/// Shared visual identity for the settings entry and purchase page.
struct ProEmblem: View {
    var isActive = false
    var size: CGFloat = 44

    var body: some View {
        SteelIconTile(
            systemName: isActive ? "checkmark.seal.fill" : "crown.fill",
            size: size,
            base: Color(red: 0.22, green: 0.35, blue: 0.44),
            foreground: SteelFlowTheme.proHighlight
        )
    }
}

struct ProPaywallView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.locale) private var locale
    @Environment(\.dynamicTypeSize) private var typeSize
    let reason: ProPaywallReason
    @State private var purchaseManager = PurchaseManager.shared

    var body: some View {
        NavigationStack {
            GeometryReader { geometry in
                // Keep checkout reachable, while allowing the entire page to scroll at large text sizes.
                let inlineCheckout = typeSize.isAccessibilitySize || geometry.size.height < 540
                ScrollView {
                    VStack(spacing: 20) {
                        hero
                        if !purchaseManager.isPro, reason != .general {
                            Label(LocalizedStringKey(reason.rawValue), systemImage: "lock.open.fill")
                                .font(.subheadline)
                                .foregroundStyle(SteelFlowTheme.steelBlue)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(14)
                                .background(SteelFlowTheme.steelBlue.opacity(0.08), in: RoundedRectangle(cornerRadius: 16))
                        }
                        benefits
                        if inlineCheckout { checkout }
                    }
                    .padding(20)
                    .frame(maxWidth: 620)
                    .frame(maxWidth: .infinity)
                }
                .safeAreaInset(edge: .bottom, spacing: 0) {
                    if !inlineCheckout {
                        checkout
                            .padding(.horizontal, 20)
                            .padding(.top, 16)
                            .padding(.bottom, 8)
                            .frame(maxWidth: 620)
                            .frame(maxWidth: .infinity)
                            .background(SteelFlowTheme.surface)
                            .overlay(alignment: .top) { Divider() }
                    }
                }
            }
            .background(Color(uiColor: .systemGroupedBackground))
            .localizedNavigationTitle("purchase.paywall.navigation_title")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button { dismiss() } label: {
                        PolishedSymbol(systemName: "xmark")
                            .font(.body.weight(.semibold))
                    }
                    .accessibilityLabel(Text("common.close"))
                }
            }
            .task { await purchaseManager.load() }
            .alert(
                purchaseManager.alertTitle,
                isPresented: Binding(
                    get: { purchaseManager.alertMessage != nil },
                    set: { if !$0 { purchaseManager.alertMessage = nil } }
                )
            ) {
                Button("common.ok", role: .cancel) {}
            } message: {
                Text(purchaseManager.alertMessage ?? "")
            }
        }
        .tint(SteelFlowTheme.steelBlue)
        .presentationDetents([.large])
    }

    private var hero: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                ProEmblem(isActive: purchaseManager.isPro)
                Spacer()
                Text("purchase.paywall.lifetime")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(SteelFlowTheme.proHighlight)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 7)
                    .background(Color.white.opacity(0.08), in: Capsule())
            }
            VStack(alignment: .leading, spacing: 8) {
                Text(purchaseManager.isPro ? "purchase.pro_active" : "purchase.paywall.title")
                    .font(.title2.bold())
                    .foregroundStyle(.white)
                Text(purchaseManager.isPro ? "purchase.paywall.active_subtitle" : "purchase.paywall.subtitle")
                    .font(.subheadline)
                    .foregroundStyle(Color.white.opacity(0.8))
            }
            .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(22)
        .background(SteelFlowTheme.proGradient, in: RoundedRectangle(cornerRadius: 24))
        .overlay {
            RoundedRectangle(cornerRadius: 24).strokeBorder(Color.white.opacity(0.12))
        }
    }

    private var benefits: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("purchase.paywall.included")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)
            VStack(spacing: 0) {
                benefit("projects", icon: "square.stack.3d.up.fill")
                benefitDivider
                benefit("materials", icon: "slider.horizontal.3")
                benefitDivider
                benefit("quotes", icon: "doc.richtext.fill")
                benefitDivider
                benefit("backups", icon: "externaldrive.fill")
            }
            .padding(.horizontal, 16)
            .background(SteelFlowTheme.surface, in: RoundedRectangle(cornerRadius: 20))
        }
    }

    private var benefitDivider: some View {
        Divider().padding(.leading, 46)
    }

    private func benefit(_ key: String, icon: String) -> some View {
        let titleKey = "purchase.paywall.feature.\(key).title"
        let detailKey = "purchase.paywall.feature.\(key).detail"
        return HStack(alignment: .top, spacing: 12) {
            SteelIconTile(systemName: icon, size: 34)
            VStack(alignment: .leading, spacing: 4) {
                Text(LocalizedStringKey(titleKey))
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)
                Text(LocalizedStringKey(detailKey))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
        }
        .padding(.vertical, 13)
        .accessibilityElement(children: .combine)
    }

    private var checkout: some View {
        VStack(spacing: 10) {
            if purchaseManager.isPro {
                Button("common.done") { dismiss() }
                    .buttonStyle(ProPurchaseButtonStyle())
            } else {
                ViewThatFits(in: .horizontal) {
                    HStack(alignment: .center, spacing: 16) {
                        purchaseTerms
                        Spacer(minLength: 0)
                        price
                    }
                    VStack(alignment: .leading, spacing: 8) {
                        purchaseTerms
                        price
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                Button {
                    Task {
                        await purchaseManager.purchase()
                        if purchaseManager.isPro { dismiss() }
                    }
                } label: {
                    HStack(spacing: 8) {
                        if purchaseManager.isLoading { ProgressView() }
                        if let price = purchaseManager.localizedPrice {
                            Text(AppLocalization.format("purchase.paywall.buy_format", locale: locale, price))
                        } else {
                            Text(purchaseManager.isLoading ? "purchase.paywall.loading" : "purchase.buy")
                        }
                    }
                    .multilineTextAlignment(.center)
                }
                .buttonStyle(ProPurchaseButtonStyle())
                .disabled(!purchaseManager.isPurchaseAvailable || purchaseManager.isLoading)
                .accessibilityIdentifier("paywall.purchase")

                if purchaseManager.availabilityMessage != nil {
                    VStack(spacing: 4) {
                        Text("purchase.paywall.unavailable")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Button("common.retry") { Task { await purchaseManager.load() } }
                            .font(.subheadline.weight(.semibold))
                            .disabled(purchaseManager.isLoading)
                    }
                    .multilineTextAlignment(.center)
                }
                Button("purchase.restore") { Task { await purchaseManager.restore() } }
                    .font(.subheadline.weight(.medium))
                    .frame(minHeight: 36)
                    .disabled(purchaseManager.isLoading)
            }
            Text("purchase.paywall.footer")
                .font(.caption2)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var purchaseTerms: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text("purchase.paywall.lifetime").font(.headline)
            Text("purchase.paywall.one_time")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .fixedSize(horizontal: false, vertical: true)
    }

    private var price: some View {
        Group {
            if let price = purchaseManager.localizedPrice {
                Text(price).font(.title2.bold()).monospacedDigit()
            } else {
                Text(purchaseManager.isLoading ? "purchase.paywall.loading" : "purchase.paywall.price_unavailable")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .fixedSize(horizontal: true, vertical: false)
    }
}

private struct ProPurchaseButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundStyle(isEnabled ? Color.white : Color(uiColor: .secondaryLabel))
            .tint(isEnabled ? Color.white : Color(uiColor: .secondaryLabel))
            .padding(.horizontal, 16)
            .padding(.vertical, 15)
            .frame(maxWidth: .infinity, minHeight: 52)
            .background(isEnabled ? SteelFlowTheme.actionFill : Color(uiColor: .tertiarySystemFill), in: RoundedRectangle(cornerRadius: 16))
            .opacity(configuration.isPressed && isEnabled ? 0.82 : 1)
    }
}

extension View {
    func proPaywall(reason: Binding<ProPaywallReason?>, onUnlocked: (() -> Void)? = nil) -> some View {
        sheet(item: reason, onDismiss: { if PurchaseManager.shared.isPro { onUnlocked?() } }) { ProPaywallView(reason: $0) }
    }
}
