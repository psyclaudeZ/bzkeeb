import CoreGraphics

enum MouseController {
    static let eventMarker: Int64 = 0x627a6b656562

    private static func source() -> CGEventSource? {
        let source = CGEventSource(stateID: .hidSystemState)
        source?.userData = eventMarker
        return source
    }

    static func location() -> CGPoint {
        CGEvent(source: nil)?.location ?? .zero
    }

    static func move(to point: CGPoint, dragging: Bool = false) {
        let eventType: CGEventType = dragging ? .leftMouseDragged : .mouseMoved
        CGEvent(
            mouseEventSource: source(),
            mouseType: eventType,
            mouseCursorPosition: point,
            mouseButton: .left
        )?.post(tap: .cghidEventTap)
    }

    static func click(at point: CGPoint, button: CGMouseButton = .left, count: Int64 = 1) {
        move(to: point)
        let downType: CGEventType = button == .right ? .rightMouseDown : .leftMouseDown
        let upType: CGEventType = button == .right ? .rightMouseUp : .leftMouseUp
        let down = CGEvent(mouseEventSource: source(), mouseType: downType, mouseCursorPosition: point, mouseButton: button)
        let up = CGEvent(mouseEventSource: source(), mouseType: upType, mouseCursorPosition: point, mouseButton: button)
        down?.setIntegerValueField(.mouseEventClickState, value: count)
        up?.setIntegerValueField(.mouseEventClickState, value: count)
        down?.post(tap: .cghidEventTap)
        up?.post(tap: .cghidEventTap)
    }

    static func beginDrag(at point: CGPoint) {
        CGEvent(
            mouseEventSource: source(),
            mouseType: .leftMouseDown,
            mouseCursorPosition: point,
            mouseButton: .left
        )?.post(tap: .cghidEventTap)
    }

    static func endDrag(at point: CGPoint) {
        CGEvent(
            mouseEventSource: source(),
            mouseType: .leftMouseUp,
            mouseCursorPosition: point,
            mouseButton: .left
        )?.post(tap: .cghidEventTap)
    }

    static func scroll(vertical: Int32, horizontal: Int32) {
        CGEvent(
            scrollWheelEvent2Source: source(),
            units: .pixel,
            wheelCount: 2,
            wheel1: vertical,
            wheel2: horizontal,
            wheel3: 0
        )?.post(tap: .cghidEventTap)
    }
}

