import AppKit

enum HelpOverlay {
    static func draw(in bounds: CGRect, prefix: String) {
        let size = CGSize(width: 680, height: 510)
        let scale = min(1, min((bounds.width - 40) / size.width, (bounds.height - 40) / size.height))
        guard scale > 0, let context = NSGraphicsContext.current?.cgContext else { return }
        context.saveGState()
        defer { context.restoreGState() }
        context.translateBy(x: bounds.midX - size.width * scale / 2, y: bounds.midY - size.height * scale / 2)
        context.scaleBy(x: scale, y: scale)

        OverlayStyle.drawPanel(CGRect(origin: .zero, size: size))

        func text(_ value: String, x: CGFloat = 28, y: CGFloat, font: NSFont, color: NSColor = OverlayStyle.foreground) {
            NSAttributedString(string: value, attributes: [.font: font, .foregroundColor: color])
                .draw(at: CGPoint(x: x, y: y))
        }
        let body = OverlayStyle.body
        let keyFont = OverlayStyle.key
        text("Keyboard controls", y: 24, font: OverlayStyle.title)

        var y: CGFloat = 68
        func section(_ title: String, rows: [(String, String)]) {
            text(title, y: y, font: OverlayStyle.heading, color: OverlayStyle.accent)
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
    }
}
