import Foundation

extension KeyedDecodingContainer {
    /// Decodes an array, dropping the elements that fail instead of failing the array.
    ///
    /// A malformed item should not take the rest of the menu with it.
    func decodeTolerantArray<Element: Decodable>(_ type: Element.Type, forKey key: Key) throws -> [Element] {
        let wrapped = try decodeIfPresent([Tolerant<Element>].self, forKey: key) ?? []

        return wrapped.compactMap(\.value)
    }

    /// Decodes an accelerator string into a shortcut, or nil when absent or unparseable.
    func decodeShortcut(forKey key: Key) throws -> MenuBarShortcut? {
        try decodeIfPresent(String.self, forKey: key).flatMap(MenuBarShortcut.init(accelerator:))
    }
}

/// Decodes a value, or nothing at all.
///
/// Wrapping each element gives it its own decoder, so swallowing a failure here does not leave
/// the surrounding array's cursor stranded mid-element.
private struct Tolerant<Wrapped: Decodable>: Decodable {
    let value: Wrapped?

    init(from decoder: Decoder) throws {
        value = try? Wrapped(from: decoder)
    }
}
