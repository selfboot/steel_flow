import SwiftUI
import SwiftData

@MainActor enum ProjectCloner {
    static func copy(_ source: ProjectEntity, name: String, clearPrices: Bool = false) -> ProjectEntity {
        let copy = ProjectEntity(name: name, customerName: source.customerName, quoteLanguage: source.quoteLanguage,
            unitSystem: source.unitSystem, currencyCode: source.currencyCode, paperSize: source.paperSize)
        copy.taxPercentText = source.taxPercentText; copy.markupPercentText = source.markupPercentText
        copy.profitMode = source.profitMode; copy.validDays = source.validDays; copy.terms = source.terms; copy.notes = source.notes
        copy.customerContact = source.customerContact; copy.showQuoteMass = source.showQuoteMass; copy.showQuoteUnitPrice = source.showQuoteUnitPrice
        copy.items = source.items.sorted { $0.sortIndex < $1.sortIndex }.map {
            let item = $0.copyItem()
            if clearPrices { _ = PriceBasisConversion.migrate(item, from: source.currencyCode, to: source.currencyCode, mode: .clearAmounts, rate: nil) }
            return item
        }
        return copy
    }
}

struct TemplatePickerView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query private var projects: [ProjectEntity]
    @State private var name = ""
    @State private var clearPrices = true
    @State private var paywallReason: ProPaywallReason?
    @State private var pendingTemplate: ProjectEntity?
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("project.name", text: $name)
                    Toggle("workflow.template_clear_prices", isOn: $clearPrices)
                    Text("workflow.template_help").font(.caption).foregroundStyle(.secondary)
                }
                Section("workflow.templates") {
                    if !projects.contains(where: \.isTemplate) { Text("workflow.templates_empty") }
                    ForEach(projects.filter { $0.isTemplate && !$0.isArchived }) { template in
                        Button(template.name) { create(template) }
                    }
                }
            }
            .navigationTitle("workflow.from_template")
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("common.cancel") { dismiss() } } }
            .proPaywall(reason: $paywallReason) { if let template = pendingTemplate { pendingTemplate = nil; create(template) } }
        }
    }
    private func create(_ template: ProjectEntity) {
        let isPro = PurchaseManager.shared.isPro
        guard isPro else { pendingTemplate = template; paywallReason = .duplicate; return }
        guard ProPolicy.canActivateProject(activeProjectCount: projects.filter { !$0.isArchived && !$0.isTemplate }.count, isPro: isPro), isPro || template.items.count <= ProPolicy.freeItemsPerProjectLimit else { paywallReason = .projects; return }
        let copy = ProjectCloner.copy(template, name: name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? template.name : name, clearPrices: clearPrices)
        modelContext.insert(copy)
        if PersistenceErrorCenter.shared.save(modelContext) { dismiss() }
    }
}

struct CustomerPickerView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \CustomerEntity.name) private var customers: [CustomerEntity]
    var onSelect: ((CustomerEntity) -> Void)? = nil
    @State private var search = ""
    @State private var showNew = false
    @State private var editing: CustomerEntity?
    var body: some View {
        NavigationStack {
            List {
                ForEach(customers.filter { search.isEmpty || [$0.name, $0.phone, $0.email].contains { $0.localizedStandardContains(search) } }) { customer in
                    Button {
                        if let onSelect { onSelect(customer); dismiss() } else { editing = customer }
                    } label: {
                        VStack(alignment: .leading) { Text(customer.name).foregroundStyle(.primary); Text(customer.phone + " " + customer.email).font(.caption).foregroundStyle(.secondary) }
                    }
                    .contextMenu { Button("common.edit") { editing = customer } }
                }
                Button("workflow.customer_new", systemImage: "person.badge.plus") { showNew = true }
            }
            .searchable(text: $search)
            .navigationTitle("workflow.customers")
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("common.done") { dismiss() } } }
            .sheet(isPresented: $showNew) { CustomerEditorView() }
            .sheet(item: $editing) { CustomerEditorView(customer: $0) }
        }
    }
}

private struct CustomerEditorView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    var customer: CustomerEntity?
    @State private var name = ""
    @State private var email = ""
    @State private var phone = ""
    @State private var address = ""
    var body: some View {
        NavigationStack {
            Form {
                TextField("project.customer", text: $name)
                TextField("company.email", text: $email).keyboardType(.emailAddress).textInputAutocapitalization(.never)
                TextField("company.phone", text: $phone).keyboardType(.phonePad)
                TextField("company.address", text: $address, axis: .vertical)
            }
            .keyboardDismissSupport()
            .navigationTitle("workflow.customers")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("common.cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) { Button("common.save") {
                    let value = customer ?? CustomerEntity(name: name)
                    value.name = name.trimmingCharacters(in: .whitespacesAndNewlines); value.email = email; value.phone = phone; value.address = address
                    if customer == nil { modelContext.insert(value) }
                    if PersistenceErrorCenter.shared.save(modelContext) { dismiss() }
                }.disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty) }
            }
            .onAppear { if let customer { name = customer.name; email = customer.email; phone = customer.phone; address = customer.address } }
        }
    }
}
