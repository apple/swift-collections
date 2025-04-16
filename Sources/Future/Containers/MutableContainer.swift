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

@available(SwiftStdlib 6.2, *) // for MutableSpan
public protocol Muterator: ~Copyable, ~Escapable {
  associatedtype Element: ~Copyable

  @lifetime(&self)
  mutating func nextChunk(maximumCount: Int) -> MutableSpan<Element>
}

@available(SwiftStdlib 6.2, *) // for MutableSpan
public protocol MutableContainer: Container, ~Copyable, ~Escapable {
  associatedtype MutatingIterationState: ~Copyable, ~Escapable

  @lifetime(&self)
  mutating func startMutatingIteration() -> MutatingIterationState
  
  /// This is a temporary stand-in for the subscript requirement that we actually want:
  ///
  ///     subscript(index: Index) -> Element { borrow mutate }
  @lifetime(&self)
  mutating func mutateElement(at index: Index) -> Inout<Element>
}

@available(SwiftStdlib 6.2, *) // for MutableSpan
extension MutableContainer where Self: ~Copyable & ~Escapable {
  @inlinable
  public subscript(index: Index) -> Element {
    unsafeAddress {
      unsafe borrowElement(at: index)._pointer
    }
    
    @lifetime(&self)
    unsafeMutableAddress {
      unsafe mutateElement(at: index)._pointer
    }
  }
}
