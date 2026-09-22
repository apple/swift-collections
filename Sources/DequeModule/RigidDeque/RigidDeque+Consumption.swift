//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Collections open source project
//
// Copyright (c) 2026 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
//
// SPDX-License-Identifier: Apache-2.0 WITH Swift-exception
//
//===----------------------------------------------------------------------===//

#if !COLLECTIONS_SINGLE_MODULE
import InternalCollectionsUtilities
import SpanPreview
#endif

@available(SwiftStdlib 5.0, *)
extension RigidDeque where Element: ~Copyable {
#if UnstableContainersPreview
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
  /// - Parameter consumer: A function taking an input span of removed items,
  ///    allowing them to be consumed straight out of the deque's storage.
  /// - Returns: A valid index addressing the position following the consumed
  ///    range.
  /// - Complexity: O(`self.count`)
  @_alwaysEmitIntoClient
  @discardableResult
  public mutating func consumeSubrange(
    _ subrange: Range<Index>,
    consumingWith consumer: (inout InputSpan<Element>) -> Void
  ) -> Index {
    _checkValidBounds(subrange)
    let segments = self._handle.mutableSegments(forOffsets: subrange)

    var span = InputSpan(
      buffer: segments.first, initializedCount: segments.first.count)
    consumer(&span)
    _ = consume span

    if let second = segments.second {
      var span = InputSpan(buffer: second, initializedCount: second.count)
      consumer(&span)
      _ = consume span
    }
    _handle.closeGap(offsets: subrange)
    return subrange.lowerBound
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
  /// - Returns: A valid index addressing the position following the consumed
  ///    range.
  /// - Complexity: O(`self.count`)
  @_alwaysEmitIntoClient
  @inline(__always)
  @discardableResult
  public mutating func consumeSubrange<R: RangeExpression<Index>>(
    _ subrange: R,
    consumingWith consumer: (inout InputSpan<Element>) -> Void
  ) -> Index {
    consumeSubrange(subrange.relative(to: indices), consumingWith: consumer)
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
  /// - Complexity: O(`self.count`)
  @_alwaysEmitIntoClient
  @inline(__always)
  public mutating func consumeAll(
    consumingWith consumer: (inout InputSpan<Element>) -> Void
  ) {
    consumeSubrange(indices, consumingWith: consumer)
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
    consumeSubrange(self.count &- n ..< self.count, consumingWith: consumer)
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
    consumeSubrange(0 ..< n, consumingWith: consumer)
  }
#endif
}

#if compiler(>=6.4) && UnstableContainersPreview
@available(SwiftStdlib 5.0, *)
extension RigidDeque where Element: ~Copyable {
  @available(SwiftStdlib 5.0, *)
  @_alwaysEmitIntoClient
  @inline(__always)
  @_lifetime(&self)
  public mutating func consumeSubrange(
    _ subrange: Range<Index>
  ) -> SubrangeConsumer {
    SubrangeConsumer(_base: &self, offsetRange: subrange)
  }
}

@available(SwiftStdlib 5.0, *)
extension RigidDeque where Element: ~Copyable {
  // FIXME: This works around a Swift 6.5 name resolution issue; see usages below.
  @usableFromInline internal typealias _Element = Element

  @available(SwiftStdlib 5.0, *)
  @frozen
  public struct SubrangeConsumer: ~Copyable, ~Escapable {
    // FIXME: We have to use our own MutableRef because the standard one
    // provides no access to the underlying pointer. See deinit why we need it.
    @usableFromInline
    internal var _base: _MutableRef<RigidDeque>

    @usableFromInline
    internal var _offsetRange: Range<Int>

    // FIXME: This ought to be using `Element` directly, but when the package is
    // built using the Xcode project, some Swift 6.5 nightlies appear to
    // resolve it to a less available `Element` definition, causing a build
    // failure. The availability indicates it may be `Iterable.Element` via
    // the `Container` conformance; this is super confusing though.
    @usableFromInline
    internal var _buffer1: UnsafeMutableBufferPointer<_Element>

    @usableFromInline
    internal var _buffer2: UnsafeMutableBufferPointer<_Element>

    @_alwaysEmitIntoClient
    @inline(__always)
    @_lifetime(&_base)
    internal init(_base: inout RigidDeque, offsetRange: Range<Int>) {
      _base._checkValidBounds(offsetRange)
      let segments = _base._handle.mutableSegments(forOffsets: offsetRange)
      self._buffer1 = segments.first
      self._buffer2 = segments.second ?? .init(start: nil, count: 0)
      self._base = _MutableRef(&_base)
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
extension RigidDeque.SubrangeConsumer where Element: ~Copyable {
  public typealias Index = Int

  @inlinable
  public var count: Int {
    _buffer1.count + _buffer2.count
  }

  @inlinable
  @_lifetime(&self)
  @_lifetime(self: copy self)
  public mutating func drainNext(maxCount: Int) -> InputSpan<Element> {
    if _buffer1.isEmpty {
      if _buffer2.isEmpty {
        return .init()
      }
      swap(&_buffer1, &_buffer2)
    }
    let buffer = _buffer1._trim(first: maxCount)
    return _overrideLifetime(
      InputSpan(buffer: buffer, initializedCount: buffer.count),
      mutating: &self)
  }

  @inlinable
  public consuming func finalize() -> Int {
    _offsetRange.lowerBound
  }
}
#endif
