import AppKit

final class CursorEffectController {
    private var window: NSWindow?
    private var view: CursorEffectView?
    private var timer: Timer?
    private var started: TimeInterval = 0
    private var deadline: TimeInterval?

    func show(_ effect: CursorEffect, duration: TimeInterval? = nil) {
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

    private func tick() {
        let now = ProcessInfo.processInfo.systemUptime
        if let deadline, now >= deadline { hide(); return }
        positionWindow(at: NSEvent.mouseLocation)
        view?.time = now - started
        view?.needsDisplay = true
    }

    private func positionWindow(at point: CGPoint) {
        window?.setFrameOrigin(CGPoint(x: point.x - 56, y: point.y - 56))
    }

    deinit { timer?.invalidate() }
}
