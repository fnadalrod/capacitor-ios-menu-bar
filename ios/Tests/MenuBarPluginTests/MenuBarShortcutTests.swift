import UIKit
import XCTest

@testable import MenuBarPlugin

final class MenuBarShortcutTests: XCTestCase {
    func testParsesTheAcceleratorShapeDesktopMenusActuallyUse() {
        let shortcut = MenuBarShortcut(accelerator: "CmdOrCtrl+Shift+P")

        XCTAssertEqual(shortcut?.input, "p")
        XCTAssertEqual(shortcut?.modifiers, [.command, .shift])
    }

    func testLowercasesLettersSoShiftOnlyTravelsInTheModifiers() {
        XCTAssertEqual(MenuBarShortcut(accelerator: "CmdOrCtrl+M")?.input, "m")
    }

    func testAcceptsTheModifierSpellingsOfEveryDesktopFramework() {
        for spelling in ["Cmd", "Command", "CmdOrCtrl", "CommandOrControl", "Super", "Meta"] {
            XCTAssertEqual(
                MenuBarShortcut(accelerator: "\(spelling)+S")?.modifiers,
                .command,
                "\(spelling) should map to Command")
        }

        XCTAssertEqual(MenuBarShortcut(accelerator: "Alt+S")?.modifiers, .alternate)
        XCTAssertEqual(MenuBarShortcut(accelerator: "Option+S")?.modifiers, .alternate)
        XCTAssertEqual(MenuBarShortcut(accelerator: "Ctrl+S")?.modifiers, .control)
    }

    func testHandlesPunctuationKeys() {
        XCTAssertEqual(MenuBarShortcut(accelerator: "CmdOrCtrl+,")?.input, ",")
        XCTAssertEqual(MenuBarShortcut(accelerator: "CmdOrCtrl+Comma")?.input, ",")
    }

    func testHandlesPlusAsAKeyEvenThoughItIsTheSeparator() {
        let shortcut = MenuBarShortcut(accelerator: "CmdOrCtrl++")

        XCTAssertEqual(shortcut?.input, "+")
        XCTAssertEqual(shortcut?.modifiers, .command)
    }

    func testResolvesNamedKeys() {
        XCTAssertEqual(MenuBarShortcut(accelerator: "Space")?.input, " ")
        XCTAssertEqual(MenuBarShortcut(accelerator: "Enter")?.input, "\r")
        XCTAssertEqual(MenuBarShortcut(accelerator: "Escape")?.input, UIKeyCommand.inputEscape)
        XCTAssertEqual(MenuBarShortcut(accelerator: "Up")?.input, UIKeyCommand.inputUpArrow)
        XCTAssertEqual(MenuBarShortcut(accelerator: "F5")?.input, UIKeyCommand.f5)
    }

    func testRejectsWhatItCannotParseInsteadOfGuessing() {
        XCTAssertNil(MenuBarShortcut(accelerator: ""))
        XCTAssertNil(MenuBarShortcut(accelerator: "Hyper+S"))
        XCTAssertNil(MenuBarShortcut(accelerator: "CmdOrCtrl+NotAKey"))
        XCTAssertNil(MenuBarShortcut(accelerator: "Cmd+"), "a dangling separator has no key, it is not Plus")
    }

    func testAcceptsPlusOnItsOwn() {
        XCTAssertEqual(MenuBarShortcut(accelerator: "+"), MenuBarShortcut(input: "+"))
    }

    func testToleratesSpacesAndAnyCaseInModifierNames() {
        XCTAssertEqual(
            MenuBarShortcut(accelerator: " cmdorctrl + SHIFT + k "),
            MenuBarShortcut(input: "k", modifiers: [.command, .shift]))
    }

    func testResolvesEditingKeys() {
        XCTAssertEqual(MenuBarShortcut(accelerator: "Tab")?.input, "\t")
        XCTAssertEqual(MenuBarShortcut(accelerator: "Backspace")?.input, "\u{8}")
        XCTAssertEqual(MenuBarShortcut(accelerator: "Delete")?.input, UIKeyCommand.inputDelete)
        XCTAssertEqual(MenuBarShortcut(accelerator: "PageDown")?.input, UIKeyCommand.inputPageDown)
        XCTAssertEqual(MenuBarShortcut(accelerator: "F12")?.input, UIKeyCommand.f12)
    }

    func testCoversEveryAcceleratorInATypicalDesktopMenu() {
        let accelerators = [
            "CmdOrCtrl+,", "CmdOrCtrl+N", "CmdOrCtrl+O", "CmdOrCtrl+P", "CmdOrCtrl+Q",
            "CmdOrCtrl+S", "CmdOrCtrl+Alt+F", "CmdOrCtrl+Alt+V", "CmdOrCtrl+Shift+F",
            "CmdOrCtrl+Shift+M", "CmdOrCtrl+Shift+P", "CmdOrCtrl+Shift+R", "CmdOrCtrl+Shift+S",
            "CmdOrCtrl+Shift+V", "CmdOrCtrl+Shift+W"
        ]

        for accelerator in accelerators {
            XCTAssertNotNil(MenuBarShortcut(accelerator: accelerator), "failed to parse \(accelerator)")
        }
    }
}
