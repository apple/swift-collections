//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Collections open source project
//
// Copyright (c) 2026 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
//
// SPDX-License-Identifier: Apache-2.0 WITH Swift-exception
//
//===----------------------------------------------------------------------===//

#if compiler(>=6.3) && COLLECTIONS_UNSTABLE_CONTAINERS_PREVIEW

@available(SwiftStdlib 5.0, *)
extension BorrowingIteratorProtocol
where
  Self: ~Copyable & ~Escapable,
  Element: Copyable
{
  /// Turns a borrowing iterator into a producer by copying its elements.
  /// This allows producer algorithms (such as `collect(into:)`) to get
  /// invoked on borrowing iterators, while making it explicit that contents
  /// will get copied.
  @inlinable
  @_lifetime(copy self)
  public consuming func copy() -> BorrowingMapProducer<Self, Element, Never> {
    // FIXME: We could also just define a direct implementation that avoids the closure.
    BorrowingMapProducer(_base: self, transform: { $0 })
  }

  // Note: We could also define `collect(into:)` directly on borrowing iterators,
  // like in the commented out example below.
  //
  // However, I think that would be counterproductive to our goal of predictable
  // performance, as it would make the copies implicit. Compare and contrast:
  //
  //    items.borrow().collect(into: UniqueArray.self)
  //
  //    items.borrow().copy().collect(into: UniqueArray.self)
  //
  // The latter is more verbose, but it is extremely clear that it is copying
  // elements -- it avoids sweeping the cost of that under the carpet.
  #if false // See above
  @inlinable
  public consuming func collect<
    R: DynamicContainer<Element> & ~Copyable
  >(
    into container: R.Type = R.self
  ) -> R {
    var result = R()
    while true {
      let span = self.nextSpan()
      guard !span.isEmpty else { break }
      result.append(copying: span)
    }
    return result
  }
  #endif
}

#endif
