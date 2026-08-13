import AppKit
import SwiftUI

/// Native text field that becomes first responder as soon as the menu bar window is key,
/// so clicking 待办 is immediately “type a todo”.
struct CaptureTextField: NSViewRepresentable {
    @Binding var text: String
    var placeholder: String
    var onSubmit: () -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeNSView(context: Context) -> NSTextField {
        let field = FocusingTextField()
        field.placeholderString = placeholder
        field.delegate = context.coordinator
        field.isBordered = true
        field.isBezeled = true
        field.bezelStyle = .roundedBezel
        field.isEditable = true
        field.isSelectable = true
        field.font = .systemFont(ofSize: 14)
        field.focusRingType = .default
        field.maximumNumberOfLines = 1
        field.cell?.wraps = false
        field.cell?.isScrollable = true
        field.setContentHuggingPriority(.defaultLow, for: .horizontal)
        field.setContentHuggingPriority(.defaultHigh, for: .vertical)
        field.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        field.stringValue = text
        return field
    }

    func updateNSView(_ nsView: NSTextField, context: Context) {
        context.coordinator.parent = self
        if nsView.placeholderString != placeholder {
            nsView.placeholderString = placeholder
        }
        guard nsView.stringValue != text else { return }
        nsView.stringValue = text
        if let editor = nsView.currentEditor() {
            let end = (text as NSString).length
            editor.selectedRange = NSRange(location: end, length: 0)
        }
    }

    final class Coordinator: NSObject, NSTextFieldDelegate {
        var parent: CaptureTextField

        init(_ parent: CaptureTextField) {
            self.parent = parent
        }

        func controlTextDidChange(_ obj: Notification) {
            guard let field = obj.object as? NSTextField else { return }
            parent.text = field.stringValue
        }

        func control(_ control: NSControl, textView: NSTextView, doCommandBy commandSelector: Selector) -> Bool {
            if commandSelector == #selector(NSResponder.insertNewline(_:)) {
                parent.onSubmit()
                return true
            }
            return false
        }
    }
}

final class FocusingTextField: NSTextField {
    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        NotificationCenter.default.removeObserver(self, name: NSWindow.didBecomeKeyNotification, object: nil)
        guard let window else { return }
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(windowDidBecomeKey),
            name: NSWindow.didBecomeKeyNotification,
            object: window
        )
        requestFocus()
    }

    @objc private func windowDidBecomeKey() {
        requestFocus()
    }

    private func requestFocus() {
        DispatchQueue.main.async { [weak self] in
            self?.becomeKeyFirstResponder()
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.06) { [weak self] in
            self?.becomeKeyFirstResponder()
        }
    }

    private func becomeKeyFirstResponder() {
        guard let window, window.isKeyWindow else { return }
        window.makeFirstResponder(self)
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}
