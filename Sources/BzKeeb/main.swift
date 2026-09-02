import AppKit
import ApplicationServices
import CoreGraphics

private enum HintAction: Equatable {
    case click
    case hover
    case rightClick

    var status: String {
        switch self {
        case .click: return "HINT CLICK"
        case .hover: return "HINT HOVER"
        case .rightClick: return "HINT RIGHT CLICK"
        }
    }
}

private struct DiscoveredTarget {
    let rect: CGRect
    let title: String
    let role: String
    let depth: Int
}

private struct HintTarget {
    let rect: CGRect
    let title: String
    let code: String
}

private struct HintState {
    let action: HintAction
    let targets: [HintTarget]
    var typed = ""
}

private struct GridState {
    var rect: CGRect
    var depth: Int
}

private struct PrecisionState {
    var point: CGPoint
    var dragging: Bool
}

private enum Mode {
    case idle
    case scanning(HintAction)
    case hints(HintState)
    case grid(GridState)
    case precision(PrecisionState)
    case scroll
}

private enum OverlayModel {
    case status(String)
    case hints([HintTarget], String, String)
    case grid(CGRect, Int)
    case pointer(CGPoint, String)
}

private struct ScreenGeometry {
    let screen: NSScreen
    let cgBounds: CGRect
}

private final class OverlayView: NSView {
    let cgBounds: CGRect
    var model: OverlayModel? {
        didSet { needsDisplay = true }
    }

    init(frame: CGRect, cgBounds: CGRect) {
        self.cgBounds = cgBounds
        super.init(frame: frame)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var isFlipped: Bool { true }

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        guard let model else { return }

        switch model {
        case .status(let text):
            drawStatus(text)

        case .hints(let targets, let typed, let status):
            for target in targets where target.code.hasPrefix(typed) {
                guard target.rect.intersects(cgBounds) else { continue }
                let local = localRect(target.rect)
                NSColor.systemYellow.withAlphaComponent(0.35).setStroke()
                let outline = NSBezierPath(rect: local)
                outline.lineWidth = 1
                outline.stroke()
                drawChip(target.code, at: CGPoint(x: local.midX, y: local.midY))
            }
            drawStatus(typed.isEmpty ? status : "\(status)  \(typed)")

        case .grid(let rect, let depth):
            guard rect.intersects(cgBounds) else { return }
            let local = localRect(rect)
            NSColor.systemCyan.withAlphaComponent(0.9).setStroke()
            let border = NSBezierPath(rect: local)
            border.lineWidth = 3
            border.stroke()

            let keys = [["q", "w", "e"], ["a", "s", "d"], ["z", "x", "c"]]
            let cellWidth = local.width / 3
            let cellHeight = local.height / 3
            for row in 0..<3 {
                for column in 0..<3 {
                    let cell = CGRect(
                        x: local.minX + CGFloat(column) * cellWidth,
                        y: local.minY + CGFloat(row) * cellHeight,
                        width: cellWidth,
                        height: cellHeight
                    )
                    NSColor.systemCyan.withAlphaComponent(0.55).setStroke()
                    let path = NSBezierPath(rect: cell)
                    path.lineWidth = 1
                    path.stroke()
                    drawChip(keys[row][column], at: CGPoint(x: cell.midX, y: cell.midY), color: .systemCyan)
                }
            }
            drawStatus("GRID \(depth + 1)/3")

        case .pointer(let point, let status):
            guard cgBounds.contains(point) else { return }
            let local = localPoint(point)
            NSColor.systemPink.setStroke()
            let horizontal = NSBezierPath()
            horizontal.move(to: CGPoint(x: local.x - 18, y: local.y))
            horizontal.line(to: CGPoint(x: local.x + 18, y: local.y))
            horizontal.lineWidth = 2
            horizontal.stroke()
            let vertical = NSBezierPath()
            vertical.move(to: CGPoint(x: local.x, y: local.y - 18))
            vertical.line(to: CGPoint(x: local.x, y: local.y + 18))
            vertical.lineWidth = 2
            vertical.stroke()
            drawStatus(status)
        }
    }

