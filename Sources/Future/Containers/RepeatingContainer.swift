//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Collections open source project
//
// Copyright (c) 2025 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
//
//===----------------------------------------------------------------------===//

#if false // FIXME: Disabled until I have time to track down a flaky compiler crash

#if false // FIXME: This is what we'd want
import Builtin

@frozen
@_addressableForDependencies
public struct RepeatingContainer<Element: ~Copyable>: ~Copyable {
  @usableFromInline
  internal var _count: Int

  @usableFromInline
  internal var _item: Element

  public init(repeating item: consuming Element, count: Int) {
    self._item = item
    self._count = count
  }
}
#else
@frozen
public struct RepeatingContainer<Element: ~Copyable>: ~Copyable {
  @usableFromInline
  internal var _count: Int

  @usableFromInline
  internal var _contents: Box<Element>

  public init(repeating item: consuming Element, count: Int) {
    self._count = count
    self._contents = Box(item)
  }
}
#endif

extension RepeatingContainer where Element: ~Copyable {
  @inlinable
  public var startIndex: Int { 0 }

  @inlinable
  public var endIndex: Int { _count }
}

#if false // FIXME: This is what we'd want
@available(SwiftStdlib 6.2, *)
extension RepeatingContainer: RandomAccessContainer where Element: ~Copyable {
  @lifetime(borrow self)
  public func borrowElement(at index: Int) -> Borrow<Element> {
    Borrow(self._item)
  }

  @lifetime(borrow self)
  public func nextSpan(after index: inout Int) -> Span<Element> {
    let c = _count
    precondition(index >= 0 && index <= c, "Index out of bounds")
    guard index < c else { return .empty }
    index += 1
    // FIXME: Oh my
    let pointer = unsafe UnsafePointer<Element>(Builtin.unprotectedAddressOfBorrow(self._item))
    let span = unsafe Span(_unsafeStart: pointer, count: 1)
    return unsafe _overrideLifetime(span, borrowing: self)
  }

  @lifetime(borrow self)
  public func previousSpan(before index: inout Int) -> Span<Element> {
    let c = _count
    precondition(index >= 0 && index <= c, "Index out of bounds")
    guard index > 0 else { return .empty }
    index -= 1
    // FIXME: Oh my
    let pointer = unsafe UnsafePointer<Element>(Builtin.addressOfBorrow(self._item))
    let span = unsafe Span(_unsafeStart: pointer, count: 1)
    return unsafe _overrideLifetime(span, borrowing: self)
  }
}
#else
@available(SwiftStdlib 6.2, *)
extension RepeatingContainer: RandomAccessContainer where Element: ~Copyable {
  @lifetime(borrow self)
  public func borrowElement(at index: Int) -> Borrow<Element> {
    _contents.borrow()
  }

  @lifetime(borrow self)
  public func nextSpan(after index: inout Int) -> Span<Element> {
    let c = _count
    precondition(index >= 0 && index <= c, "Index out of bounds")
    guard index < c else { return .empty }
    index += 1
    return _contents.span
  }

  @lifetime(borrow self)
  public func previousSpan(before index: inout Int) -> Span<Element> {
    let c = _count
    precondition(index >= 0 && index <= c, "Index out of bounds")
    guard index > 0 else { return .empty }
    index -= 1
    return _contents.span
  }
}
#endif

#endif
