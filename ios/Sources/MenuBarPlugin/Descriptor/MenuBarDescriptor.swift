import Foundation

/// The menu as data, decoded straight from the bridge payload.
///
/// Has no Capacitor dependency: a UIKit app can build one in Swift and pass it to
/// `MenuBarController`.
public struct MenuBarDescriptor: Decodable {
    public var menus: [MenuBarSubmenu]
    /// Names of system menus to drop entirely, e.g. `["format"]`.
    public var removeSystemMenus: [String]

    private enum CodingKeys: String, CodingKey {
        case menus
        case removeSystemMenus
    }

    public init(menus: [MenuBarSubmenu], removeSystemMenus: [String] = []) {
        self.menus = menus
        self.removeSystemMenus = removeSystemMenus
    }

    /// Decodes a payload shaped like the JavaScript `SetMenuOptions`.
    ///
    /// The validity check comes first because `JSONSerialization` raises an Objective-C
    /// exception, not a Swift error, on a value it cannot serialise: without it a stray object
    /// in the payload would crash the app instead of rejecting the call.
    public init(payload: [String: Any]) throws {
        guard JSONSerialization.isValidJSONObject(payload) else {
            throw MenuBarDescriptorError.payloadIsNotJSON
        }

        let data = try JSONSerialization.data(withJSONObject: payload)

        self = try JSONDecoder().decode(MenuBarDescriptor.self, from: data)
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        menus = try container.decodeTolerantArray(MenuBarSubmenu.self, forKey: .menus)
        removeSystemMenus = try container.decodeIfPresent([String].self, forKey: .removeSystemMenus) ?? []
    }
}

public enum MenuBarDescriptorError: Error, Equatable {
    /// The payload holds a value that has no JSON form, so it cannot be a menu.
    case payloadIsNotJSON
}
