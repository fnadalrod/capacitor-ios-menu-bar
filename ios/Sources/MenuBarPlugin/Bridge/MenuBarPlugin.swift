import Capacitor
import Foundation
import UIKit

/// Capacitor bridge over `MenuBarController`.
///
/// Everything here is transport: read the payload, hand it to the controller, and forward
/// selections back to JavaScript. The menu logic lives outside so it stays usable without
/// Capacitor.
@objc(MenuBarPlugin)
public class MenuBarPlugin: CAPPlugin, CAPBridgedPlugin {
    public let identifier = "MenuBarPlugin"
    public let jsName = "MenuBar"
    public let pluginMethods: [CAPPluginMethod] = [
        CAPPluginMethod(name: "isSupported", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "setMenu", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "clearMenu", returnType: CAPPluginReturnPromise)
    ]

    override public func load() {
        MenuBarController.shared.onSelect = { [weak self] id in
            self?.notifyListeners("menuItemSelected", data: ["id": id])
        }

        guard getConfig().getBoolean("autoInstall", true) else {
            return
        }

        DispatchQueue.main.async {
            MenuBarInstaller.install()
        }
    }

    @objc func isSupported(_ call: CAPPluginCall) {
        DispatchQueue.main.async {
            call.resolve(["supported": MenuBarController.isSupported])
        }
    }

    /// Reads the two known keys rather than handing over `call.options` wholesale: the options
    /// also carry the bridge's own bookkeeping, which is not JSON-serialisable.
    @objc func setMenu(_ call: CAPPluginCall) {
        let payload: [String: Any] = [
            "menus": call.getArray("menus") ?? [],
            "removeSystemMenus": call.getArray("removeSystemMenus") ?? []
        ]

        do {
            let descriptor = try MenuBarDescriptor(payload: payload)

            MenuBarLog.info("Received \(descriptor.menus.count) menu(s) from JavaScript.")
            DispatchQueue.main.async {
                MenuBarController.shared.setMenu(descriptor)
                call.resolve()
            }
        } catch {
            call.reject("Could not read the menu descriptor: \(error.localizedDescription)", nil, error)
        }
    }

    @objc func clearMenu(_ call: CAPPluginCall) {
        DispatchQueue.main.async {
            MenuBarController.shared.clearMenu()
            call.resolve()
        }
    }
}
