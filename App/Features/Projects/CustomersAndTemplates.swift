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
    var onCreated: ((ProjectEntity) -> Void)? = nil
    var onNewProject: (() -> Void)? = nil
    private var templates: [ProjectEntity] { projects.filter { $0.isTemplate && !$0.isArchived } }
    private var sourceProjects: [ProjectEntity] { projects.filter { !$0.isTemplate && !$0.isArchived } }
    @Environment(\.locale) private var locale
    @State private var selectedTemplate: ProjectEntity?
    @State private var name = ""
    @State private var clearPrices = true
    @State private var paywallReason: ProPaywallReason?
    @State private var pendingTemplate: ProjectEntity?
    var body: some View {
        NavigationStack {
            ScrollViewReader { scroll in
            Form {
                if templates.isEmpty {
                    Section {
                        Label("ui.templates_none", systemImage: "doc.on.doc").font(.headline)
                        Text("ui.template_first_help").foregroundStyle(.secondary)
                        if sourceProjects.isEmpty {
                            Button("project.create") { onNewProject?(); dismiss() }.buttonStyle(PrimaryActionStyle())
                        }
                    }
                    if !sourceProjects.isEmpty {
                        Section("ui.template_choose_source") {
                            ForEach(sourceProjects) { project in
                                Button { saveFirstTemplate(project) } label: {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(project.name).foregroundStyle(.primary)
                                        Text("workflow.save_template").font(.caption)
                                    }.frame(minHeight: 44)
                                }.accessibilityIdentifier("template.source." + project.name)
                            }
                        }
                    }
                } else {
                Section {
                    LabeledEntry("project.name", text: $name)
                    Toggle("workflow.template_clear_prices", isOn: $clearPrices)
                    Text("workflow.template_help").font(.caption).foregroundStyle(.secondary)
                }
                if let template = selectedTemplate {
                    Section("ui.template_preview") {
                        LabeledContent("project.items", value: String(template.items.count))
                        Text(Array(Set(template.items.map { MaterialCatalog.localizedName(materialID: $0.materialID, fallback: $0.materialName, locale: locale) })).sorted().joined(separator: " · "))
                        LabeledContent("project.tax", value: template.taxPercentText + "%")
                        LabeledContent(template.profitMode == .markup ? "project.markup" : "project.margin", value: template.markupPercentText + "%")
                        Text(clearPrices ? "ui.prices_will_clear" : "ui.prices_will_keep").accessibilityIdentifier("template.preview.prices")
                    }.id("template.preview")
                }
                Section("workflow.templates") {
                    ForEach(templates) { template in
                        Button { selectedTemplate = template } label: {
                            HStack { Text(template.name).foregroundStyle(.primary); Spacer(); Image(systemName: selectedTemplate?.id == template.id ? "checkmark.circle.fill" : "circle") }.frame(minHeight: 44)
                        }.accessibilityIdentifier("template." + template.name)
                        .accessibilityValue(selectedTemplate?.id == template.id ? Text("ui.selected") : Text("ui.not_selected"))
                    }
                }
            }
            }
            .onChange(of: selectedTemplate?.id) { _, id in if id != nil { withAnimation { scroll.scrollTo("template.preview", anchor: .top) } } }
            .keyboardDismissSupport()
            }
            .safeAreaInset(edge: .bottom) {
                if !templates.isEmpty {
                    VStack(spacing: 8) {
                        if selectedTemplate == nil { Text("ui.template_select_first").font(.caption).foregroundStyle(.secondary) }
                        Button { if let selectedTemplate { create(selectedTemplate) } } label: { Text("ui.create_template").frame(maxWidth: .infinity) }
                            .buttonStyle(PrimaryActionStyle()).disabled(selectedTemplate == nil).accessibilityIdentifier("template.create")
                    }.padding().background(.bar)
                }
            }
            .navigationTitle("workflow.from_template")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("common.cancel") { dismiss() } } }
            .proPaywall(reason: $paywallReason) { if let template = pendingTemplate { pendingTemplate = nil; create(template) } }
        }
    }
    private func saveFirstTemplate(_ project: ProjectEntity) {
        let template = ProjectCloner.copy(project, name: project.name, clearPrices: true)
        template.isTemplate = true; template.customerName = ""; template.customerContact = ""
        modelContext.insert(template)
        if PersistenceErrorCenter.shared.save(modelContext) { selectedTemplate = template }
    }
    private func create(_ template: ProjectEntity) {
        let isPro = PurchaseManager.shared.isPro
        guard isPro else { pendingTemplate = template; paywallReason = .duplicate; return }
        guard ProPolicy.canActivateProject(activeProjectCount: projects.filter { !$0.isArchived && !$0.isTemplate }.count, isPro: isPro), isPro || template.items.count <= ProPolicy.freeItemsPerProjectLimit else { paywallReason = .projects; return }
        let copy = ProjectCloner.copy(template, name: name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? template.name : name, clearPrices: clearPrices)
        modelContext.insert(copy)
        if PersistenceErrorCenter.shared.save(modelContext) { onCreated?(copy); dismiss() }
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
    private var filtered: [CustomerEntity] { customers.filter { search.isEmpty || [$0.name, $0.phone, $0.email].contains { $0.localizedStandardContains(search) } } }
    var body: some View {
        NavigationStack {
            List {
                if !search.isEmpty && filtered.isEmpty { ContentUnavailableView.search(text: search); Button("ui.clear_search") { search = "" } }
                ForEach(filtered) { customer in
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
                LabeledEntry("project.customer", text: $name)
                LabeledEntry("company.email", text: $email, keyboard: .emailAddress)
                LabeledEntry("company.phone", text: $phone, keyboard: .phonePad)
                LabeledEntry("company.address", text: $address, multiline: true)
            }
            .keyboardDismissSupport()
            .navigationTitle(customer == nil ? "ui.new_customer" : "ui.edit_customer")
            .navigationBarTitleDisplayMode(.inline)
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
