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

@available(SwiftStdlib 6.2, *)
public protocol BidirectionalContainer<Element>: Container, ~Copyable, ~Escapable {
  func index(before i: Index) -> Index
  func formIndex(before i: inout Index)

  @lifetime(borrow self)
  func previousSpan(before index: inout Index) -> Span<Element>
}

@available(SwiftStdlib 6.2, *)
extension BidirectionalContainer where Self: ~Copyable & ~Escapable {
  @inlinable
  @lifetime(borrow self)
  public func previousSpan(before index: inout Index, maximumCount: Int) -> Span<Element> {
    var span = previousSpan(before: &index)
    if span.count > maximumCount {
      // Index remains within the same span, so offseting it is expected to be quick
      index = self.index(index, offsetBy: span.count - maximumCount)
      span = span._extracting(last: maximumCount)
    }
    return span
  }
}
