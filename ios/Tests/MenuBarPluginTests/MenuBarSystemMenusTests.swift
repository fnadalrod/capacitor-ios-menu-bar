import UIKit
import XCTest

@testable import MenuBarPlugin

final class MenuBarSystemMenusTests: XCTestCase {
    func testResolvesFriendlyNamesToUIKitIdentifiers() {
        XCTAssertEqual(MenuBarSystemMenus.identifier(named: "file"), .file)
        XCTAssertEqual(MenuBarSystemMenus.identifier(named: "openRecent"), .openRecent)
        XCTAssertEqual(MenuBarSystemMenus.identifier(named: "bringAllToFront"), .bringAllToFront)
    }

    func testPassesAnUnknownNameThroughAsARawIdentifier() {
        let raw = "com.apple.menu.something-new"

        XCTAssertEqual(MenuBarSystemMenus.identifier(named: raw).rawValue, raw)
    }

    func testNoTwoNamesPointAtTheSameMenu() {
        let identifiers = Array(MenuBarSystemMenus.identifiers.values)

        XCTAssertEqual(Set(identifiers).count, identifiers.count)
    }
}
