import UIKit
import XCTest

@testable import MenuBarPlugin

final class MenuBarCommandRegistryTests: XCTestCase {
    private let redo = MenuBarShortcut(input: "z", modifiers: [.command, .shift])
    private let selectAll = #selector(UIResponderStandardEditActions.selectAll(_:))

    func testAFreeShortcutIsGrantedOnceAndThenRefused() {
        let registry = MenuBarCommandRegistry()

        XCTAssertEqual(registry.claimShortcut(redo, title: "Zen"), redo)
        XCTAssertNil(registry.claimShortcut(redo, title: "Focus"))
    }

    func testShortcutsAlreadyInTheBuildAreTaken() {
        let registry = MenuBarCommandRegistry(registering: RecordingMenuBuilder().rootMenu)

        XCTAssertNil(registry.claimShortcut(redo, title: "Zen"))
        XCTAssertNil(registry.claimShortcut(MenuBarShortcut(input: "A", modifiers: .command), title: "All"), "inputs compare without case")
    }

    func testTheMenuBeingReplacedDoesNotCount() {
        let registry = MenuBarCommandRegistry(registering: RecordingMenuBuilder().rootMenu, excluding: .edit)

        XCTAssertEqual(registry.claimShortcut(redo, title: "Zen"), redo)
    }

    func testOnlyTheExactCombinationIsTaken() {
        let registry = MenuBarCommandRegistry(registering: RecordingMenuBuilder().rootMenu)
        let optionZ = MenuBarShortcut(input: "z", modifiers: [.command, .alternate])

        XCTAssertEqual(registry.claimShortcut(optionZ, title: "Zen"), optionZ)
    }

    func testAnAbsentShortcutClaimsNothing() {
        XCTAssertNil(MenuBarCommandRegistry().claimShortcut(nil, title: "Plain"))
    }

    func testACommandIsTakenByItsActionAndPropertyList() {
        let registry = MenuBarCommandRegistry()

        XCTAssertTrue(registry.claimCommand(action: selectAll, propertyList: "mine", title: "Select All"))
        XCTAssertFalse(registry.claimCommand(action: selectAll, propertyList: "mine", title: "Select All again"))
        XCTAssertTrue(registry.claimCommand(action: selectAll, propertyList: "other", title: "Select Every"))
    }
}
