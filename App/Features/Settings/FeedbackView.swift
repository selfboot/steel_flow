import MessageUI
import SwiftUI
import UIKit

enum FeedbackCategory: String, CaseIterable, Identifiable {
    case problem
    case feature
    case general

    var id: String { rawValue }

    var titleKey: LocalizedStringKey {
        switch self {
        case .problem: "feedback.type.problem"
        case .feature: "feedback.type.feature"
        case .general: "feedback.type.general"
        }
    }

    var subjectPrefix: String {
        switch self {
        case .problem: "[Problem]"
        case .feature: "[Feature]"
        case .general: "[Feedback]"
        }
    }
}

struct FeedbackDiagnostics: Equatable {
    let appVersion: String
    let device: String
    let systemVersion: String
    let locale: String

    @MainActor
    static var current: FeedbackDiagnostics {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "Unknown"
        return FeedbackDiagnostics(
            appVersion: "\(version) (\(build))",
            device: "\(UIDevice.current.model) (\(machineIdentifier))",
            systemVersion: "\(UIDevice.current.systemName) \(UIDevice.current.systemVersion)",
            locale: Locale.current.identifier
        )
    }

    private static var machineIdentifier: String {
        var info = utsname()
        uname(&info)
        return withUnsafePointer(to: &info.machine) { pointer in
            pointer.withMemoryRebound(to: CChar.self, capacity: 1) { String(cString: $0) }
        }
    }
}

struct FeedbackMailPayload: Equatable, Identifiable {
    static let recipient = "xuezaigds@gmail.com"

    let subject: String
    let body: String

    var id: String { subject }

    static func make(
        category: FeedbackCategory,
        summary: String,
        details: String,
        diagnostics: FeedbackDiagnostics
    ) -> FeedbackMailPayload {
        let cleanedSummary = summary.trimmingCharacters(in: .whitespacesAndNewlines)
        let cleanedDetails = details.trimmingCharacters(in: .whitespacesAndNewlines)
        let body = """
        \(cleanedDetails)

        ---
        App: SteelFlow
        App version: \(diagnostics.appVersion)
        Device: \(diagnostics.device)
        System: \(diagnostics.systemVersion)
        Locale: \(diagnostics.locale)
        ---
        """
        return FeedbackMailPayload(
            subject: "\(category.subjectPrefix) \(cleanedSummary)",
            body: body
        )
    }

    var mailtoURL: URL? {
        var components = URLComponents()
        components.scheme = "mailto"
        components.path = Self.recipient
        components.queryItems = [
            URLQueryItem(name: "subject", value: subject),
            URLQueryItem(name: "body", value: body)
        ]
        return components.url
    }

    var clipboardText: String {
        "To: \(Self.recipient)\nSubject: \(subject)\n\n\(body)"
    }
}

struct FeedbackView: View {
    private enum FocusedField: Hashable {
        case summary
        case details
    }

    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL
    @State private var category: FeedbackCategory = .problem
    @State private var summary = ""
    @State private var details = ""
    @State private var mailPayload: FeedbackMailPayload?
    @State private var showFallback = false
    @State private var showSent = false
    @State private var showCopied = false
    @State private var showMailFailure = false
    @FocusState private var focusedField: FocusedField?

    private var payload: FeedbackMailPayload {
        FeedbackMailPayload.make(
            category: category,
            summary: summary,
            details: details,
            diagnostics: .current
        )
    }

