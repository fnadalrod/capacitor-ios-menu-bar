import UIKit
import XCTest

@testable import MenuBarPlugin

final class MenuBarElementFactoryTests: XCTestCase {
    private let factory = MenuBarElementFactory()

    private func action(_ id: String) -> MenuBarItem {
        .action(MenuBarAction(id: id, title: id.uppercased()))
    }

    private func titles(of elements: [UIMenuElement]) -> [String] {
        elements.map(\.title)
    }

    func testASingleRunStaysFlat() {
        let elements = factory.elements(of: [action("a"), action("b")])

        XCTAssertEqual(titles(of: elements), ["A", "B"])
        XCTAssertTrue(elements.allSatisfy { element in element is UICommand })
    }

    func testSeparatorsFoldRunsIntoInlineGroups() {
        let elements = factory.elements(of: [action("a"), .separator, action("b"), action("c")])
        let groups = elements.compactMap { element in element as? UIMenu }

        XCTAssertEqual(groups.count, 2)
        XCTAssertTrue(groups.allSatisfy { group in group.options.contains(.displayInline) })
        XCTAssertEqual(groups.map { group in titles(of: group.children) }, [["A"], ["B", "C"]])
    }

    func testLeadingTrailingAndDoubledSeparatorsDrawNothing() {
        let elements = factory.elements(of: [.separator, action("a"), .separator, .separator, action("b"), .separator])
        let groups = elements.compactMap { element in element as? UIMenu }

        XCTAssertEqual(groups.map { group in titles(of: group.children) }, [["A"], ["B"]])
    }

    func testOnlySeparatorsMakeAnEmptyMenu() {
        XCTAssertTrue(factory.elements(of: [.separator, .separator]).isEmpty)
    }

    func testAnActionCarriesItsIdAndTheSharedSelector() throws {
        let command = try XCTUnwrap(factory.elements(of: [action("file.new")]).first as? UICommand)

        XCTAssertEqual(command.propertyList as? String, "file.new")
        XCTAssertEqual(command.action, MenuBarElementFactory.actionSelector)
    }

    func testAnActionWithAShortcutBecomesAKeyCommand() throws {
        let shortcut = MenuBarShortcut(accelerator: "CmdOrCtrl+Shift+S")
        let item = MenuBarItem.action(MenuBarAction(id: "save-as", title: "Save As", shortcut: shortcut))

        let command = try XCTUnwrap(factory.elements(of: [item]).first as? UIKeyCommand)

        XCTAssertEqual(command.input, "s")
        XCTAssertEqual(command.modifierFlags, [.command, .shift])
        XCTAssertEqual(command.propertyList as? String, "save-as")
    }

    func testFlagsMapOntoAttributesAndState() throws {
        let item = MenuBarItem.action(MenuBarAction(id: "a", title: "A", enabled: false, checked: true, destructive: true))

        let command = try XCTUnwrap(factory.elements(of: [item]).first as? UICommand)

        XCTAssertTrue(command.attributes.contains(.disabled))
        XCTAssertTrue(command.attributes.contains(.destructive))
        XCTAssertEqual(command.state, .on)
    }

    func testAPlainActionIsEnabledUncheckedAndNotDestructive() throws {
        let command = try XCTUnwrap(factory.elements(of: [action("a")]).first as? UICommand)

        XCTAssertEqual(command.attributes, [])
        XCTAssertEqual(command.state, .off)
    }

    func testASystemImageIsUsedWhenItExistsAndIgnoredWhenNot() throws {
        let known = MenuBarItem.action(MenuBarAction(id: "a", title: "A", systemImage: "doc.badge.plus"))
        let unknown = MenuBarItem.action(MenuBarAction(id: "b", title: "B", systemImage: "not.a.real.symbol"))

        let commands = factory.elements(of: [known, unknown]).compactMap { element in element as? UICommand }

        XCTAssertNotNil(commands[0].image)
        XCTAssertNil(commands[1].image)
    }

