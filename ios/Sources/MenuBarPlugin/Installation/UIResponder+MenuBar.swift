import UIKit

extension UIResponder {
    /// The single target every custom menu item points at.
    ///
    /// Defined on `UIResponder` because UIKit only enables a menu item when something in the
    /// responder chain implements its selector. Declaring it here makes it available whatever
    /// has focus, so only the item's `enabled` flag decides.
    ///
    /// Prefixed because it adds an Objective-C method to a UIKit class, and selector names are
    /// global.
    @objc func capacitorMenuBarItemSelected(_ sender: Any?) {
        guard let command = sender as? UICommand else {
            return
        }

        MenuBarController.shared.handle(command)
    }
}
