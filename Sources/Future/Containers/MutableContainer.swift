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

@available(SwiftCompatibilitySpan 5.0, *)
public protocol MutableContainer<Element>: Container, ~Copyable, ~Escapable {
#if compiler(>=9999) // FIXME: We can't do this yet
  subscript(index: Index) -> Element { borrow mutate }
#else
  @lifetime(&self)
  mutating func mutateElement(at index: Index) -> Inout<Element>
#endif

  @lifetime(&self)
  mutating func nextMutableSpan(after index: inout Index) -> MutableSpan<Element>

  // FIXME: What about previousMutableSpan?
}

@available(SwiftCompatibilitySpan 5.0, *)
extension MutableContainer where Self: ~Copyable & ~Escapable {
  #if false // Hm...
  @lifetime(&self)
  mutating func nextMutableSpan(
    after index: inout Index, maximumCount: Int
  ) -> MutableSpan<Element> {
    let original = index
    var span = self.nextMutableSpan(after: &index)
    if span.count > maximumCount {
      span = span.extracting(first: maximumCount)
      // Index remains within the same span, so offseting it is expected to be quick
      index = self.index(original, offsetBy: maximumCount)
    }
    return span
  }
  #endif

  @inlinable
  public subscript(index: Index) -> Element {
    @lifetime(borrow self)
    unsafeAddress {
      unsafe borrowElement(at: index)._pointer
    }
    
    @lifetime(&self)
    unsafeMutableAddress {
      unsafe mutateElement(at: index)._pointer
    }
  }
}
