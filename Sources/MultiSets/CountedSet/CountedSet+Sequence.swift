//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Collections open source project
//
// Copyright (c) 2021 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
//
//===----------------------------------------------------------------------===//

extension CountedSet: Sequence {
  /// Returns an iterator over the elements of this collection.
  ///
  /// - Complexity: O(1)
  /// - Remark: A type-erased wrapper is used instead of an opaque type purely
  /// to preserve compatibility with older versions of Swift.
  @inlinable
  public func makeIterator() -> AnyIterator<Element> {
    AnyIterator(_storage.lazy.flatMap(repeatElement).makeIterator())
  }
}
