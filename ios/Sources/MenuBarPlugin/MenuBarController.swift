import UIKit

/// Holds the current menu and answers UIKit when it builds the application menu.
///
/// Plain UIKit with no Capacitor dependency, so native apps can use it too.
///
/// UIKit has no live menu to change: it builds the main menu once and rebuilds it on request.
/// Each change stores the descriptor, requests a rebuild and answers `build(with:)` when UIKit
/// calls back. Items are snapshots, so checkmarks and enabled flags only change with a new
/// `setMenu`.
///
/// Rendering lives in `MenuBarElementFactory` and placement in `MenuBarPlacement`.
public final class MenuBarController {
    public static let shared = MenuBarController()

    /// Called on the main thread with the `id` of the chosen action item.
    public var onSelect: ((String) -> Void)?

    private var descriptor: MenuBarDescriptor?
    private let placement = MenuBarPlacement()
    private let requestRebuild: () -> Void

    /// `requestRebuild` is injectable so tests can observe it without a running menu system.
    init(requestRebuild: @escaping () -> Void = MenuBarController.requestSystemRebuild) {
        self.requestRebuild = requestRebuild
    }

    /// Whether this device surfaces an application menu at all.
    ///
    /// True on iPad and Mac Catalyst. Before iPadOS 26 there is no bar on screen, only the
    /// ⌘-held overlay. Keep an in-app menu either way.
    public static var isSupported: Bool {
        #if targetEnvironment(macCatalyst)
        return true
        #else
        return UIDevice.current.userInterfaceIdiom == .pad
        #endif
    }

    public func setMenu(_ descriptor: MenuBarDescriptor) {
        self.descriptor = descriptor
        requestRebuild()
    }

    public func clearMenu() {
        descriptor = nil
        requestRebuild()
    }

    /// Contributes the current descriptor to a menu build.
    ///
    /// Call this from `AppDelegate.buildMenu(with:)` after `super`, or let `MenuBarInstaller`
    /// arrange the call for you.
    public func build(with builder: UIMenuBuilder) {
        build(into: UIMenuBuilderAdapter(builder: builder))
    }

    func build(into builder: MenuBarBuilding) {
        MenuBarLog.debug("buildMenu reached us (main menu: \(builder.buildsMainMenu)).")

        guard builder.buildsMainMenu, let descriptor else {
            return
        }

        placement.place(descriptor, into: builder)
        MenuBarLog.info("Contributed \(descriptor.menus.count) menu(s) to the main menu.")
    }

    func handle(_ command: UICommand) {
        guard let id = command.propertyList as? String else {
            return
        }

        onSelect?(id)
    }

    static func requestSystemRebuild() {
        DispatchQueue.main.async {
            UIMenuSystem.main.setNeedsRebuild()
        }
    }
}
