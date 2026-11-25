import XCTest

@testable import MenuBarPlugin

final class MenuBarDescriptorTests: XCTestCase {
    private func decode(_ json: String) throws -> MenuBarDescriptor {
        try JSONDecoder().decode(MenuBarDescriptor.self, from: Data(json.utf8))
    }

    func testDecodesTheFullShapeOfAMenu() throws {
        let descriptor = try decode(#"""
        {
          "menus": [
            {
              "type": "submenu",
              "id": "file",
              "title": "File",
              "replaces": "file",
              "items": [
                {"type": "action", "id": "file.new", "title": "New", "shortcut": "CmdOrCtrl+N"},
                {"type": "separator"},
                {"type": "role", "role": "copy", "title": "Copy"},
                {
                  "type": "submenu",
                  "id": "file.recent",
                  "title": "Open Recent",
                  "items": [{"type": "action", "id": "file.recent.1", "title": "Draft"}]
                }
              ]
            }
          ],
          "removeSystemMenus": ["format"]
        }
        """#)

        XCTAssertEqual(descriptor.removeSystemMenus, ["format"])
        XCTAssertEqual(descriptor.menus.count, 1)
        XCTAssertEqual(descriptor.menus[0].replaces, "file")
        XCTAssertEqual(descriptor.menus[0].items.count, 4)

        guard case .action(let action) = descriptor.menus[0].items[0] else {
            return XCTFail("expected the first item to be an action")
        }

        XCTAssertEqual(action.id, "file.new")
        XCTAssertEqual(action.shortcut?.input, "n")
    }

    func testDefaultsMatchWhatAPlainItemShouldLookLike() throws {
        let descriptor = try decode(#"""
        {"menus": [{"type": "submenu", "id": "f", "title": "F",
          "items": [{"type": "action", "id": "a", "title": "A"}]}]}
        """#)

        guard case .action(let action) = descriptor.menus[0].items[0] else {
            return XCTFail("expected an action")
        }

        XCTAssertTrue(action.enabled)
        XCTAssertFalse(action.checked)
        XCTAssertFalse(action.destructive)
        XCTAssertNil(action.shortcut)
        XCTAssertEqual(descriptor.removeSystemMenus, [])
    }

    func testAnUnparseableShortcutCostsTheShortcutAndNotTheItem() throws {
        let descriptor = try decode(#"""
        {"menus": [{"type": "submenu", "id": "f", "title": "F",
          "items": [{"type": "action", "id": "a", "title": "A", "shortcut": "Hyper+Nope"}]}]}
        """#)

        guard case .action(let action) = descriptor.menus[0].items[0] else {
            return XCTFail("the item should still be there")
        }

        XCTAssertNil(action.shortcut)
    }

    func testOneBadItemDoesNotCostTheWholeMenu() throws {
        let descriptor = try decode(#"""
        {"menus": [{"type": "submenu", "id": "f", "title": "F", "items": [
          {"type": "action", "id": "a", "title": "A"},
          {"type": "somethingFromTheFuture"},
          {"type": "action", "title": "no id at all"},
          {"type": "role", "role": "notARole", "title": "R"},
          {"type": "action", "id": "b", "title": "B"}
        ]}]}
        """#)

        let ids: [String] = descriptor.menus[0].items.compactMap { item in
            guard case .action(let action) = item else {
                return nil
            }

            return action.id
        }

        XCTAssertEqual(ids, ["a", "b"], "the three broken items should be dropped, not the menu")
    }

    func testABrokenTopLevelMenuDropsOnlyItself() throws {
        let descriptor = try decode(#"""
        {"menus": [
          {"type": "submenu", "id": "a", "title": "A", "items": []},
          {"type": "submenu", "title": "no id"},
          {"type": "submenu", "id": "c", "title": "C", "items": []}
        ]}
        """#)

        XCTAssertEqual(descriptor.menus.map(\.id), ["a", "c"])
    }

    func testAMissingItemsArrayIsAnEmptyMenuRatherThanAFailure() throws {
        let descriptor = try decode(#"""
        {"menus": [{"type": "submenu", "id": "a", "title": "A"}]}
        """#)

        XCTAssertEqual(descriptor.menus[0].items.count, 0)
    }

    func testDecodesTheBridgePayload() throws {
        let descriptor = try MenuBarDescriptor(payload: [
            "menus": [["type": "submenu", "id": "view", "title": "View", "items": [
                ["type": "action", "id": "view.zen", "title": "Zen", "checked": true]
            ]]],
            "removeSystemMenus": ["format"]
        ])

        XCTAssertEqual(descriptor.menus.map(\.id), ["view"])
        XCTAssertEqual(descriptor.removeSystemMenus, ["format"])
    }

    func testRejectsAPayloadWithNoJSONFormInsteadOfCrashing() {
        XCTAssertThrowsError(try MenuBarDescriptor(payload: ["menus": [Date()]])) { error in
            XCTAssertEqual(error as? MenuBarDescriptorError, .payloadIsNotJSON)
        }
    }

    func testAnUnknownRoleIsDroppedButAKnownOneDecodes() throws {
        let descriptor = try decode(#"""
        {"menus": [{"type": "submenu", "id": "e", "title": "E", "items": [
          {"type": "role", "role": "selectAll", "title": "Select All", "shortcut": "CmdOrCtrl+A", "enabled": false}
        ]}]}
        """#)

        guard case .role(let item) = descriptor.menus[0].items[0] else {
            return XCTFail("expected a role")
        }

        XCTAssertEqual(item.role, .selectAll)
        XCTAssertEqual(item.shortcut, MenuBarShortcut(input: "a", modifiers: .command))
        XCTAssertFalse(item.enabled)
    }

    func testAMenuCanBeBuiltInSwiftWithoutJSON() {
        let descriptor = MenuBarDescriptor(menus: [
            MenuBarSubmenu(id: "file", title: "File", items: [
                .action(MenuBarAction(id: "file.new", title: "New", shortcut: MenuBarShortcut(accelerator: "CmdOrCtrl+N"))),
                .separator,
                .role(MenuBarRoleItem(role: .copy, title: "Copy"))
            ], replaces: "file")
        ])

        XCTAssertEqual(descriptor.menus[0].items.count, 3)
        XCTAssertEqual(descriptor.removeSystemMenus, [])
    }
}
