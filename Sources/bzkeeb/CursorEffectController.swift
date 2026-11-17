import AppKit

final class CursorEffectController {
    private var window: NSWindow?
    private var view: CursorEffectView?
    private var timer: Timer?
    private var started: TimeInterval = 0
    private var deadline: TimeInterval?
    private var primaryDisplayHeight: CGFloat = 0
    private var screenObserver: NSObjectProtocol?

    init() {
        screenObserver = NotificationCenter.default.addObserver(
            forName: NSApplication.didChangeScreenParametersNotification,
            object: nil, queue: .main
        ) { [weak self] _ in self?.refreshScreenGeometry() }
    }

    func show(_ effect: CursorEffect, duration: TimeInterval? = nil) {
        refreshScreenGeometry()
        if window == nil {
            let panel = NSWindow(contentRect: CGRect(x: 0, y: 0, width: 112, height: 112),
                                 styleMask: .borderless, backing: .buffered, defer: false)
            panel.isReleasedWhenClosed = false
            panel.isOpaque = false
            panel.backgroundColor = .clear
            panel.hasShadow = false
            panel.ignoresMouseEvents = true
            panel.hidesOnDeactivate = false
            panel.level = .screenSaver
            panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary]
            let effectView = CursorEffectView(frame: CGRect(x: 0, y: 0, width: 112, height: 112))
            panel.contentView = effectView
            window = panel
            view = effectView
        }
        view?.effect = effect
        let now = ProcessInfo.processInfo.systemUptime
        if timer == nil || duration != nil { started = now }
        deadline = duration.map { now + $0 }
        positionWindow(at: NSEvent.mouseLocation)
        tick()
        window?.orderFrontRegardless()
        if timer == nil {
            let timer = Timer(timeInterval: 1 / 30, repeats: true) { [weak self] _ in self?.tick() }
            self.timer = timer
            RunLoop.main.add(timer, forMode: .common)
        }
    }

    func hide() {
        timer?.invalidate()
        timer = nil
        window?.orderOut(nil)
    }

    // Called directly from the event tap, for physical and generated movement.
    // Do not query mouseLocation here: it can still contain the previous event's position.
    func followCursor(at quartzPoint: CGPoint) {
        guard timer != nil, window?.isVisible == true else { return }
        if let deadline, ProcessInfo.processInfo.systemUptime >= deadline { hide(); return }
        positionWindow(at: Self.appKitPoint(from: quartzPoint, primaryDisplayHeight: primaryDisplayHeight))
    }

    static func appKitPoint(from quartzPoint: CGPoint, primaryDisplayHeight: CGFloat) -> CGPoint {
        CGPoint(x: quartzPoint.x, y: primaryDisplayHeight - quartzPoint.y)
    }

    private func refreshScreenGeometry() {
        // Quartz's origin is the primary display's top-left; AppKit's is its bottom-left.
        // Cache this transform rather than querying screen geometry on every mouse event.
        primaryDisplayHeight = NSScreen.screens.first?.frame.maxY ?? 0
        if window?.isVisible == true { positionWindow(at: NSEvent.mouseLocation) }
    }

    private func tick() {
        let now = ProcessInfo.processInfo.systemUptime
        if let deadline, now >= deadline { hide(); return }
        // Animation has its own cadence; it must never overwrite event-driven positioning.
        view?.time = now - started
        view?.needsDisplay = true
    }

    private func positionWindow(at point: CGPoint) {
        window?.setFrameOrigin(CGPoint(x: point.x - 56, y: point.y - 56))
    }

    deinit {
        timer?.invalidate()
        if let screenObserver { NotificationCenter.default.removeObserver(screenObserver) }
    }
}
