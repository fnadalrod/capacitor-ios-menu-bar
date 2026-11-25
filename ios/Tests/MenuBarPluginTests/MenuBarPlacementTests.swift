import UIKit
import XCTest

@testable import MenuBarPlugin

final class MenuBarPlacementTests: XCTestCase {
    private let placement = MenuBarPlacement()

    private func submenu(_ id: String, replaces: String? = nil) -> MenuBarSubmenu {
        MenuBarSubmenu(id: id, title: id.capitalized, items: [], replaces: replaces)
    }

    func testReplacesASystemMenuThatIsPresent() {
        let builder = RecordingMenuBuilder()

        placement.place(MenuBarDescriptor(menus: [submenu("file", replaces: "file")]), into: builder)

        XCTAssertEqual(builder.operations, [.replace(.file, title: "File")])
        XCTAssertEqual(builder.placed.first?.identifier, .file, "the replacement keeps the system identifier")
    }

    func testAppendsInsteadOfVanishingWhenTheMenuToReplaceIsAbsent() {
        let builder = RecordingMenuBuilder(systemMenus: [.help])

        placement.place(MenuBarDescriptor(menus: [submenu("format", replaces: "format")]), into: builder)

        XCTAssertEqual(builder.operations, [.insertBefore(.help, title: "Format")])
    }

    func testAppendsBeforeHelpInTheDeclaredOrder() {
        let builder = RecordingMenuBuilder()

        placement.place(MenuBarDescriptor(menus: [submenu("tools"), submenu("plugins")]), into: builder)

        XCTAssertEqual(builder.operations, [
            .insertBefore(.help, title: "Tools"),
            .insertBefore(.help, title: "Plugins")
        ])
    }

    func testAppendsAtTheEndOfTheRootWhenThereIsNoHelpMenu() {
        let builder = RecordingMenuBuilder(systemMenus: [.file])

        placement.place(MenuBarDescriptor(menus: [submenu("tools")]), into: builder)

        XCTAssertEqual(builder.operations, [.appendToRoot(title: "Tools")])
    }

    func testAppendedMenusAreNamespacedAwayFromSystemIdentifiers() {
        let builder = RecordingMenuBuilder()

        placement.place(MenuBarDescriptor(menus: [submenu("file")]), into: builder)

        XCTAssertEqual(builder.placed.first?.identifier.rawValue, "capacitor.menubar.file")
    }

    func testRemovesSystemMenusBeforePlacingAnything() {
        let builder = RecordingMenuBuilder(systemMenus: [.file, .help])
        let descriptor = MenuBarDescriptor(menus: [submenu("file", replaces: "file")], removeSystemMenus: ["file"])

        placement.place(descriptor, into: builder)

        XCTAssertEqual(builder.operations, [
            .remove(.file),
            .insertBefore(.help, title: "File")
        ], "a removed menu cannot be replaced, so the submenu falls back to appending")
    }

    func testRemovesSystemMenusGivenAsRawIdentifiers() {
        let builder = RecordingMenuBuilder()
        let raw = "com.apple.menu.something-new"

        placement.place(MenuBarDescriptor(menus: [], removeSystemMenus: [raw]), into: builder)

        XCTAssertEqual(builder.operations, [.remove(UIMenu.Identifier(raw))])
    }

    private func zenMenu(replaces: String?) -> MenuBarDescriptor {
        let zen = MenuBarAction(id: "view.zen", title: "Zen", shortcut: MenuBarShortcut(accelerator: "CmdOrCtrl+Shift+Z"))

        return MenuBarDescriptor(menus: [MenuBarSubmenu(id: "view", title: "View", items: [.action(zen)], replaces: replaces)])
    }

    private func firstCommand(of menu: UIMenu?) throws -> UICommand {
        try XCTUnwrap(menu?.children.first as? UICommand)
    }

    func testAMenuNextToEditLosesTheShortcutRedoAlreadyHas() throws {
        let builder = RecordingMenuBuilder()

        placement.place(zenMenu(replaces: nil), into: builder)

        XCTAssertFalse(try firstCommand(of: builder.placed.first) is UIKeyCommand)
    }

    func testReplacingEditFreesItsShortcuts() throws {
        let builder = RecordingMenuBuilder()

        placement.place(zenMenu(replaces: "edit"), into: builder)

        XCTAssertTrue(try firstCommand(of: builder.placed.first) is UIKeyCommand, "the Redo it clashed with is gone")
    }

    func testRemovingEditFreesItsShortcuts() throws {
        let builder = RecordingMenuBuilder()
        var descriptor = zenMenu(replaces: nil)
        descriptor.removeSystemMenus = ["edit"]

        placement.place(descriptor, into: builder)

        XCTAssertTrue(try firstCommand(of: builder.placed.first) is UIKeyCommand)
    }

    func testALaterMenuCannotReuseAShortcutAnEarlierOneTook() throws {
        let builder = RecordingMenuBuilder(systemMenus: [.help])
        let save = MenuBarShortcut(accelerator: "CmdOrCtrl+S")
        let descriptor = MenuBarDescriptor(menus: [
            MenuBarSubmenu(id: "file", title: "File", items: [.action(MenuBarAction(id: "file.save", title: "Save", shortcut: save))]),
            MenuBarSubmenu(id: "tools", title: "Tools", items: [.action(MenuBarAction(id: "tools.stats", title: "Stats", shortcut: save))])
        ])

        placement.place(descriptor, into: builder)

        XCTAssertTrue(try firstCommand(of: builder.placed[0]) is UIKeyCommand)
        XCTAssertFalse(try firstCommand(of: builder.placed[1]) is UIKeyCommand)
    }
}
