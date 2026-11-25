import UIKit

/// A keyboard shortcut, parsed into the two pieces `UIKeyCommand` asks for.
///
/// Uses Electron/Tauri accelerator strings (`"CmdOrCtrl+Shift+P"`) so existing desktop menu
/// definitions can be reused.
public struct MenuBarShortcut: Equatable {
    /// What `UIKeyCommand.input` wants: the bare key, lowercased, modifiers excluded.
    public let input: String
    public let modifiers: UIKeyModifierFlags

    public init(input: String, modifiers: UIKeyModifierFlags = []) {
        self.input = input
        self.modifiers = modifiers
    }

    /// Parses an accelerator string. Nil if any component is unrecognised.
    public init?(accelerator: String) {
        guard let tokens = Self.tokens(of: accelerator),
              let input = Self.input(named: tokens.key),
              let modifiers = Self.modifiers(named: tokens.modifiers) else {
            return nil
        }

        self.init(input: input, modifiers: modifiers)
    }

    /// Splits an accelerator into its modifier names and its key.
    ///
    /// `"CmdOrCtrl++"` splits into `["CmdOrCtrl", "", ""]` because the key is the separator
    /// itself, so a trailing empty pair means the key is `+`. A single trailing empty token
    /// (`"Cmd+"`) has no key at all and is rejected.
    private static func tokens(of accelerator: String) -> (modifiers: [String], key: String)? {
        let components = accelerator
            .components(separatedBy: "+")
            .map { component in component.trimmingCharacters(in: .whitespaces) }

        if components.count >= 2, components.suffix(2).allSatisfy(\.isEmpty) {
            return (Array(components.dropLast(2)), "+")
        }

        guard let key = components.last, !key.isEmpty else {
            return nil
        }

        return (Array(components.dropLast()), key)
    }

    private static func modifiers(named tokens: [String]) -> UIKeyModifierFlags? {
        let flags = tokens.compactMap { token in modifierFlags[token.lowercased()] }

        guard flags.count == tokens.count else {
            return nil
        }

        return UIKeyModifierFlags(flags)
    }

    /// Single characters are lowercased because Shift is carried in the modifier flags. An input
    /// of `"M"` would describe a key combination that can't be typed.
    private static func input(named token: String) -> String? {
        guard token.count == 1 else {
            return namedKeys[token.lowercased()]
        }

        return token.lowercased()
    }

    private static let modifierFlags: [String: UIKeyModifierFlags] = [
        "cmd": .command,
        "command": .command,
        "cmdorctrl": .command,
        "commandorcontrol": .command,
        "super": .command,
        "meta": .command,
        "ctrl": .control,
        "control": .control,
        "alt": .alternate,
        "option": .alternate,
        "opt": .alternate,
        "shift": .shift,
        "capslock": .alphaShift
    ]

    private static let namedKeys: [String: String] = [
        "space": " ",
        "tab": "\t",
        "enter": "\r",
        "return": "\r",
        "backspace": "\u{8}",
        "delete": UIKeyCommand.inputDelete,
        "del": UIKeyCommand.inputDelete,
        "escape": UIKeyCommand.inputEscape,
        "esc": UIKeyCommand.inputEscape,
        "up": UIKeyCommand.inputUpArrow,
        "down": UIKeyCommand.inputDownArrow,
        "left": UIKeyCommand.inputLeftArrow,
        "right": UIKeyCommand.inputRightArrow,
        "home": UIKeyCommand.inputHome,
        "end": UIKeyCommand.inputEnd,
        "pageup": UIKeyCommand.inputPageUp,
        "pagedown": UIKeyCommand.inputPageDown,
        "plus": "+",
        "minus": "-",
        "comma": ",",
        "f1": UIKeyCommand.f1,
        "f2": UIKeyCommand.f2,
        "f3": UIKeyCommand.f3,
        "f4": UIKeyCommand.f4,
        "f5": UIKeyCommand.f5,
        "f6": UIKeyCommand.f6,
        "f7": UIKeyCommand.f7,
        "f8": UIKeyCommand.f8,
        "f9": UIKeyCommand.f9,
        "f10": UIKeyCommand.f10,
        "f11": UIKeyCommand.f11,
        "f12": UIKeyCommand.f12
    ]
}
