import AppKit

enum OverlayStyle {
    static let background = NSColor(calibratedWhite: 0.08, alpha: 0.97)
    static let foreground = NSColor.white
    static let accent = NSColor.systemCyan
    static let title = NSFont.systemFont(ofSize: 24, weight: .semibold)
    static let body = NSFont.systemFont(ofSize: 15)
    static let key = NSFont.monospacedSystemFont(ofSize: 15, weight: .medium)
    static let heading = NSFont.systemFont(ofSize: 12, weight: .bold)

    static func drawPanel(_ rect: CGRect) {
        background.setFill()
        NSBezierPath(roundedRect: rect, xRadius: 16, yRadius: 16).fill()
    }

    static func drawLabel(_ value: String, in bounds: CGRect, centered: Bool = false) {
        let text = NSAttributedString(string: value, attributes: [
            .font: centered ? title : body,
            .foregroundColor: foreground,
        ])
        let size = text.size()
        let height = size.height + 24
        let box = CGRect(x: bounds.midX - size.width / 2 - 20,
                         y: centered ? bounds.midY - height / 2 : bounds.maxY - height - 20,
                         width: size.width + 40, height: height)
        drawPanel(box)
        text.draw(at: CGPoint(x: box.minX + 20, y: box.minY + 12))
    }
}
