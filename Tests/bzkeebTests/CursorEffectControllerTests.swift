import AppKit
import Testing
@testable import bzkeeb

@Test func cursorCoordinatesAcrossDisplays() {
    let positions: [(CGPoint, CGPoint)] = [
        (CGPoint(x: 100, y: 0), CGPoint(x: 100, y: 900)),
        (CGPoint(x: 100, y: 900), CGPoint(x: 100, y: 0)),
        (CGPoint(x: -400, y: 200), CGPoint(x: -400, y: 700)), // display to the left
        (CGPoint(x: 2000, y: 200), CGPoint(x: 2000, y: 700)), // display to the right
        (CGPoint(x: 100, y: -300), CGPoint(x: 100, y: 1200)), // display above
        (CGPoint(x: 100, y: 1200), CGPoint(x: 100, y: -300)), // display below
    ]
    for (quartz, appKit) in positions {
        #expect(CursorEffectController.appKitPoint(from: quartz, primaryDisplayHeight: 900) == appKit)
    }
}

@Test @MainActor func cursorEffectMovesImmediatelyAndStaysHiddenAfterDismissal() throws {
    let app = NSApplication.shared
    let controller = CursorEffectController()
    defer { controller.hide() }
    let existingWindows = Set(app.windows.map(\.windowNumber))
    controller.followCursor(at: CGPoint(x: 10, y: 20))
    #expect(Set(app.windows.map(\.windowNumber)) == existingWindows)

    controller.show(.halo)
    let window = try #require(app.windows.first {
        !existingWindows.contains($0.windowNumber) && $0.contentView is CursorEffectView
    })
    let primary = try #require(NSScreen.screens.first)
    let target = CGPoint(x: primary.frame.midX, y: primary.frame.midY)
    controller.followCursor(at: target)
    // No timer/run-loop turn is required to follow a new event position.
    #expect(window.frame.midX == target.x)
    #expect(window.frame.midY == primary.frame.maxY - target.y)

    controller.hide()
    let hiddenFrame = window.frame
    controller.followCursor(at: CGPoint(x: target.x + 80, y: target.y + 80))
    #expect(!window.isVisible)
    #expect(window.frame == hiddenFrame)

    controller.show(.halo, duration: 0)
    controller.followCursor(at: target)
    #expect(!window.isVisible)
}
