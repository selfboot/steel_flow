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

struct ProPaywallView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.locale) private var locale
    let reason: ProPaywallReason
    @State private var purchaseManager = PurchaseManager.shared

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    VStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(SteelFlowTheme.steelBlue.opacity(0.12))
                                .frame(width: 84, height: 84)
                            Image(systemName: purchaseManager.isPro ? "checkmark.seal.fill" : "crown.fill")
                                .font(.system(size: 38, weight: .semibold))
                                .foregroundStyle(SteelFlowTheme.steelBlue)
                        }
                            .accessibilityHidden(true)
                        Text(purchaseManager.isPro ? "purchase.pro_active" : "purchase.paywall.title")
                            .font(.largeTitle.bold())
                            .multilineTextAlignment(.center)
                        Text(purchaseManager.isPro ? "purchase.paywall.active_subtitle" : "purchase.paywall.subtitle")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }

                    if !purchaseManager.isPro, reason != .general {
                        Label {
                            Text(LocalizedStringKey(reason.rawValue))
                        } icon: {
                            Image(systemName: "lock.fill")
                        }
                        .font(.subheadline)
                        .foregroundStyle(SteelFlowTheme.steelBlue)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                        .background(SteelFlowTheme.steelBlue.opacity(0.1), in: RoundedRectangle(cornerRadius: 14))
                    }

                    VStack(alignment: .leading, spacing: 16) {
                        benefit("purchase.paywall.benefit.projects", icon: "folder.badge.plus")
                        benefit("purchase.paywall.benefit.materials", icon: "shippingbox.fill")
                        benefit("purchase.paywall.benefit.quotes", icon: "doc.richtext.fill")
                        benefit("purchase.paywall.benefit.backups", icon: "externaldrive.fill")
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                    VStack(spacing: 14) {
                        HStack(alignment: .firstTextBaseline) {
                            VStack(alignment: .leading, spacing: 3) {
                                Text("purchase.paywall.lifetime")
                                    .font(.headline)
                                Text("purchase.paywall.one_time")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            Text(purchaseManager.localizedPrice ?? "—")
                                .font(.title3.bold().monospacedDigit())
                        }

                        if purchaseManager.isPro {
                            Button("common.done") { dismiss() }
                                .buttonStyle(.borderedProminent)
                                .controlSize(.large)
                                .frame(maxWidth: .infinity)
                        } else {
                            Button {
                                Task {
                                    await purchaseManager.purchase()
                                    if purchaseManager.isPro { dismiss() }
                                }
                            } label: {
                                Group {
                                    if purchaseManager.isLoading {
                                        ProgressView()
                                    } else if let price = purchaseManager.localizedPrice {
                                        Text(AppLocalization.format("purchase.paywall.buy_format", locale: locale, price))
                                    } else {
                                        Text("purchase.buy")
                                    }
                                }
                                .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.borderedProminent)
                            .controlSize(.large)
                            .disabled(!purchaseManager.isPurchaseAvailable || purchaseManager.isLoading)

                            Button("purchase.restore") {
                                Task { await purchaseManager.restore() }
                            }
                            .disabled(purchaseManager.isLoading)
                        }

                        if let message = purchaseManager.availabilityMessage, !purchaseManager.isPro {
                            Label(message, systemImage: "exclamationmark.triangle")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }

                        Text("purchase.paywall.footer")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding()
                    .background(Color(uiColor: .secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 18))
                }
                .padding()
                .frame(maxWidth: 620)
                .frame(maxWidth: .infinity)
            }
            .background(Color(uiColor: .systemGroupedBackground))
            .navigationTitle("purchase.paywall.navigation_title")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("common.close") { dismiss() }
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
        .presentationDetents([.large])
    }

    private func benefit(_ title: LocalizedStringKey, icon: String) -> some View {
        Label {
            Text(title)
        } icon: {
            Image(systemName: icon)
                .foregroundStyle(SteelFlowTheme.steelBlue)
                .frame(width: 24)
        }
    }
}

extension View {
    func proPaywall(reason: Binding<ProPaywallReason?>) -> some View {
        sheet(item: reason) { ProPaywallView(reason: $0) }
    }
}
