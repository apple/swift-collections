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
extension RigidDeque where Element: ~Copyable {
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
    precondition(
      subrange.lowerBound >= 0 && subrange.upperBound <= self.count,
      "Subrange out of bounds")
    let segments = self._handle.mutableSegments(forOffsets: subrange)
    
    var span = InputSpan(buffer: segments.first, initializedCount: segments.first.count)
    consumer(&span)
    _ = consume span
    
    if let second = segments.second {
      var span = InputSpan(buffer: second, initializedCount: second.count)
      consumer(&span)
    }
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
    precondition(
      n >= 0 && n <= self.count,
      "Count of elements to consume is out of bounds")
    consume(self.count &- n ..< self.count, consumingWith: consumer)
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
    precondition(
      n >= 0 && n <= self.count,
      "Count of elements to consume is out of bounds")
    consume(0 ..< n, consumingWith: consumer)
  }
#endif
}

#if COLLECTIONS_UNSTABLE_CONTAINERS_PREVIEW
@available(SwiftStdlib 5.0, *)
extension RigidDeque where Element: ~Copyable {
  @_alwaysEmitIntoClient
  @inline(__always)
  @_lifetime(&self)
  public mutating func consume(_ subrange: Range<Index>) -> SubrangeConsumer {
    SubrangeConsumer(_base: &self, offsetRange: subrange)
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

@available(SwiftStdlib 5.0, *)
extension RigidDeque where Element: ~Copyable {
  @frozen
  public struct SubrangeConsumer: ~Copyable, ~Escapable {
    @usableFromInline
    internal var _base: Inout<RigidDeque>
      
    @usableFromInline
    internal var _offsetRange: Range<Int>
    
    @usableFromInline
    internal var _buffer1: UnsafeMutableBufferPointer<Element>

    @usableFromInline
    internal var _buffer2: UnsafeMutableBufferPointer<Element>
    
    @_alwaysEmitIntoClient
    @inline(__always)
    @_lifetime(&_base)
    internal init(_base: inout RigidDeque, offsetRange: Range<Int>) {
      let segments = _base._handle.mutableSegments(forOffsets: offsetRange)
      self._buffer1 = segments.first
      self._buffer2 = segments.second ?? .init(start: nil, count: 0)
      self._base = Inout(&_base)
      self._offsetRange = offsetRange
    }

    @inlinable
    deinit {
      self._buffer1.deinitialize()
      self._buffer2.deinitialize()
      // FIXME: This needs to be written as
      //    self._base[]._handle.closeGap(offsets: self._offsetRange)
      // but unfortunately we cannot mutate self in deinit yet.
      // Inout's dereferencing operation is necessarily declared mutating
      // to avoid exclusivity violations.
      self._base._pointer.pointee._handle.closeGap(offsets: self._offsetRange)
    }
  }
}

@available(SwiftStdlib 5.0, *)
extension RigidDeque.SubrangeConsumer: Drain {
  @inlinable
  @_lifetime(&self)
  @_lifetime(self: copy self)
  public mutating func drainNext(maximumCount: Int) -> InputSpan<Element> {
    if _buffer1.isEmpty {
      if _buffer2.isEmpty {
        return .init()
      }
      swap(&_buffer1, &_buffer2)
    }
    let buffer = _buffer1._trim(first: maximumCount)
    return _overrideLifetime(
      InputSpan(buffer: buffer, initializedCount: buffer.count),
      mutating: &self)
  }
}
#endif

#endif
