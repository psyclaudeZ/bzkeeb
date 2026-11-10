import CoreGraphics

enum MouseCommand: Equatable {
    case move(dx: CGFloat, dy: CGFloat)
    case scroll(vertical: Int32, horizontal: Int32)
    case click, rightClick, doubleClick, beginDrag

    static func decode(keyCode: Int64, flags: CGEventFlags) -> MouseCommand? {
        let modifiers = flags.intersection([.maskShift, .maskAlternate, .maskControl, .maskCommand])
        guard !modifiers.contains(.maskControl), !modifiers.contains(.maskCommand) else { return nil }

        let arrows: [Int64: (CGFloat, CGFloat)] = [
            123: (-1, 0), 124: (1, 0), 125: (0, 1), 126: (0, -1),
        ]
        // Option changes event Unicode (for example, Option+J produces ∆).
        // Use the same physical key positions as the activation shortcuts.
        let letters: [Int64: (CGFloat, CGFloat)] = [
            4: (-1, 0), 38: (0, 1), 40: (0, -1), 37: (1, 0), // H J K L
        ]
        if let direction = arrows[keyCode] {
            let step: CGFloat = modifiers.contains(.maskShift) ? 10 : 40
            return .move(dx: direction.0 * step, dy: direction.1 * step)
        }
        guard !flags.contains(.maskSecondaryFn) else { return nil }
        if let direction = letters[keyCode] {
            if modifiers.contains(.maskAlternate) {
                let step: CGFloat = modifiers.contains(.maskShift) ? 10 : 40
                return .move(dx: direction.0 * step, dy: direction.1 * step)
            }
            guard modifiers.isEmpty else { return nil }
            return .scroll(vertical: Int32(-direction.1 * 70), horizontal: Int32(-direction.0 * 70))
        }
        guard modifiers.isEmpty else { return nil }
        switch keyCode {
        case 36, 76, 49: return .click // Return, keypad Enter, Space
        case 15: return .rightClick   // R
        case 7: return .doubleClick   // X
        case 9: return .beginDrag     // V
        case 32: return .scroll(vertical: 600, horizontal: 0)  // U
        case 2: return .scroll(vertical: -600, horizontal: 0)  // D
        default: return nil
        }
    }
}