    private func localPoint(_ point: CGPoint) -> CGPoint {
        CGPoint(x: point.x - cgBounds.minX, y: point.y - cgBounds.minY)
    }

    private func localRect(_ rect: CGRect) -> CGRect {
        CGRect(
            x: rect.minX - cgBounds.minX,
            y: rect.minY - cgBounds.minY,
            width: rect.width,
            height: rect.height
        )
    }

    private func drawChip(_ text: String, at point: CGPoint, color: NSColor = .systemYellow) {
        let attributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.monospacedSystemFont(ofSize: 16, weight: .bold),
            .foregroundColor: NSColor.black,
        ]
        let string = NSAttributedString(string: text, attributes: attributes)
        let textSize = string.size()
        let chip = CGRect(
            x: point.x - textSize.width / 2 - 5,
            y: point.y - textSize.height / 2 - 2,
            width: textSize.width + 10,
            height: textSize.height + 4
        )
        color.setFill()
        NSBezierPath(roundedRect: chip, xRadius: 4, yRadius: 4).fill()
        string.draw(at: CGPoint(x: chip.minX + 5, y: chip.minY + 2))
    }

    private func drawStatus(_ text: String) {
        let attributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.monospacedSystemFont(ofSize: 15, weight: .semibold),
            .foregroundColor: NSColor.white,
        ]
        let string = NSAttributedString(string: text, attributes: attributes)
        let textSize = string.size()
        let box = CGRect(
            x: (bounds.width - textSize.width) / 2 - 10,
            y: bounds.height - textSize.height - 30,
            width: textSize.width + 20,
            height: textSize.height + 10
        )
        NSColor.black.withAlphaComponent(0.82).setFill()
        NSBezierPath(roundedRect: box, xRadius: 6, yRadius: 6).fill()
        string.draw(at: CGPoint(x: box.minX + 10, y: box.minY + 5))
    }
}

private final class OverlayController {
    private struct Entry {
        let window: NSWindow
        let view: OverlayView
    }

    private var entries: [Entry] = []

    func show(_ model: OverlayModel) {
        ensureWindows()
        for entry in entries {
            entry.view.model = model
            entry.window.orderFrontRegardless()
        }
    }

    func hide() {
        for entry in entries {
            entry.window.orderOut(nil)
            entry.view.model = nil
        }
    }

    private func ensureWindows() {
        let geometries = currentScreenGeometries()
        if entries.count == geometries.count { return }

        for entry in entries {
            entry.window.close()
        }
        entries.removeAll()

        for geometry in geometries {
            let window = NSWindow(
                contentRect: geometry.screen.frame,
                styleMask: .borderless,
                backing: .buffered,
                defer: false
            )
            window.setFrame(geometry.screen.frame, display: true)
            window.isOpaque = false
            window.backgroundColor = .clear
            window.hasShadow = false
            window.ignoresMouseEvents = true
            window.hidesOnDeactivate = false
            window.level = .statusBar
            window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary]

            let view = OverlayView(
                frame: CGRect(origin: .zero, size: geometry.screen.frame.size),
                cgBounds: geometry.cgBounds
            )
            window.contentView = view
            entries.append(Entry(window: window, view: view))
        }
    }
}

