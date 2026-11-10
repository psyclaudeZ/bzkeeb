import CoreGraphics
import Testing
@testable import bzkeeb

@Test func scrollingDirectionsAndPageDistance() {
    let cases: [(Int64, MouseCommand)] = [
        (4, .scroll(vertical: 0, horizontal: 70)),
        (38, .scroll(vertical: -70, horizontal: 0)),
        (40, .scroll(vertical: 70, horizontal: 0)),
        (37, .scroll(vertical: 0, horizontal: -70)),
        (32, .scroll(vertical: 600, horizontal: 0)),
        (2, .scroll(vertical: -600, horizontal: 0)),
    ]
    for (key, command) in cases {
        #expect(MouseCommand.decode(keyCode: key, flags: []) == command)
    }
}

@Test func optionAndArrowsShareFastAndSlowMovement() {
    let directions: [(Int64, Int64, CGFloat, CGFloat)] = [
        (4, 123, -1, 0), (38, 125, 0, 1), (40, 126, 0, -1), (37, 124, 1, 0),
    ]
    for (letter, arrow, dx, dy) in directions {
        #expect(MouseCommand.decode(keyCode: letter, flags: .maskAlternate) == .move(dx: dx * 40, dy: dy * 40))
        #expect(MouseCommand.decode(keyCode: arrow, flags: []) == .move(dx: dx * 40, dy: dy * 40))
        #expect(MouseCommand.decode(keyCode: letter, flags: [.maskAlternate, .maskShift]) == .move(dx: dx * 10, dy: dy * 10))
        #expect(MouseCommand.decode(keyCode: arrow, flags: .maskShift) == .move(dx: dx * 10, dy: dy * 10))
        // macOS may mark arrow events with the secondary Fn flag.
        #expect(MouseCommand.decode(keyCode: arrow, flags: .maskSecondaryFn) == .move(dx: dx * 40, dy: dy * 40))
    }
}

@Test func clickAndDragBindings() {
    for key: Int64 in [36, 76, 49] {
        #expect(MouseCommand.decode(keyCode: key, flags: []) == .click)
    }
    #expect(MouseCommand.decode(keyCode: 15, flags: []) == .rightClick)
    #expect(MouseCommand.decode(keyCode: 7, flags: []) == .doubleClick)
    #expect(MouseCommand.decode(keyCode: 9, flags: []) == .beginDrag)
}

@Test func unrelatedModifiersDoNotTriggerMouseActions() {
    for key: Int64 in [4, 38, 40, 37, 123, 124, 125, 126, 36, 76, 49, 15, 7, 9, 32, 2] {
        #expect(MouseCommand.decode(keyCode: key, flags: .maskCommand) == nil)
        #expect(MouseCommand.decode(keyCode: key, flags: .maskControl) == nil)
    }
    #expect(MouseCommand.decode(keyCode: 38, flags: .maskShift) == nil)
    #expect(MouseCommand.decode(keyCode: 2, flags: .maskAlternate) == nil)
    #expect(MouseCommand.decode(keyCode: 0, flags: []) == nil)
    #expect(MouseCommand.decode(keyCode: 38, flags: .maskAlphaShift) == .scroll(vertical: -70, horizontal: 0))
}
