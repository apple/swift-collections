//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Collections open source project
//
// Copyright (c) 2024 - 2025 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
//
//===----------------------------------------------------------------------===//

#if compiler(>=6.3) // FIXME: Turn this on once we have a new enough toolchain
@available(SwiftStdlib 6.2, *) // for MutableSpan
public protocol Muterator: ~Copyable, ~Escapable {
  associatedtype Element: ~Copyable

  @lifetime(copy self)
  mutating func nextChunk(maximumCount: Int) -> MutableSpan<Element>
}

@available(SwiftStdlib 6.2, *) // for MutableSpan
public protocol MutableContainer: Container, ~Copyable, ~Escapable {
  associatedtype MutatingIterationState: ~Copyable, ~Escapable

  @lifetime(&self)
  mutating func startMutatingIteration() -> MutatingIterationState

  /// Return a pointer addressing the element at the given index.
  /// This is wildly unsafe; please do not use this outside of `unsafeAddress` accessors.
  ///
  /// This is a temporary stand-in for the subscript requirement that we actually want:
  ///
  ///     subscript(index: Index) -> Element { borrow mutate }
  @unsafe
  mutating func _unsafeMutableAddressOfElement(at index: Index) -> UnsafePointer<Element>
}

extension MutableContainer where Self: ~Copyable & ~Escapable {
  @inlinable
  public subscript(index: Index) -> Element {
    unsafeAddress {
      unsafe _unsafeAddressOfElement(at: index)
    }
    unsafeMutableAddress {
      unsafe _unsafeMutableAddressOfElement(at: index)
    }
  }
}
#endif
