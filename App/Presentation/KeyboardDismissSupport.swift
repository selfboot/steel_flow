import SwiftUI
import UIKit

@MainActor
private enum KeyboardDismissAction {
    static func perform() {
        UIApplication.shared.sendAction(
            #selector(UIResponder.resignFirstResponder),
            to: nil,
            from: nil,
            for: nil
        )
    }
}

private struct KeyboardDismissSupport: ViewModifier {
    func body(content: Content) -> some View {
        content
            .scrollDismissesKeyboard(.immediately)
            .onSubmit { KeyboardDismissAction.perform() }
            .toolbar {
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("common.done") { KeyboardDismissAction.perform() }
                }
            }
    }
}

private struct KeyboardOutsideTapSupport: ViewModifier {
    func body(content: Content) -> some View {
        content.background(KeyboardOutsideTapObserver().frame(width: 0, height: 0))
    }
}

private struct KeyboardOutsideTapObserver: UIViewRepresentable {
    func makeCoordinator() -> Coordinator { Coordinator() }

    func makeUIView(context: Context) -> WindowObservationView {
        let view = WindowObservationView()
        view.windowDidChange = { window in context.coordinator.install(in: window) }
        return view
    }

    func updateUIView(_ uiView: WindowObservationView, context: Context) {
        context.coordinator.install(in: uiView.window)
    }

    static func dismantleUIView(_ uiView: WindowObservationView, coordinator: Coordinator) {
        uiView.windowDidChange = nil
        coordinator.uninstall()
    }

    @MainActor
    final class Coordinator: NSObject, UIGestureRecognizerDelegate {
        private weak var installedWindow: UIWindow?
        private lazy var tapRecognizer: UITapGestureRecognizer = {
            let recognizer = UITapGestureRecognizer(target: self, action: #selector(outsideTap))
            recognizer.cancelsTouchesInView = false
            recognizer.delegate = self
            return recognizer
        }()

        func install(in window: UIWindow?) {
            guard installedWindow !== window else { return }
            uninstall()
            installedWindow = window
            window?.addGestureRecognizer(tapRecognizer)
        }

        func uninstall() {
            installedWindow?.removeGestureRecognizer(tapRecognizer)
            installedWindow = nil
        }

        func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
            var touchedView = touch.view
            while let view = touchedView {
                if view is UITextField || view is UITextView { return false }
                touchedView = view.superview
            }
            return true
        }

        @objc private func outsideTap() {
            KeyboardDismissAction.perform()
        }
    }
}

@MainActor
private final class WindowObservationView: UIView {
    var windowDidChange: ((UIWindow?) -> Void)?

    override func didMoveToWindow() {
        super.didMoveToWindow()
        windowDidChange?(window)
    }
}

extension View {
    func keyboardDismissSupport() -> some View {
        modifier(KeyboardDismissSupport())
    }

    func keyboardOutsideTapSupport() -> some View {
        modifier(KeyboardOutsideTapSupport())
    }
}
