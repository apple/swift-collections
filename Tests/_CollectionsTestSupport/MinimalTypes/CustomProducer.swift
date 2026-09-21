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
package struct CustomProducer<Element: ~Copyable, Failure: Error>: ~Copyable {
  package let underestimatedCount: Int
  package let _generator: (Int) throws(Failure) -> Element?
  package var _offset: Int

  package init(
    underestimatedCount: Int = 0,
    generatingWith generator: borrowing @escaping (Int) throws(Failure) -> Element?
  ) {
    self.underestimatedCount = underestimatedCount
    self._generator = copy generator
    self._offset = 0
  }

  package var offset: Int { _offset }
}

@available(SwiftStdlib 5.0, *)
extension CustomProducer: Producer where Element: ~Copyable {
  package mutating func generate(
    into target: inout OutputSpan<Element>
  ) throws(Failure) -> Int {
    var c = 0
    while !target.isFull {
      guard let next = try _generator(_offset) else { return c }
      target.append(next)
      _offset += 1
      c += 1
    }
    return c
  }
}

#endif
