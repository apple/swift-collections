//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Collections open source project
//
// Copyright (c) 2024 - 2026 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
//
//===----------------------------------------------------------------------===//

#if !COLLECTIONS_SINGLE_MODULE
import InternalCollectionsUtilities
import ContainersPreview
#endif

#if compiler(>=6.2)

#if COLLECTIONS_UNSTABLE_CONTAINERS_PREVIEW
@available(SwiftStdlib 5.0, *)
extension UniqueArray where Element: ~Copyable {
  /// Remove the specified subrange of items from this array,
  /// passing an input span to the given function to consume them in place.
  ///
  /// - Parameter subrange: The subrange of items to consume from this array.
  /// - Parameter consumer: A function taking an input span of the removed items,
  ///    allowing them to be consumed straight out of the array's storage.
  ///    The function is not required to consume all items in the span;
  ///    however, the span's remaining items will still be removed from
  ///    the array.
  ///
  /// - Complexity: O(`self.count`)
  @_alwaysEmitIntoClient
  public mutating func consume(
    _ subrange: Range<Int>,
    consumingWith consumer: (inout InputSpan<Element>) -> Void
  ) {
    _storage.consume(subrange, consumingWith: consumer)
  }

  /// Remove the specified subrange of items from this deque,
  /// passing a series of input spans to a given callback function to consume
  /// them in place.
  ///
  /// The callback is not required to fully consume the contents of its
  /// argument; any items it leaves in the input span get automatically
  /// consumed. The underlying storage isn't necessarily contiguous, so
  /// the callback may be called more than once, whether or not it fully
  /// consumes its input. If the specified range is empty, the callback
  /// may not be called at all.
  ///
  /// - Parameter subrange: The subrange of items to consume from this array.
  /// - Parameter consumer: A function taking an input span of the removed items,
  ///    allowing them to be consumed straight out of the array's storage.
  ///    The function is called at most once.
 ///
  /// - Complexity: O(`self.count`)
  @_alwaysEmitIntoClient
  @inline(__always)
  public mutating func consume<R: RangeExpression<Index>>(
    _ subrange: R,
    consumingWith consumer: (inout InputSpan<Element>) -> Void
  ) {
    _storage.consume(subrange.relative(to: indices), consumingWith: consumer)
  }

  /// Remove all items currently in this array, passing an input
  /// span to a given callback function to consume them in place.
  ///
  /// The callback is not required to fully consume the contents of its
  /// argument; any items it leaves in the input span get automatically
  /// consumed.
  ///
  /// - Parameter consumer: A function taking an input span of the removed items,
  ///    allowing them to be consumed straight out of the array's storage.
  ///    The function is called at most once.
  ///
  /// - Complexity: O(`self.count`)
  @_alwaysEmitIntoClient
  public mutating func consumeAll(
    consumingWith consumer: (inout InputSpan<Element>) -> Void
  ) {
    _storage.consume(indices, consumingWith: consumer)
  }

  /// Remove the specified number of items from the end of this array,
  /// passing an input span to a given callback function to consume them in
  /// place.
  ///
  /// The callback is not required to fully consume the contents of its
  /// argument; any items it leaves in the input span get automatically
  /// consumed.
  ///
  /// - Parameter n: The number of items to consume from the end of the array.
  ///   `n` must be greater than or equal to zero and must not exceed
  ///   the count of the array.
  /// - Parameter consumer: A function taking an input span of the removed items,
  ///    allowing them to be consumed straight out of the array's storage.
  ///    The function is called at most once.
  /// - Complexity: O(`n`)
  @inline(__always)
  @_alwaysEmitIntoClient
  public mutating func consumeLast(
    _ n: Int,
    consumingWith consumer: (inout InputSpan<Element>) -> Void
  ) {
    _storage.consumeLast(n, consumingWith: consumer)
  }
}
#endif

#endif