private enum MouseController {
    private static func source() -> CGEventSource? {
        CGEventSource(stateID: .hidSystemState)
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

private enum AccessibilityScanner {
    private static let actionableRoles: Set<String> = [
        "AXButton", "AXCheckBox", "AXRadioButton", "AXPopUpButton", "AXMenuButton",
        "AXLink", "AXTextField", "AXTextArea", "AXSearchField", "AXComboBox",
        "AXSlider", "AXTab", "AXRow", "AXCell", "AXDisclosureTriangle",
    ]

    static func scan(pid: pid_t, visibleBounds: [CGRect]) -> [DiscoveredTarget] {
        let application = AXUIElementCreateApplication(pid)
        AXUIElementSetMessagingTimeout(application, 0.25)

        let root: AXUIElement
        if let focused = attribute(application, kAXFocusedWindowAttribute as CFString),
           CFGetTypeID(focused) == AXUIElementGetTypeID() {
            root = unsafeBitCast(focused, to: AXUIElement.self)
        } else {
            root = application
        }

        var stack: [(AXUIElement, Int)] = [(root, 0)]
        var visited = Set<CFHashCode>()
        var candidates: [DiscoveredTarget] = []
        var examined = 0

        while let (element, depth) = stack.popLast(), examined < 7_000 {
            examined += 1
            let identity = CFHash(element)
            guard visited.insert(identity).inserted else { continue }

            if boolAttribute(element, kAXHiddenAttribute as CFString) == true {
                continue
            }

            let role = stringAttribute(element, kAXRoleAttribute as CFString) ?? ""
            let actions = actionNames(element)
            if (actionableRoles.contains(role) || actions.contains(kAXPressAction as String)),
               boolAttribute(element, kAXEnabledAttribute as CFString) != false,
               let rect = rectAttribute(element),
               rect.width >= 3,
               rect.height >= 3,
               rect.width < 4_000,
               rect.height < 4_000,
               visibleBounds.contains(where: { $0.intersects(rect) }) {
                let title = stringAttribute(element, kAXTitleAttribute as CFString)
                    ?? stringAttribute(element, kAXDescriptionAttribute as CFString)
                    ?? role.replacingOccurrences(of: "AX", with: "")
                candidates.append(DiscoveredTarget(rect: rect, title: title, role: role, depth: depth))
            }

            if depth < 45, let children = childrenAttribute(element) {
                for child in children.reversed() {
                    stack.append((child, depth + 1))
                }
            }
        }

        var deduplicated: [String: DiscoveredTarget] = [:]
        for candidate in candidates {
            let key = [candidate.rect.minX, candidate.rect.minY, candidate.rect.width, candidate.rect.height]
                .map { String(Int($0.rounded())) }
                .joined(separator: ":")
            if let existing = deduplicated[key], existing.depth > candidate.depth {
                continue
            }
            deduplicated[key] = candidate
        }

        return deduplicated.values
            .sorted {
                if abs($0.rect.midY - $1.rect.midY) > 4 { return $0.rect.midY < $1.rect.midY }
                return $0.rect.midX < $1.rect.midX
            }
            .prefix(500)
            .map { $0 }
    }

    private static func attribute(_ element: AXUIElement, _ name: CFString) -> CFTypeRef? {
        var value: CFTypeRef?
        guard AXUIElementCopyAttributeValue(element, name, &value) == .success else { return nil }
        return value
    }

    private static func stringAttribute(_ element: AXUIElement, _ name: CFString) -> String? {
        attribute(element, name) as? String
    }

    private static func boolAttribute(_ element: AXUIElement, _ name: CFString) -> Bool? {
        attribute(element, name) as? Bool
    }

    private static func childrenAttribute(_ element: AXUIElement) -> [AXUIElement]? {
        attribute(element, kAXChildrenAttribute as CFString) as? [AXUIElement]
    }

    private static func actionNames(_ element: AXUIElement) -> Set<String> {
        var names: CFArray?
        guard AXUIElementCopyActionNames(element, &names) == .success,
              let values = names as? [String] else { return [] }
        return Set(values)
    }

    private static func rectAttribute(_ element: AXUIElement) -> CGRect? {
        guard let positionValue = attribute(element, kAXPositionAttribute as CFString),
              let sizeValue = attribute(element, kAXSizeAttribute as CFString),
              CFGetTypeID(positionValue) == AXValueGetTypeID(),
              CFGetTypeID(sizeValue) == AXValueGetTypeID() else { return nil }

        let positionAX = unsafeBitCast(positionValue, to: AXValue.self)
        let sizeAX = unsafeBitCast(sizeValue, to: AXValue.self)
        var point = CGPoint.zero
        var size = CGSize.zero
        guard AXValueGetValue(positionAX, .cgPoint, &point),
              AXValueGetValue(sizeAX, .cgSize, &size) else { return nil }
        return CGRect(origin: point, size: size)
    }
}

private final class AppDelegate: NSObject, NSApplicationDelegate {
    private let overlays = OverlayController()
    private var mode: Mode = .idle
    private var eventTap: CFMachPort?
    private var eventTapSource: CFRunLoopSource?
    private var statusItem: NSStatusItem?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        installMenuBarItem()

        if accessibilityIsTrusted(prompt: true) {
            installEventTap()
        } else {
            showPermissionAlert()
        }
    }

    func applicationWillTerminate(_ notification: Notification) {
        cancelCurrentMode()
        if let eventTapSource {
            CFRunLoopRemoveSource(CFRunLoopGetMain(), eventTapSource, .commonModes)
        }
    }

    func handleTapEvent(type: CGEventType, event: CGEvent) -> Unmanaged<CGEvent>? {
        if type == .tapDisabledByTimeout || type == .tapDisabledByUserInput {
            if let eventTap { CGEvent.tapEnable(tap: eventTap, enable: true) }
            return Unmanaged.passUnretained(event)
        }

        guard type == .keyDown || type == .keyUp else {
            return Unmanaged.passUnretained(event)
        }

        if case .idle = mode {
            guard type == .keyDown, let command = globalCommand(for: event) else {
                return Unmanaged.passUnretained(event)
            }
            run(command)
            return nil
        }

        if type == .keyDown {
            handleModeKey(event)
        }
        return nil
    }

    private func installMenuBarItem() {
        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        item.button?.title = "BK"

        let menu = NSMenu()
        let title = NSMenuItem(title: "BzKeeb plumbing prototype", action: nil, keyEquivalent: "")
        title.isEnabled = false
        menu.addItem(title)
        menu.addItem(.separator())
        menu.addItem(NSMenuItem(title: "⌃⌥F  Hint click", action: nil, keyEquivalent: ""))
        menu.addItem(NSMenuItem(title: "⌃⌥M  Hint hover", action: nil, keyEquivalent: ""))
        menu.addItem(NSMenuItem(title: "⌃⌥R  Hint right-click", action: nil, keyEquivalent: ""))
        menu.addItem(NSMenuItem(title: "⌃⌥G  Grid → precision", action: nil, keyEquivalent: ""))
        menu.addItem(NSMenuItem(title: "⌃⌥P  Precision", action: nil, keyEquivalent: ""))
        menu.addItem(NSMenuItem(title: "⌃⌥S  Scroll", action: nil, keyEquivalent: ""))
        menu.addItem(.separator())

        let permission = NSMenuItem(title: "Check Accessibility permission", action: #selector(checkPermission), keyEquivalent: "")
        permission.target = self
        menu.addItem(permission)
        let quit = NSMenuItem(title: "Quit BzKeeb", action: #selector(quit), keyEquivalent: "q")
        quit.target = self
        menu.addItem(quit)

        item.menu = menu
        statusItem = item
    }

    private func installEventTap() {
        let mask = (CGEventMask(1) << CGEventType.keyDown.rawValue)
            | (CGEventMask(1) << CGEventType.keyUp.rawValue)
        let pointer = Unmanaged.passUnretained(self).toOpaque()
        guard let tap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: mask,
            callback: eventTapCallback,
            userInfo: pointer
        ) else {
            showEventTapAlert()
            return
        }

        eventTap = tap
        let source = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0)
        eventTapSource = source
        CFRunLoopAddSource(CFRunLoopGetMain(), source, .commonModes)
        CGEvent.tapEnable(tap: tap, enable: true)
    }

    private func globalCommand(for event: CGEvent) -> String? {
        let relevant: CGEventFlags = [.maskCommand, .maskShift, .maskControl, .maskAlternate]
        guard event.flags.intersection(relevant) == [.maskControl, .maskAlternate] else { return nil }
        switch event.getIntegerValueField(.keyboardEventKeycode) {
        case 3: return "hint-click"     // F
        case 46: return "hint-hover"    // M
        case 15: return "hint-right"    // R
        case 5: return "grid"           // G
        case 35: return "precision"     // P
        case 1: return "scroll"         // S
        default: return nil
        }
    }

    private func run(_ command: String) {
        switch command {
        case "hint-click": beginHints(action: .click)
        case "hint-hover": beginHints(action: .hover)
        case "hint-right": beginHints(action: .rightClick)
        case "grid": beginGrid()
        case "precision": beginPrecision(at: MouseController.location())
        case "scroll": beginScroll()
        default: break
        }
    }

    private func beginHints(action: HintAction) {
        guard accessibilityIsTrusted(prompt: true) else {
            showPermissionAlert()
            return
        }
        guard let app = NSWorkspace.shared.frontmostApplication,
              app.processIdentifier != ProcessInfo.processInfo.processIdentifier else {
            NSSound.beep()
            return
        }

        mode = .scanning(action)
        overlays.show(.status("SCANNING ACCESSIBILITY…"))
        let bounds = currentScreenGeometries().map(\.cgBounds)
        let pid = app.processIdentifier

        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            let targets = AccessibilityScanner.scan(pid: pid, visibleBounds: bounds)
            DispatchQueue.main.async {
                self?.finishHintScan(targets, action: action)
            }
        }
    }

