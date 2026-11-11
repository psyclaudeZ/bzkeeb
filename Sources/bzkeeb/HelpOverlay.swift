import AppKit

enum HelpOverlay {
    static func draw(in bounds: CGRect, prefix: String, returnToScroll: Bool) {
        let size = CGSize(width: 680, height: 611)
        let scale = min(1, min((bounds.width - 40) / size.width, (bounds.height - 40) / size.height))
        guard scale > 0, let context = NSGraphicsContext.current?.cgContext else { return }
        context.saveGState()
        defer { context.restoreGState() }
        context.translateBy(x: bounds.midX - size.width * scale / 2, y: bounds.midY - size.height * scale / 2)
        context.scaleBy(x: scale, y: scale)

        NSColor(calibratedWhite: 0.08, alpha: 0.97).setFill()
        NSBezierPath(roundedRect: CGRect(origin: .zero, size: size), xRadius: 16, yRadius: 16).fill()

        func text(_ value: String, x: CGFloat = 28, y: CGFloat, font: NSFont, color: NSColor = .white) {
            NSAttributedString(string: value, attributes: [.font: font, .foregroundColor: color])
                .draw(at: CGPoint(x: x, y: y))
        }
        let body = NSFont.systemFont(ofSize: 15)
        let keyFont = NSFont.monospacedSystemFont(ofSize: 15, weight: .medium)
        let muted = NSColor(calibratedWhite: 0.7, alpha: 1)
        text("Keyboard controls", y: 24, font: .systemFont(ofSize: 24, weight: .semibold))
        text("bzkeeb  ·  ⌥ Option    ⇧ Shift    ⌘ Command", y: 58, font: .systemFont(ofSize: 13), color: muted)

        var y: CGFloat = 96
        func section(_ title: String, rows: [(String, String)]) {
            text(title, y: y, font: .systemFont(ofSize: 12, weight: .bold), color: .systemCyan)
            y += 26
            for (key, action) in rows {
                text(key, y: y, font: keyFont)
                text(action, x: 290, y: y, font: body)
                y += 25
            }
            y += 15
        }
        section("ACTIVATE", rows: [
            ("\(prefix)F", "Find a target and click"),
            ("\(prefix)O", "Find a target and hover"),
            ("\(prefix)R", "Find a target and right-click"),
            ("\(prefix)G", "Grid → scroll mode"),
            ("\(prefix)S", "Scroll mode"),
        ])
        section("SCROLL MODE", rows: [
            ("h j k l", "Scroll left / down / up / right"),
            ("u / d", "Page up / down"),
            ("⌥ + hjkl  or  arrows", "Move pointer fast · 40 px"),
            ("Add ⇧ to either", "Move pointer slowly · 10 px"),
            ("Return / Space", "Click or drop, then exit"),
            ("r / x", "Right-click / double-click, then exit"),
            ("v", "Start dragging; move and scroll as usual"),
            ("Esc / mouse click", "Exit mode; release any active drag"),
        ])
        text("Opening help releases an active drag.  ⌘, opens settings.", y: y, font: .systemFont(ofSize: 13), color: muted)
        let close = returnToScroll ? "return to scroll mode" : "close help"
        text("Esc or \(prefix)/  ·  \(close)", y: y + 30, font: .systemFont(ofSize: 14, weight: .medium))
    }
}
