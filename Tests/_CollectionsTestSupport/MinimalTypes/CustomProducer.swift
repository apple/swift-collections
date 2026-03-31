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

#if compiler(>=6.4) && COLLECTIONS_UNSTABLE_CONTAINERS_PREVIEW

@available(SwiftStdlib 5.0, *)
package struct CustomProducer<Element: ~Copyable, ProducerError: Error>: ~Copyable {
  package let underestimatedCount: Int
  package let _chunkSize: Int
  package let _generator: () throws(ProducerError) -> Element?

  package init(
    underestimatedCount: Int = 0,
    chunkSize: Int = Int.max,
    generatingWith generator: borrowing @escaping () throws(ProducerError) -> Element?
  ) {
    self.underestimatedCount = underestimatedCount
    self._chunkSize = chunkSize
    self._generator = copy generator
  }
}

@available(SwiftStdlib 5.0, *)
extension CustomProducer: Producer where Element: ~Copyable {
  package mutating func generate(
    into target: inout OutputSpan<Element>
  ) throws(ProducerError) -> Bool {
    var i = 0
    while !target.isFull, i < _chunkSize {
      guard let next = try _generator() else { return false }
      target.append(next)
      i += 1
    }
    return true
  }
}

#endif