    private func finishHintScan(_ targets: [DiscoveredTarget], action: HintAction) {
        guard case .scanning(let currentAction) = mode, currentAction == action else { return }
        guard !targets.isEmpty else {
            overlays.show(.status("NO TARGETS — TRY ⌃⌥G"))
            mode = .idle
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) { [weak self] in
                if case .idle = self?.mode { self?.overlays.hide() }
            }
            return
        }

        let codes = makeHintCodes(count: targets.count)
        let hints = zip(targets, codes).map {
            HintTarget(rect: $0.0.rect, title: $0.0.title, code: $0.1)
        }
        let state = HintState(action: action, targets: hints)
        mode = .hints(state)
        overlays.show(.hints(hints, "", action.status))
    }

    private func beginGrid() {
        let point = MouseController.location()
        guard let bounds = displayBounds(containing: point) else { return }
        let state = GridState(rect: bounds, depth: 0)
        mode = .grid(state)
        overlays.show(.grid(state.rect, state.depth))
    }

    private func beginPrecision(at point: CGPoint) {
        let state = PrecisionState(point: point, dragging: false)
        mode = .precision(state)
        overlays.show(.pointer(point, "PRECISION  hjkl · v drag · ↩ click · esc"))
    }

    private func beginScroll() {
        mode = .scroll
        overlays.show(.pointer(MouseController.location(), "SCROLL  hjkl · u/d page · esc"))
    }

    private func handleModeKey(_ event: CGEvent) {
        let keyCode = event.getIntegerValueField(.keyboardEventKeycode)
        if keyCode == 53 { // Escape
            cancelCurrentMode()
            return
        }

        switch mode {
        case .idle:
            break
        case .scanning:
            break
        case .hints(var state):
            if keyCode == 51 { // Delete
                if !state.typed.isEmpty { state.typed.removeLast() }
                mode = .hints(state)
                overlays.show(.hints(state.targets, state.typed, state.action.status))
                return
            }
            guard let key = keyString(event), "asdfghjkl".contains(key) else {
                NSSound.beep()
                return
            }
            state.typed += key
            let matches = state.targets.filter { $0.code.hasPrefix(state.typed) }
            guard !matches.isEmpty else {
                NSSound.beep()
                state.typed = ""
                mode = .hints(state)
                overlays.show(.hints(state.targets, state.typed, state.action.status))
                return
            }
            if let exact = matches.first(where: { $0.code == state.typed }) {
                performHintAction(state.action, target: exact)
            } else {
                mode = .hints(state)
                overlays.show(.hints(state.targets, state.typed, state.action.status))
            }

        case .grid(var state):
            guard let key = keyString(event), let selection = gridSelection(for: key) else {
                NSSound.beep()
                return
            }
            state.rect = gridCell(in: state.rect, column: selection.column, row: selection.row)
            state.depth += 1
            let point = CGPoint(x: state.rect.midX, y: state.rect.midY)
            MouseController.move(to: point)
            if state.depth >= 3 {
                beginPrecision(at: point)
            } else {
                mode = .grid(state)
                overlays.show(.grid(state.rect, state.depth))
            }

        case .precision(var state):
            if keyCode == 36 || keyCode == 76 || keyCode == 49 { // Return, keypad Enter, Space
                overlays.hide()
                if state.dragging {
                    MouseController.endDrag(at: state.point)
                } else {
                    MouseController.click(at: state.point)
                }
                mode = .idle
                return
            }
            guard let key = keyString(event) else { return }
            let step: CGFloat = event.flags.contains(.maskShift) ? 40 : 10
            var next = state.point
            switch key {
            case "h": next.x -= step
            case "j": next.y += step
            case "k": next.y -= step
            case "l": next.x += step
            case "v" where !state.dragging:
                MouseController.beginDrag(at: state.point)
                state.dragging = true
            case "r" where !state.dragging:
                overlays.hide()
                MouseController.click(at: state.point, button: .right)
                mode = .idle
                return
            case "d" where !state.dragging:
                overlays.hide()
                MouseController.click(at: state.point, count: 2)
                mode = .idle
                return
            default:
                NSSound.beep()
                return
            }
            if next != state.point {
                state.point = next
                MouseController.move(to: next, dragging: state.dragging)
            }
            mode = .precision(state)
            let status = state.dragging ? "DRAGGING  hjkl · ↩ drop · esc" : "PRECISION  hjkl · v drag · ↩ click · esc"
            overlays.show(.pointer(state.point, status))

        case .scroll:
            guard let key = keyString(event) else { return }
            let amount: Int32 = event.flags.contains(.maskShift) ? 240 : 70
            switch key {
            case "j": MouseController.scroll(vertical: -amount, horizontal: 0)
            case "k": MouseController.scroll(vertical: amount, horizontal: 0)
            case "h": MouseController.scroll(vertical: 0, horizontal: amount)
            case "l": MouseController.scroll(vertical: 0, horizontal: -amount)
            case "d": MouseController.scroll(vertical: -600, horizontal: 0)
            case "u": MouseController.scroll(vertical: 600, horizontal: 0)
            default: NSSound.beep()
            }
        }
    }

    private func performHintAction(_ action: HintAction, target: HintTarget) {
        overlays.hide()
        mode = .idle
        let point = CGPoint(x: target.rect.midX, y: target.rect.midY)
        switch action {
        case .click:
            MouseController.click(at: point)
        case .hover:
            MouseController.move(to: point)
        case .rightClick:
            MouseController.click(at: point, button: .right)
        }
    }

    private func cancelCurrentMode() {
        if case .precision(let state) = mode, state.dragging {
            MouseController.endDrag(at: state.point)
        }
        mode = .idle
        overlays.hide()
    }

    private func accessibilityIsTrusted(prompt: Bool) -> Bool {
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: prompt] as CFDictionary
        return AXIsProcessTrustedWithOptions(options)
    }

    @objc private func checkPermission() {
        if accessibilityIsTrusted(prompt: true) {
            if eventTap == nil { installEventTap() }
            let alert = NSAlert()
            alert.messageText = "Accessibility is enabled"
            alert.informativeText = "The BzKeeb hotkeys are ready."
            alert.runModal()
        } else {
            showPermissionAlert()
        }
    }

    @objc private func quit() {
        NSApp.terminate(nil)
    }

    private func showPermissionAlert() {
        NSApp.activate(ignoringOtherApps: true)
        let alert = NSAlert()
        alert.alertStyle = .informational
        alert.messageText = "BzKeeb needs Accessibility access"
        alert.informativeText = "Enable BzKeeb in System Settings → Privacy & Security → Accessibility, then use the BK menu item to check again."
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }

    private func showEventTapAlert() {
        NSApp.activate(ignoringOtherApps: true)
        let alert = NSAlert()
        alert.alertStyle = .warning
        alert.messageText = "Could not install the global keyboard listener"
        alert.informativeText = "Toggle BzKeeb off and on in Accessibility settings, then check permission from the BK menu."
        alert.runModal()
    }
}

