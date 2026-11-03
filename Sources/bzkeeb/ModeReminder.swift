import AppKit

/// A single, brief visual reminder. It never takes focus or intercepts clicks.
final class ModeReminder {
    private var windows: [NSWindow] = []
    private var dismissTimer: Timer?
    private var lastShown = -Double.infinity

    func show(mode: String) {
        let now = ProcessInfo.processInfo.systemUptime
        // Avoid strobing when the user types several rejected keys quickly.
        guard now - lastShown >= 1.5 else { return }
        lastShown = now
        hide()
        for screen in NSScreen.screens {
            let window = NSWindow(contentRect: screen.frame, styleMask: .borderless,
                                  backing: .buffered, defer: false)
            window.isReleasedWhenClosed = false
            window.isOpaque = false
            window.backgroundColor = .clear
            window.hasShadow = false
            window.ignoresMouseEvents = true
            window.hidesOnDeactivate = false
            window.level = .screenSaver
            window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary]
            let view = ModeReminderView(frame: CGRect(origin: .zero, size: screen.frame.size))
            view.message = "bzkeeb · \(mode) mode — Esc or click to exit"
            window.contentView = view
            window.orderFrontRegardless()
            windows.append(window)
        }
        // Static border rather than repeated blinking, including under Reduce Motion.
        let timer = Timer(timeInterval: 0.9, repeats: false) { [weak self] _ in self?.hide() }
        dismissTimer = timer
        RunLoop.main.add(timer, forMode: .common)
    }

    func hide() {
        dismissTimer?.invalidate()
        dismissTimer = nil
        for window in windows { window.close() }
        windows.removeAll()
    }

    deinit { dismissTimer?.invalidate() }
}

private final class ModeReminderView: NSView {
    var message = ""
    override var isFlipped: Bool { true }

    override func draw(_ dirtyRect: NSRect) {
        NSColor.systemOrange.withAlphaComponent(0.9).setStroke()
        let border = NSBezierPath(roundedRect: bounds.insetBy(dx: 4, dy: 4), xRadius: 12, yRadius: 12)
        border.lineWidth = 6
        border.stroke()

        let text = NSAttributedString(string: message, attributes: [
            .font: NSFont.systemFont(ofSize: 16, weight: .semibold),
            .foregroundColor: NSColor.white,
        ])
        let size = text.size()
        let box = CGRect(x: (bounds.width - size.width) / 2 - 16, y: 60,
                         width: size.width + 32, height: size.height + 20)
        NSColor.black.withAlphaComponent(0.9).setFill()
        NSBezierPath(roundedRect: box, xRadius: 10, yRadius: 10).fill()
        text.draw(at: CGPoint(x: box.minX + 16, y: box.minY + 10))
    }
}
