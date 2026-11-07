import AppKit

/// Retriggerable visual feedback that never takes focus or intercepts clicks.
final class ModeReminder {
    private var windows: [NSWindow] = []
    private var dismissTimer: Timer?
    private var lastTriggered: TimeInterval = 0

    func show(mode: String) {
        lastTriggered = ProcessInfo.processInfo.systemUptime
        if windows.map(\.frame) != NSScreen.screens.map(\.frame) {
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
                window.contentView = view
                windows.append(window)
            }
        }
        for window in windows {
            (window.contentView as? ModeReminderView)?.message = "bzkeeb · \(mode) mode"
            window.orderFrontRegardless()
        }
        update()
        if dismissTimer == nil {
            let timer = Timer(timeInterval: 1 / 30, repeats: true) { [weak self] _ in self?.update() }
            dismissTimer = timer
            RunLoop.main.add(timer, forMode: .common)
        }
    }

    private func update() {
        let elapsed = ProcessInfo.processInfo.systemUptime - lastTriggered
        guard elapsed < 1.2 else { hide(); return }
        for window in windows {
            guard let view = window.contentView as? ModeReminderView else { continue }
            view.pulse = NSWorkspace.shared.accessibilityDisplayShouldReduceMotion ? 0 : max(0, 1 - elapsed / 0.25)
            view.needsDisplay = true
        }
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
    var pulse: CGFloat = 0
    override var isFlipped: Bool { true }

    override func draw(_ dirtyRect: NSRect) {
        NSColor.systemOrange.withAlphaComponent(0.18).setStroke()
        let glow = NSBezierPath(roundedRect: bounds.insetBy(dx: 15, dy: 15), xRadius: 18, yRadius: 18)
        glow.lineWidth = 30 + 12 * pulse
        glow.stroke()
        NSColor.systemOrange.setStroke()
        let border = NSBezierPath(roundedRect: bounds.insetBy(dx: 10, dy: 10), xRadius: 12, yRadius: 12)
        border.lineWidth = 12 + 8 * pulse
        border.stroke()

        let text = NSAttributedString(string: message, attributes: [
            .font: NSFont.systemFont(ofSize: 28, weight: .bold),
            .foregroundColor: NSColor.systemOrange,
        ])
        let instruction = NSAttributedString(string: "Press Esc or click to exit", attributes: [
            .font: NSFont.systemFont(ofSize: 20, weight: .medium),
            .foregroundColor: NSColor.white,
        ])
        let size = text.size()
        let width = max(size.width, instruction.size().width) + 64
        let box = CGRect(x: (bounds.width - width) / 2, y: bounds.midY - 66,
                         width: width, height: 132)
        NSColor.black.withAlphaComponent(0.95).setFill()
        NSBezierPath(roundedRect: box, xRadius: 10, yRadius: 10).fill()
        NSColor.systemOrange.setStroke()
        let outline = NSBezierPath(roundedRect: box, xRadius: 10, yRadius: 10)
        outline.lineWidth = 2 + 2 * pulse
        outline.stroke()
        text.draw(at: CGPoint(x: bounds.midX - size.width / 2, y: box.minY + 26))
        instruction.draw(at: CGPoint(x: bounds.midX - instruction.size().width / 2, y: box.minY + 78))
    }
}
