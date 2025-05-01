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

@available(SwiftStdlib 6.2, *)
extension UnsafeMutableBufferPointer: @unsafe ContiguousContainer
where Element: ~Copyable
{
  /// The contents of `self` must not be mutated while the returned span exists.
  public var span: Span<Element> {
    @inlinable
    @lifetime(borrow self)
    get {
      unsafe Span(_unsafeElements: self)
    }
  }

  @inlinable
  @lifetime(borrow self)
  public func borrowElement(at index: Int) -> Borrow<Element> {
    precondition(index >= 0 && index < count, "Index out of bounds")
    let ptr = unsafe baseAddress.unsafelyUnwrapped + index
    return unsafe Borrow(unsafeAddress: ptr, borrowing: self)
  }
}
