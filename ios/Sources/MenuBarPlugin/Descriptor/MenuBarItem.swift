import Foundation

/// One entry of a menu, discriminated by the `type` field of the JavaScript object.
public enum MenuBarItem {
    case action(MenuBarAction)
    case role(MenuBarRoleItem)
    case separator
    case submenu(MenuBarSubmenu)

    var isSeparator: Bool {
        guard case .separator = self else {
            return false
        }

        return true
    }
}

extension MenuBarItem: Decodable {
    private enum CodingKeys: String, CodingKey {
        case type
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(String.self, forKey: .type)

        switch type {
        case "action":
            self = .action(try MenuBarAction(from: decoder))
        case "role":
            self = .role(try MenuBarRoleItem(from: decoder))
        case "separator":
            self = .separator
        case "submenu":
            self = .submenu(try MenuBarSubmenu(from: decoder))
        default:
            throw DecodingError.dataCorruptedError(
                forKey: .type,
                in: container,
                debugDescription: "Unknown menu item type \"\(type)\"")
        }
    }
}
