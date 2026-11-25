import UIKit
import XCTest

@testable import MenuBarPlugin

final class MenuBarControllerTests: XCTestCase {
    private var rebuildRequests = 0
    private lazy var controller = MenuBarController { [unowned self] in self.rebuildRequests += 1 }

    private let fileMenu = MenuBarDescriptor(menus: [
        MenuBarSubmenu(id: "file", title: "File", items: [.action(MenuBarAction(id: "file.new", title: "New"))])
    ])

    func testSettingAndClearingTheMenuEachAskForARebuild() {
        controller.setMenu(fileMenu)
        controller.clearMenu()

        XCTAssertEqual(rebuildRequests, 2)
    }

    func testContributesNothingBeforeAMenuIsSet() {
        let builder = RecordingMenuBuilder()

        controller.build(into: builder)

        XCTAssertEqual(builder.operations, [])
    }

    func testContributesTheMenuOnceSet() {
        let builder = RecordingMenuBuilder()

        controller.setMenu(fileMenu)
        controller.build(into: builder)

        XCTAssertEqual(builder.operations, [.insertBefore(.help, title: "File")])
    }

    func testContributesNothingAfterTheMenuIsCleared() {
        let builder = RecordingMenuBuilder()

        controller.setMenu(fileMenu)
        controller.clearMenu()
        controller.build(into: builder)

        XCTAssertEqual(builder.operations, [])
    }

    func testLeavesContextMenusAlone() {
        let builder = RecordingMenuBuilder(buildsMainMenu: false)

        controller.setMenu(fileMenu)
        controller.build(into: builder)

        XCTAssertEqual(builder.operations, [], "only the application menu is ours to change")
    }

    func testReportsTheIdOfTheChosenItem() {
        var selected: [String] = []
        controller.onSelect = { id in selected.append(id) }
        let command = UICommand(title: "New", action: MenuBarElementFactory.actionSelector, propertyList: "file.new")

        controller.handle(command)

        XCTAssertEqual(selected, ["file.new"])
    }

    func testIgnoresACommandThatCarriesNoId() {
        var selected: [String] = []
        controller.onSelect = { id in selected.append(id) }

        controller.handle(UICommand(title: "Copy", action: #selector(UIResponderStandardEditActions.copy(_:))))

        XCTAssertEqual(selected, [])
    }
}
