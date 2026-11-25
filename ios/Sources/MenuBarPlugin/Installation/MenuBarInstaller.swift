import ObjectiveC.runtime
import UIKit

/// Puts `MenuBarController` on the path UIKit walks when it builds the main menu.
///
/// UIKit builds the menu bar by calling `buildMenu(with:)` on the app delegate. It is a
/// `UIResponder` method and a Capacitor plugin is not in the responder chain, so the override
/// has to be added to the delegate's class. There are two ways to do it:
///
/// 1. **Automatic** (default). `install()` adds the override at runtime and requests a rebuild.
///    Nothing changes inside `ios/`, which most Capacitor projects regenerate.
/// 2. **Manual.** Set `autoInstall: false` under `MenuBar` in the Capacitor config and call
///    `MenuBarController.shared.build(with: builder)` from `AppDelegate.buildMenu(with:)`,
///    after `super`.
public enum MenuBarInstaller {
    private static var installedClasses = Set<ObjectIdentifier>()
    private static let buildMenu = #selector(UIResponder.buildMenu(with:))
    private static let originalBuildMenu = NSSelectorFromString("capacitorMenuBar_originalBuildMenuWithBuilder:")
    private static let methodSignature = "v@:@"

    private typealias Contribution = (UIMenuBuilder) -> Void
    private typealias BuildMenuBlock = @convention(block) (AnyObject, UIMenuBuilder) -> Void
    private typealias BuildMenuImplementation = @convention(c) (AnyObject, Selector, UIMenuBuilder) -> Void

    /// Installs on the app delegate's class and asks UIKit to rebuild, because UIKit has already
    /// built the menu by the time a plugin loads. Idempotent.
    ///
    /// - Returns: whether the override is in place.
    @discardableResult
    public static func install() -> Bool {
        guard let delegate = UIApplication.shared.delegate, let delegateClass = object_getClass(delegate) else {
            MenuBarLog.error("No app delegate to install on; the menu will not appear.")

            return false
        }

        guard install(on: delegateClass, contribute: MenuBarController.shared.build(with:)) else {
            return false
        }

        MenuBarController.requestSystemRebuild()

        return true
    }

    /// Makes `buildMenu(with:)` on `delegateClass` run `contribute` after whatever it already
    /// did. Idempotent per class.
    static func install(on delegateClass: AnyClass, contribute: @escaping (UIMenuBuilder) -> Void) -> Bool {
        let key = ObjectIdentifier(delegateClass)

        guard !installedClasses.contains(key) else {
            return true
        }

        guard addOverride(to: delegateClass, contribute: contribute)
                || wrapExisting(on: delegateClass, contribute: contribute) else {
            return false
        }

        installedClasses.insert(key)

        return true
    }

    /// Adds `buildMenu(with:)` to a class that only inherits it, calling up to the superclass first.
    ///
    /// `class_addMethod` refuses when the class declares the method itself; that is the case
    /// `wrapExisting` handles.
    private static func addOverride(to delegateClass: AnyClass, contribute: @escaping Contribution) -> Bool {
        guard let superclass = class_getSuperclass(delegateClass) else {
            return false
        }

        let block: BuildMenuBlock = { receiver, builder in
            callInherited(from: superclass, on: receiver, with: builder)
            contribute(builder)
        }

        guard class_addMethod(delegateClass, buildMenu, imp_implementationWithBlock(block), methodSignature) else {
            return false
        }

        MenuBarLog.info("Installed: added buildMenu(with:) to \(delegateClass).")

        return true
    }

    /// Wraps a `buildMenu(with:)` the host already wrote, instead of replacing it.
    ///
    /// Replacing it would discard the app's own menu changes. The original implementation is
    /// moved to a private selector and called first.
    private static func wrapExisting(on delegateClass: AnyClass, contribute: @escaping Contribution) -> Bool {
        let block: BuildMenuBlock = { receiver, builder in
            _ = (receiver as? NSObject)?.perform(originalBuildMenu, with: builder)
            contribute(builder)
        }

        guard class_addMethod(delegateClass, originalBuildMenu, imp_implementationWithBlock(block), methodSignature),
              let existing = class_getInstanceMethod(delegateClass, buildMenu),
              let wrapper = class_getInstanceMethod(delegateClass, originalBuildMenu) else {
            MenuBarLog.error("Could not wrap the existing buildMenu(with:) on \(delegateClass).")

            return false
        }

        method_exchangeImplementations(existing, wrapper)
        MenuBarLog.info("Installed: wrapped the existing buildMenu(with:) on \(delegateClass).")

        return true
    }

    private static func callInherited(from superclass: AnyClass, on receiver: AnyObject, with builder: UIMenuBuilder) {
        guard let inherited = class_getMethodImplementation(superclass, buildMenu) else {
            return
        }

        unsafeBitCast(inherited, to: BuildMenuImplementation.self)(receiver, buildMenu, builder)
    }
}