private func eventTapCallback(
    proxy: CGEventTapProxy,
    type: CGEventType,
    event: CGEvent,
    userInfo: UnsafeMutableRawPointer?
) -> Unmanaged<CGEvent>? {
    guard let userInfo else { return Unmanaged.passUnretained(event) }
    let delegate = Unmanaged<AppDelegate>.fromOpaque(userInfo).takeUnretainedValue()
    return delegate.handleTapEvent(type: type, event: event)
}

private func currentScreenGeometries() -> [ScreenGeometry] {
    NSScreen.screens.compactMap { screen in
        guard let number = screen.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? NSNumber else {
            return nil
        }
        return ScreenGeometry(screen: screen, cgBounds: CGDisplayBounds(CGDirectDisplayID(number.uint32Value)))
    }
}

private func displayBounds(containing point: CGPoint) -> CGRect? {
    let geometries = currentScreenGeometries()
    return geometries.first(where: { $0.cgBounds.contains(point) })?.cgBounds
        ?? geometries.first?.cgBounds
}

private func makeHintCodes(count: Int) -> [String] {
    guard count > 0 else { return [] }
    let alphabet = Array("asdfghjkl")
    var length = 1
    var capacity = alphabet.count
    while capacity < count {
        length += 1
        capacity *= alphabet.count
    }

    return (0..<count).map { index in
        var value = index
        var characters = Array(repeating: alphabet[0], count: length)
        for position in stride(from: length - 1, through: 0, by: -1) {
            characters[position] = alphabet[value % alphabet.count]
            value /= alphabet.count
        }
        return String(characters)
    }
}

