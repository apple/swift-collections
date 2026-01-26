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

#if compiler(>=6.2) && COLLECTIONS_UNSTABLE_CONTAINERS_PREVIEW

@available(SwiftStdlib 5.0, *)
package struct CustomProducer<Element: ~Copyable, ProducerError: Error>: ~Copyable {
  package let underestimatedCount: Int
  package let generator: () throws(ProducerError) -> Element?

  package init(
    underestimatedCount: Int = 0,
    generatingWith generator: borrowing @escaping () throws(ProducerError) -> Element?
  ) {
    self.underestimatedCount = underestimatedCount
    self.generator = copy generator
  }
}

@available(SwiftStdlib 5.0, *)
extension CustomProducer: Producer where Element: ~Copyable {
  package mutating func generate(
    into target: inout OutputSpan<Element>
  ) throws(ProducerError) -> Bool {
    while !target.isFull {
      guard let next = try generator() else { return false }
      target.append(next)
    }
    return true
  }
}

#endif
