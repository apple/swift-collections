//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Collections open source project
//
// Copyright (c) 2025 - 2026 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
//
//===----------------------------------------------------------------------===//

#if !COLLECTIONS_SINGLE_MODULE
import InternalCollectionsUtilities
import ContainersPreview
#endif

#if compiler(>=6.2)

#if COLLECTIONS_UNSTABLE_CONTAINERS_PREVIEW
@available(SwiftStdlib 5.0, *)
extension RigidArray: BorrowingSequence where Element: ~Copyable {
  public typealias BorrowingIterator = Span<Element>.BorrowingIterator
  
  @inlinable
  public var estimatedCount: EstimatedCount {
    .exactly(count)
  }
  
  @_alwaysEmitIntoClient
  @inline(__always)
  public func makeBorrowingIterator() -> BorrowingIterator {
    self.span.makeBorrowingIterator()
  }
}
#endif

#if COLLECTIONS_UNSTABLE_CONTAINERS_PREVIEW
@available(SwiftStdlib 5.0, *)
extension RigidArray: Container where Element: ~Copyable {
}
#endif

@available(SwiftStdlib 5.0, *)
extension RigidArray where Element: ~Copyable {
  @_alwaysEmitIntoClient
  @inline(__always)
  public func index(after index: Int) -> Int { index + 1 }
  
  @_alwaysEmitIntoClient
  @inline(__always)
  public func formIndex(after index: inout Int) { index += 1 }

  @_alwaysEmitIntoClient
  @inline(__always)
  public func index(_ index: Int, offsetBy n: Int) -> Int {
    index + n
  }
  
  @_alwaysEmitIntoClient
  public func formIndex(
    _ index: inout Index, offsetBy n: inout Int, limitedBy limit: Index
  ) {
    index._advance(by: &n, limitedBy: limit)
  }

  @inlinable
  @_lifetime(borrow self)
  public func nextSpan(
    after index: inout Int, maximumCount: Int
  ) -> Span<Element> {
    precondition(index >= 0 && index <= _count, "Index out of bounds")
    let start = index
    index = start &+ Swift.min(maximumCount, _count &- start)
    return _span(in: Range(uncheckedBounds: (start, index)))
  }
}

#endif