private func keyString(_ event: CGEvent) -> String? {
    var actualLength = 0
    var buffer = [UniChar](repeating: 0, count: 8)
    buffer.withUnsafeMutableBufferPointer { pointer in
        event.keyboardGetUnicodeString(
            maxStringLength: pointer.count,
            actualStringLength: &actualLength,
            unicodeString: pointer.baseAddress!
        )
    }
    guard actualLength > 0 else { return nil }
    return String(utf16CodeUnits: buffer, count: actualLength).lowercased()
}

private func gridSelection(for key: String) -> (column: Int, row: Int)? {
    let selections: [String: (Int, Int)] = [
        "q": (0, 0), "w": (1, 0), "e": (2, 0),
        "a": (0, 1), "s": (1, 1), "d": (2, 1),
        "z": (0, 2), "x": (1, 2), "c": (2, 2),
    ]
    return selections[key]
}

private func gridCell(in rect: CGRect, column: Int, row: Int) -> CGRect {
    let width = rect.width / 3
    let height = rect.height / 3
    return CGRect(
        x: rect.minX + CGFloat(column) * width,
        y: rect.minY + CGFloat(row) * height,
        width: width,
        height: height
    )
}

private let application = NSApplication.shared
private let delegate = AppDelegate()
application.delegate = delegate
application.run()
