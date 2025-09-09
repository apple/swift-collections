/// Describes a type that has some number of elements following it directly
/// in memory. Such types are generally used with the `TrailingArray`
/// type, which manages storage for the header and its trailing elements.
public protocol TrailingElements: ~Copyable {
    /// The element type of the data that follows the header in memory.
    associatedtype Element

    /// The number of elements following the header.
    var trailingCount: Int { get }
}