    func testARoleDispatchesThroughTheResponderChain() throws {
        let item = MenuBarItem.role(MenuBarRoleItem(role: .copy, title: "Copy", enabled: false))

        let command = try XCTUnwrap(factory.elements(of: [item]).first as? UICommand)

        XCTAssertEqual(command.action, #selector(UIResponderStandardEditActions.copy(_:)))
        XCTAssertEqual(command.propertyList as? String, "capacitor.menubar.role.copy", "set apart from the system's own Copy")
        XCTAssertTrue(command.attributes.contains(.disabled))
    }

    func testARoleWithAShortcutBecomesAKeyCommand() throws {
        let item = MenuBarItem.role(MenuBarRoleItem(role: .paste, title: "Paste", shortcut: MenuBarShortcut(input: "v", modifiers: .command)))

        let command = try XCTUnwrap(factory.elements(of: [item]).first as? UIKeyCommand)

        XCTAssertEqual(command.input, "v")
        XCTAssertEqual(command.action, #selector(UIResponderStandardEditActions.paste(_:)))
    }

    func testEveryRoleHasASelector() {
        let selectors = MenuBarRole.allCases.map(\.selector)

        XCTAssertEqual(Set(selectors).count, MenuBarRole.allCases.count, "no two roles may share a selector")
    }

    func testNestedSubmenusKeepTheirItemsAndANamespacedIdentifier() throws {
        let nested = MenuBarSubmenu(id: "recent", title: "Open Recent", items: [action("draft")])

        let menu = try XCTUnwrap(factory.elements(of: [.submenu(nested)]).first as? UIMenu)

        XCTAssertEqual(menu.identifier.rawValue, "capacitor.menubar.recent")
        XCTAssertEqual(titles(of: menu.children), ["DRAFT"])
    }

    func testAShortcutAlreadyTakenCostsTheShortcutAndNotTheItem() throws {
        let registry = MenuBarCommandRegistry(registering: RecordingMenuBuilder().rootMenu)
        let item = MenuBarItem.action(MenuBarAction(id: "view.zen", title: "Zen", shortcut: MenuBarShortcut(accelerator: "CmdOrCtrl+Shift+Z")))

        let command = try XCTUnwrap(MenuBarElementFactory(registry: registry).elements(of: [item]).first as? UICommand)

        XCTAssertFalse(command is UIKeyCommand, "⇧⌘Z is Redo's")
        XCTAssertEqual(command.propertyList as? String, "view.zen")
    }

    func testTwoItemsOfTheSameMenuCannotShareAShortcut() {
        let items: [MenuBarItem] = [
            .action(MenuBarAction(id: "a", title: "A", shortcut: MenuBarShortcut(input: "k", modifiers: .command))),
            .action(MenuBarAction(id: "b", title: "B", shortcut: MenuBarShortcut(input: "k", modifiers: .command)))
        ]

        let elements = factory.elements(of: items)

        XCTAssertTrue(elements[0] is UIKeyCommand, "the first one keeps it")
        XCTAssertFalse(elements[1] is UIKeyCommand)
    }

    func testARepeatedIdDropsTheSecondItem() {
        let elements = factory.elements(of: [action("same"), action("same"), action("other")])

        XCTAssertEqual(elements.count, 2)
    }

    func testARoleNextToTheSystemEditMenuKeepsItsCommand() throws {
        let registry = MenuBarCommandRegistry(registering: RecordingMenuBuilder().rootMenu)
        let item = MenuBarItem.role(MenuBarRoleItem(role: .selectAll, title: "Select All", shortcut: MenuBarShortcut(input: "a", modifiers: .command)))

        let command = try XCTUnwrap(MenuBarElementFactory(registry: registry).elements(of: [item]).first as? UICommand)

        XCTAssertEqual(command.action, #selector(UIResponderStandardEditActions.selectAll(_:)))
        XCTAssertFalse(command is UIKeyCommand, "⌘A stays with the system's Select All")
    }
}
