//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Collections open source project
//
// Copyright (c) 2025 - 2026 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
//
// SPDX-License-Identifier: Apache-2.0 WITH Swift-exception
//
//===----------------------------------------------------------------------===//

#if COLLECTIONS_SINGLE_MODULE
import Collections
#else
import InternalCollectionsUtilities
import ContainersPreview
#endif

#if compiler(>=6.4) && UnstableContainersPreview

@available(SwiftStdlib 5.0, *)
package struct CustomCountedProducer<Element: ~Copyable, Failure: Error>: ~Copyable {
  package let count: Int
  package let underestimatedCount: Int
  package let _chunkSize: Int
  package let _generator: (Int) throws(Failure) -> Element
  package var _offset: Int

  package init(
    count: Int = 0,
    underestimatedCount: Int? = nil,
    chunkSize: Int = Int.max,
    generatingWith generator: borrowing @escaping (Int) throws(Failure) -> Element
  ) {
    precondition(count >= 0)
    self.count = count
    self.underestimatedCount = underestimatedCount ?? count
    precondition(self.underestimatedCount >= 0 && self.underestimatedCount <= count)
    precondition(count == 0 || chunkSize > 0)
    self._chunkSize = chunkSize
    self._generator = copy generator
    self._offset = 0
  }

  package var offset: Int { _offset }
}

@available(SwiftStdlib 5.0, *)
extension CustomCountedProducer: CountedProducer where Element: ~Copyable {
  package mutating func generate(
    into target: inout OutputSpan<Element>
  ) throws(Failure) -> Int {
    var c = 0
    while !target.isFull, _offset < count {
      target.append(try _generator(_offset))
      _offset += 1
      c += 1
    }
    return c
  }
}

#endif
