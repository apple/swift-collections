//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Collections open source project
//
// Copyright (c) 2026 Apple Inc. and the Swift project authors
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

@available(SwiftStdlib 5.0, *)
extension UniqueDeque where Element: ~Copyable {
#if COLLECTIONS_UNSTABLE_CONTAINERS_PREVIEW
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
  /// - Parameter subrange: The subrange of items to consume from this deque.
  /// - Parameter consumer: A function taking an input span of the removed items,
  ///    allowing them to be consumed straight out of the deque's storage.
  ///    The function is called at most once.
  ///
  /// - Complexity: O(`self.count`)
  @_alwaysEmitIntoClient
  @inline(__always)
  public mutating func consume(
    _ subrange: Range<Index>,
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
  /// - Parameter subrange: The subrange of items to consume from this deque.
  /// - Parameter consumer: A function taking an input span of the removed items,
  ///    allowing them to be consumed straight out of the deque's storage.
  ///    The function is called at most once.
  ///
  /// - Complexity: O(`self.count`)
  @_alwaysEmitIntoClient
  @inline(__always)
  public mutating func consume<R: RangeExpression<Index>>(
    _ subrange: R,
    consumingWith consumer: (inout InputSpan<Element>) -> Void
  ) {
    consume(subrange.relative(to: indices), consumingWith: consumer)
  }
  
  /// Remove all items currently in this deque, passing a series of input
  /// spans to a given callback function to consume them in place.
  ///
  /// The callback is not required to fully consume the contents of its
  /// argument; any items it leaves in the input span get automatically
  /// consumed. The underlying storage isn't necessarily contiguous, so
  /// the callback may be called more than once, whether or not it fully
  /// consumes its input. If the specified range is empty, the callback
  /// may not be called at all.
  ///
  /// - Parameter consumer: A function taking an input span of the removed items,
  ///    allowing them to be consumed straight out of the deque's storage.
  ///    The function is called at most once.
  /// - Complexity: O(`self.count`)
  @_alwaysEmitIntoClient
  @inline(__always)
  public mutating func consumeAll(
    consumingWith consumer: (inout InputSpan<Element>) -> Void
  ) {
    consume(indices, consumingWith: consumer)
  }
  
  /// Remove the specified number of items from the end of this deque,
  /// passing an input span to a given callback function to consume them in
  /// place.
  ///
  /// The callback is not required to fully consume the contents of its
  /// argument; any items it leaves in the input span get automatically
  /// consumed. The underlying storage isn't necessarily contiguous, so
  /// the callback may be called more than once, whether or not it fully
  /// consumes its input. If the specified range is empty, the callback
  /// may not be called at all.
  ///
  /// - Parameter n: The number of items to consume from the end of the deque.
  ///   `n` must be greater than or equal to zero and must not exceed
  ///   the count of the deque.
  /// - Parameter consumer: A function taking an input span of the removed items,
  ///    allowing them to be consumed straight out of the deque's storage.
  /// - Complexity: O(`n`)
  @_alwaysEmitIntoClient
  @inline(__always)
  public mutating func consumeLast(
    _ n: Int,
    consumingWith consumer: (inout InputSpan<Element>) -> Void
  ) {
    _storage.consumeLast(n, consumingWith: consumer)
  }

  /// Remove the specified number of items from the front of this deque,
  /// passing an input span to a given callback function to consume them in
  /// place.
  ///
  /// The callback is not required to fully consume the contents of its
  /// argument; any items it leaves in the input span get automatically
  /// consumed. The underlying storage isn't necessarily contiguous, so
  /// the callback may be called more than once, whether or not it fully
  /// consumes its input. If the specified range is empty, the callback
  /// may not be called at all.
  ///
  /// - Parameter n: The number of items to consume from the front of the deque.
  ///   `n` must be greater than or equal to zero and must not exceed
  ///   the count of the deque.
  /// - Parameter consumer: A function taking an input span of the removed items,
  ///    allowing them to be consumed straight out of the deque's storage.
  /// - Complexity: O(`n`)
  @_alwaysEmitIntoClient
  @inline(__always)
  public mutating func consumeFirst(
    _ n: Int,
    consumingWith consumer: (inout InputSpan<Element>) -> Void
  ) {
    _storage.consumeFirst(n, consumingWith: consumer)
  }

#endif
}

#if COLLECTIONS_UNSTABLE_CONTAINERS_PREVIEW
@available(SwiftStdlib 5.0, *)
extension UniqueDeque where Element: ~Copyable {
  public typealias SubrangeConsumer = RigidDeque<Element>.SubrangeConsumer

  @_alwaysEmitIntoClient
  @inline(__always)
  @_lifetime(&self)
  public mutating func consume(
    _ subrange: Range<Index>
  ) -> SubrangeConsumer {
    _storage.consume(subrange)
  }
  
  @_alwaysEmitIntoClient
  @inline(__always)
  @_lifetime(&self)
  public mutating func consume<R: RangeExpression<Index>>(
    _ subrange: R
  ) -> SubrangeConsumer {
    consume(subrange.relative(to: indices))
  }
  
  @_alwaysEmitIntoClient
  @inline(__always)
  @_lifetime(&self)
  public mutating func consumeAll() -> SubrangeConsumer {
    consume(indices)
  }
  
  @_alwaysEmitIntoClient
  @inline(__always)
  @_lifetime(&self)
  public mutating func consumeLast(_ n: Int) -> SubrangeConsumer {
    precondition(
      n >= 0 && n <= self.count,
      "Count of elements to consume is out of bounds")
    return consume(self.count - n ..< self.count)
  }
  
  @_alwaysEmitIntoClient
  @inline(__always)
  @_lifetime(&self)
  public mutating func consumeFirst(_ n: Int) -> SubrangeConsumer {
    precondition(
      n >= 0 && n <= self.count,
      "Count of elements to consume is out of bounds")
    return consume(0 ..< n)
  }
}
#endif

#endif