    private var canSend: Bool {
        !summary.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        Form {
            Section("feedback.type.section") {
                Picker("feedback.type.picker", selection: $category) {
                    ForEach(FeedbackCategory.allCases) { category in
                        Text(category.titleKey).tag(category)
                    }
                }
            }

            Section {
                TextField("feedback.summary.placeholder", text: $summary)
                    .textInputAutocapitalization(.sentences)
                    .submitLabel(.next)
                    .focused($focusedField, equals: .summary)
                    .onSubmit { focusedField = .details }
                TextField("feedback.details.placeholder", text: $details, axis: .vertical)
                    .textInputAutocapitalization(.sentences)
                    .lineLimit(5...10)
                    .focused($focusedField, equals: .details)
            } header: {
                Text("feedback.details.section")
            } footer: {
                Text("feedback.details.footer")
            }

            Section {
                let diagnostics = FeedbackDiagnostics.current
                LabeledContent("feedback.system.app_version", value: diagnostics.appVersion)
                LabeledContent("feedback.system.device", value: diagnostics.device)
                LabeledContent("feedback.system.ios", value: diagnostics.systemVersion)
                LabeledContent("feedback.system.locale", value: diagnostics.locale)
            } header: {
                Text("feedback.system.section")
            } footer: {
                Text("feedback.system.footer")
            }

        }
        .navigationTitle("feedback.title")
        .navigationBarTitleDisplayMode(.inline)
        .keyboardDismissSupport()
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("feedback.send") { sendFeedback() }
                    .fontWeight(.semibold)
                    .disabled(!canSend)
            }
        }
        .sheet(item: $mailPayload) { payload in
            FeedbackMailComposer(payload: payload) { result in
                if result == .sent { showSent = true }
                if result == .failed { showMailFailure = true }
            }
        }
        .confirmationDialog(
            "feedback.fallback.title",
            isPresented: $showFallback,
            titleVisibility: .visible
        ) {
            Button("feedback.fallback.open") {
                guard let url = payload.mailtoURL else {
                    showMailFailure = true
                    return
                }
                openURL(url) { accepted in
                    if !accepted { showMailFailure = true }
                }
            }
            Button("feedback.fallback.copy") {
                UIPasteboard.general.string = payload.clipboardText
                showCopied = true
            }
            Button("common.cancel", role: .cancel) {}
        } message: {
            Text("feedback.fallback.message")
        }
        .alert("feedback.sent.title", isPresented: $showSent) {
            Button("common.ok") { dismiss() }
        } message: {
            Text("feedback.sent.message")
        }
        .alert("feedback.copied.title", isPresented: $showCopied) {
            Button("common.ok", role: .cancel) {}
        } message: {
            Text("feedback.copied.message")
        }
        .alert("feedback.failure.title", isPresented: $showMailFailure) {
            Button("feedback.fallback.copy") {
                UIPasteboard.general.string = payload.clipboardText
                showCopied = true
            }
            Button("common.cancel", role: .cancel) {}
        } message: {
            Text("feedback.failure.message")
        }
    }

    private func sendFeedback() {
        let preparedPayload = payload
        let forceFallback: Bool = {
#if DEBUG
            ProcessInfo.processInfo.arguments.contains("--simulate-mail-unavailable")
#else
            false
#endif
        }()
        let canUseComposer = !forceFallback && MFMailComposeViewController.canSendMail()

        focusedField = nil
        UIApplication.shared.sendAction(
            #selector(UIResponder.resignFirstResponder),
            to: nil,
            from: nil,
            for: nil
        )

        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(250))
            if canUseComposer {
                mailPayload = preparedPayload
            } else {
                showFallback = true
            }
        }
    }
}

private struct FeedbackMailComposer: UIViewControllerRepresentable {
    let payload: FeedbackMailPayload
    let onFinish: (MFMailComposeResult) -> Void

    @Environment(\.dismiss) private var dismiss

    func makeCoordinator() -> Coordinator {
        Coordinator(dismiss: dismiss, onFinish: onFinish)
    }

    func makeUIViewController(context: Context) -> MFMailComposeViewController {
        let composer = MFMailComposeViewController()
        composer.mailComposeDelegate = context.coordinator
        composer.setToRecipients([FeedbackMailPayload.recipient])
        composer.setSubject(payload.subject)
        composer.setMessageBody(payload.body, isHTML: false)
        return composer
    }

    func updateUIViewController(_ uiViewController: MFMailComposeViewController, context: Context) {}

    @MainActor
    final class Coordinator: NSObject, @preconcurrency MFMailComposeViewControllerDelegate {
        let dismiss: DismissAction
        let onFinish: (MFMailComposeResult) -> Void

        init(dismiss: DismissAction, onFinish: @escaping (MFMailComposeResult) -> Void) {
            self.dismiss = dismiss
            self.onFinish = onFinish
        }

        func mailComposeController(
            _ controller: MFMailComposeViewController,
            didFinishWith result: MFMailComposeResult,
            error: Error?
        ) {
            onFinish(error == nil ? result : .failed)
            dismiss()
        }
    }
}
