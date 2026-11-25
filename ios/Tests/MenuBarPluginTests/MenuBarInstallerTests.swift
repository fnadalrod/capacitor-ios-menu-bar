import UIKit
import XCTest

@testable import MenuBarPlugin

/// Stands in for whatever UIResponder subclass the app delegate inherits from.
class RecordingResponder: UIResponder {
    static var calls: [String] = []

    override func buildMenu(with builder: UIMenuBuilder) {
        Self.calls.append("inherited")
    }
}

/// A delegate that only inherits `buildMenu(with:)`: the common Capacitor case.
final class InheritingDelegate: RecordingResponder {}

/// A delegate that already builds its own menu.
final class CustomizingDelegate: RecordingResponder {
    override func buildMenu(with builder: UIMenuBuilder) {
        Self.calls.append("own")
    }
}

/// A second inheriting delegate, so the idempotence test does not depend on test order.
final class ReinstalledDelegate: RecordingResponder {}

final class MenuBarInstallerTests: XCTestCase {
    /// `buildMenu(with:)` is sent through the Objective-C runtime, as UIKit sends it. The
    /// builder is a plain object, since the installed code only passes it along, and it is
    /// shared because an install outlives the test instance that made it.
    private static let builder = NSObject()

    override func setUp() {
        super.setUp()
        RecordingResponder.calls = []
    }

    private func contribution() -> (UIMenuBuilder) -> Void {
        { received in
            XCTAssertTrue((received as AnyObject) === Self.builder, "the contribution receives the builder UIKit passed")
            RecordingResponder.calls.append("contributed")
        }
    }

    private func sendBuildMenu(to delegate: UIResponder) {
        _ = delegate.perform(#selector(UIResponder.buildMenu(with:)), with: Self.builder)
    }

    func testAddsAnOverrideThatCallsTheInheritedImplementationFirst() {
        XCTAssertTrue(MenuBarInstaller.install(on: InheritingDelegate.self, contribute: contribution()))

        sendBuildMenu(to: InheritingDelegate())

        XCTAssertEqual(RecordingResponder.calls, ["inherited", "contributed"])
    }

    func testWrapsAnExistingImplementationInsteadOfReplacingIt() {
        XCTAssertTrue(MenuBarInstaller.install(on: CustomizingDelegate.self, contribute: contribution()))

        sendBuildMenu(to: CustomizingDelegate())

        XCTAssertEqual(RecordingResponder.calls, ["own", "contributed"])
    }

    func testInstallingTwiceContributesOnce() {
        XCTAssertTrue(MenuBarInstaller.install(on: ReinstalledDelegate.self, contribute: contribution()))
        XCTAssertTrue(MenuBarInstaller.install(on: ReinstalledDelegate.self, contribute: contribution()))

        sendBuildMenu(to: ReinstalledDelegate())

        XCTAssertEqual(RecordingResponder.calls, ["inherited", "contributed"])
    }

    func testLeavesTheSuperclassUntouched() {
        XCTAssertTrue(MenuBarInstaller.install(on: InheritingDelegate.self, contribute: contribution()))

        sendBuildMenu(to: RecordingResponder())

        XCTAssertEqual(RecordingResponder.calls, ["inherited"])
    }
}
