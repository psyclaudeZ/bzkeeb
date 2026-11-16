import AppKit

enum CursorEffect: String, CaseIterable {
    case waves, pulse, orbit, halo, spark

    var title: String {
        switch self {
        case .waves: return "Water waves"
        case .pulse: return "Expansion"
        case .orbit: return "Orbit"
        case .halo: return "Breathing halo"
        case .spark: return "Spark rays"
        }
    }
}

// Shared renderer: Settings previews and the real pointer use identical geometry.
final class CursorEffectView: NSView {
    var effect: CursorEffect = .waves
    var time: TimeInterval = 0
    var showPointer = false

    override func draw(_ dirtyRect: NSRect) {
        let center = CGPoint(x: bounds.midX, y: bounds.midY)
        let transform = NSAffineTransform()
        transform.translateX(by: center.x, yBy: center.y)
        transform.scale(by: min(1, bounds.width / 112))
        transform.translateX(by: -center.x, yBy: -center.y)
        transform.concat()
        let reduced = NSWorkspace.shared.accessibilityDisplayShouldReduceMotion
        let phase = reduced ? 0.35 : time.truncatingRemainder(dividingBy: 1.6) / 1.6
        func ring(_ radius: CGFloat, _ alpha: CGFloat, _ width: CGFloat = 2) {
            NSColor.systemCyan.withAlphaComponent(alpha).setStroke()
            let path = NSBezierPath(ovalIn: CGRect(x: center.x - radius, y: center.y - radius,
                                                  width: radius * 2, height: radius * 2))
            path.lineWidth = width
            path.stroke()
        }
        switch effect {
        case .waves:
            for index in 0..<3 {
                let p = (phase + Double(index) / 3).truncatingRemainder(dividingBy: 1)
                ring(10 + 36 * p, 0.85 * (1 - p))
            }
        case .pulse:
            ring(17 + 17 * (0.5 - 0.5 * cos(phase * .pi * 2)), 0.9, 3)
        case .orbit:
            ring(29, 0.25, 1)
            for index in 0..<3 {
                let angle = phase * .pi * 2 + Double(index) * .pi * 2 / 3
                let point = CGPoint(x: center.x + cos(angle) * 29, y: center.y + sin(angle) * 29)
                NSColor.systemCyan.withAlphaComponent(1 - Double(index) * 0.22).setFill()
                NSBezierPath(ovalIn: CGRect(x: point.x - 4, y: point.y - 4, width: 8, height: 8)).fill()
            }
        case .halo:
            let breath = 0.5 - 0.5 * cos(phase * .pi * 2)
            for radius in stride(from: 38, through: 18, by: -2) {
                ring(CGFloat(radius), 0.025 + 0.055 * breath, 5)
            }
            ring(18, 0.5 + 0.4 * breath, 2)
        case .spark:
            for index in 0..<8 {
                let angle = Double(index) * .pi / 4
                let length = 5 + 13 * (0.5 - 0.5 * cos(phase * .pi * 2 + Double(index) * .pi))
                let path = NSBezierPath()
                path.move(to: CGPoint(x: center.x + cos(angle) * 23, y: center.y + sin(angle) * 23))
                path.line(to: CGPoint(x: center.x + cos(angle) * (23 + length), y: center.y + sin(angle) * (23 + length)))
                path.lineWidth = 2
                path.lineCapStyle = .round
                NSColor.systemCyan.withAlphaComponent(0.8).setStroke()
                path.stroke()
            }
        }
        if showPointer {
            let pointer = NSBezierPath()
            pointer.move(to: center)
            pointer.line(to: CGPoint(x: center.x + 2, y: center.y - 17))
            pointer.line(to: CGPoint(x: center.x + 6, y: center.y - 12))
            pointer.line(to: CGPoint(x: center.x + 13, y: center.y - 12))
            pointer.close()
            NSColor.labelColor.setFill()
            pointer.fill()
        }
    }
}
