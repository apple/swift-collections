//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Collections open source project
//
// Copyright (c) 2024 - 2026 Apple Inc. and the Swift project authors
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

#if UnstableContainersPreview
@available(SwiftStdlib 5.0, *)
extension RigidArray where Element: ~Copyable {
  @_lifetime(&self)
  public mutating func _consumeAll() -> InputSpan<Element> {
    let buffer = unsafe _items
    unsafe self._count = 0
    let result = unsafe InputSpan(
      buffer: buffer,
      initializedCount: buffer.count)
    return unsafe _overrideLifetime(result, mutating: &self)
  }

  /// Remove the specified subrange of items from this array,
  /// passing an input span to the given function to consume them in place.
  ///
  /// - Parameter subrange: The subrange of items to consume from this array.
  /// - Parameter consumer: A function taking an input span of the removed items,
  ///    allowing them to be consumed straight out of the array's storage.
  ///    The function is not required to consume all items in the span;
  ///    however, the span's remaining items will still be removed from
  ///    the array.
  /// - Returns: A valid index addressing the position following the consumed
  ///    range.
  /// - Complexity: O(`self.count`)
  @_alwaysEmitIntoClient
  @discardableResult
  public mutating func consumeSubrange(
    _ subrange: Range<Int>,
    consumingWith consumer: (inout InputSpan<Element>) -> Void
  ) -> Index {
    _checkValidBounds(subrange)
    guard !subrange.isEmpty else {
      var span = InputSpan<Element>()
      consumer(&span)
      return subrange.lowerBound
    }
    let buffer = unsafe _storage.extracting(subrange)
    var span = unsafe InputSpan(buffer: buffer, initializedCount: buffer.count)

    consumer(&span)
    _ = consume span

    unsafe _closeGap(at: subrange.lowerBound, count: subrange.count)
    unsafe _count -= subrange.count
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
  /// - Parameter subrange: The subrange of items to consume from this array.
  /// - Parameter consumer: A function taking an input span of the removed items,
  ///    allowing them to be consumed straight out of the array's storage.
  ///    The function is called at most once.
  /// - Returns: A valid index addressing the upper bound of the consumed
  ///    range in the resulting array.
  /// - Complexity: O(`self.count`)
  @_alwaysEmitIntoClient
  @inline(__always)
  @discardableResult
  public mutating func consumeSubrange<R: RangeExpression<Index>>(
    _ subrange: R,
    consumingWith consumer: (inout InputSpan<Element>) -> Void
  ) -> Int {
    consumeSubrange(subrange.relative(to: indices), consumingWith: consumer)
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
    self.consumeSubrange(self.indices, consumingWith: consumer)
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
    precondition(
      n >= 0 && n <= self.count,
      "Count of elements to consume is out of bounds")
    self.consumeSubrange(self.count &- n ..< self.count, consumingWith: consumer)
  }
}
#endif

#if compiler(>=6.4) && UnstableContainersPreview
@available(SwiftStdlib 5.0, *)
extension RigidArray where Element: ~Copyable {
  @_alwaysEmitIntoClient
  @inline(always)
  @_lifetime(&self)
  public mutating func consumeSubrange(
    _ subrange: Range<Index>
  ) -> SubrangeConsumer {
    SubrangeConsumer(_base: &self, offsetRange: subrange)
  }
}

@available(SwiftStdlib 5.0, *)
extension RigidArray where Element: ~Copyable {
  @available(SwiftStdlib 5.0, *)
  @frozen
  @safe
  public struct SubrangeConsumer: ~Copyable, ~Escapable {
    // FIXME: We have to use our own MutableRef because the standard one
    // provides no access to the underlying pointer. See deinit why we need it.
    @usableFromInline
    @unsafe
    internal var _base: _MutableRef<RigidArray>

    @usableFromInline
    @unsafe
    internal var _offsetRange: Range<Int>

    @usableFromInline
    @unsafe
    internal var _remainder: UnsafeMutableBufferPointer<Element>

    @_alwaysEmitIntoClient
    @inline(__always)
    @_lifetime(&_base)
    internal init(_base: inout RigidArray, offsetRange: Range<Int>) {
      _base._checkValidBounds(offsetRange)
      unsafe self._remainder = _base._storage._extracting(unchecked: offsetRange)
      unsafe self._base = _MutableRef(&_base)
      unsafe self._offsetRange = offsetRange
    }

    @inlinable
    deinit {
      unsafe self._remainder.deinitialize()

      // FIXME: This needs to be written as
      //    self._base.value.closeGap(offsets: self._offsetRange)
      // but unfortunately we cannot mutate self in deinit yet.
      // MutableRef's dereferencing operation is necessarily declared mutating
      // to avoid exclusivity violations.
      unsafe self._base._pointer.pointee
        ._closeGap(at: _offsetRange.lowerBound, count: _offsetRange.count)
      unsafe self._base._pointer.pointee._count -= _offsetRange.count
    }
  }
}

@available(SwiftStdlib 5.0, *)
extension RigidArray.SubrangeConsumer where Element: ~Copyable {
  public typealias Index = Int

  @inlinable
  public var count: Int {
    unsafe _remainder.count
  }

  @inlinable
  @_lifetime(&self)
  @_lifetime(self: copy self)
  public mutating func drainNext(maxCount: Int) -> InputSpan<Element> {
    if unsafe _remainder.isEmpty {
      return .init()
    }
    let buffer = unsafe _remainder._trim(first: maxCount)
    return unsafe _overrideLifetime(
      InputSpan(buffer: buffer, initializedCount: buffer.count),
      mutating: &self)
  }

  @inlinable
  public consuming func finalize() -> Index {
    unsafe _offsetRange.lowerBound
  }
}
#endif
