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

import Builtin

@available(SwiftStdlib 6.2, *)
extension Span: RandomAccessContainer where Element: ~Copyable {
  @inlinable
  public var startIndex: Int { 0 }
  @inlinable
  public var endIndex: Int { count }

  @inlinable
  @lifetime(copy self)
  public func borrowElement(at index: Int) -> Borrow<Element> {
    unsafe Borrow(unsafeAddress: _unsafeAddressOfElement(index), copying: self)
  }

  @lifetime(copy self)
  public func nextSpan(after index: inout Index, maximumCount: Int) -> Span<Element> {
    precondition(index >= 0 && index <= count, "Invalid index")
    let end = index + Swift.min(count - index, maximumCount)
    defer { index = end }
    return _extracting(unsafe Range(uncheckedBounds: (index, end)))
  }
}

@available(SwiftStdlib 6.2, *)
extension Span where Element: ~Copyable {
  @usableFromInline
  typealias _Components = (pointer: UnsafeRawPointer?, count: Int)

  // FIXME: This is *wildly* unsafe; remove it.
  @unsafe
  @_alwaysEmitIntoClient
  @_transparent
  @lifetime(copy self)
  internal func _unsafelyExplode() -> _Components {
    unsafe assert(
      MemoryLayout<Self>.size == MemoryLayout<_Components>.size,
      "Unexpected Span layout")
    let immortal = unsafe _overrideLifetime(self, borrowing: immortalThing)
    return unsafe Builtin.reinterpretCast(immortal)
  }

  // FIXME: This is *wildly* unsafe; remove it.
  @unsafe
  @_alwaysEmitIntoClient
  internal func _unsafeAddressOfElement(
    unchecked position: Index
  ) -> UnsafePointer<Element> {
    let (start, _) = unsafe _unsafelyExplode()
    let elementOffset = position &* MemoryLayout<Element>.stride
    let address = unsafe start.unsafelyUnwrapped.advanced(by: elementOffset)
    return unsafe address.assumingMemoryBound(to: Element.self)
  }

  // FIXME: This is *wildly* unsafe; remove it.
  @unsafe
  @_alwaysEmitIntoClient
  internal func _unsafeAddressOfElement(
    _ position: Index
  ) -> UnsafePointer<Element> {
    precondition(position >= 0 && position < count, "Index out of bounds")
    return unsafe _unsafeAddressOfElement(unchecked: position)
  }
}

