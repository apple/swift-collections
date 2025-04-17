//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Collections open source project
//
// Copyright (c) 2024 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
//
//===----------------------------------------------------------------------===//

#if !COLLECTIONS_SINGLE_MODULE
import Future
#endif

extension Deque: RandomAccessContainer {
  @lifetime(borrow self)
  public func borrowElement(at index: Int) -> Borrow<Element> {
    _storage.value.borrowElement(at: index)
  }

  @available(SwiftCompatibilitySpan 5.0, *)
  @lifetime(borrow self)
  public func span(following index: inout Int, maximumCount: Int) -> Span<Element> {
    _storage.value.span(following: &index, maximumCount: maximumCount)
  }
}
