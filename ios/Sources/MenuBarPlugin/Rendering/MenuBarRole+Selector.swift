import UIKit

extension MenuBarRole {
    /// The responder-chain selector UIKit dispatches this role through.
    ///
    /// Undo and redo are addressed by name because they are not part of
    /// `UIResponderStandardEditActions`; keeping UIKit's own `undoRedo` system menu is the more
    /// reliable route when you only need the standard pair.
    var selector: Selector {
        switch self {
        case .undo:
            return NSSelectorFromString("undo:")
        case .redo:
            return NSSelectorFromString("redo:")
        case .cut:
            return #selector(UIResponderStandardEditActions.cut(_:))
        case .copy:
            return #selector(UIResponderStandardEditActions.copy(_:))
        case .paste:
            return #selector(UIResponderStandardEditActions.paste(_:))
        case .delete:
            return #selector(UIResponderStandardEditActions.delete(_:))
        case .select:
            return #selector(UIResponderStandardEditActions.select(_:))
        case .selectAll:
            return #selector(UIResponderStandardEditActions.selectAll(_:))
        }
    }
}
