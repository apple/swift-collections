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

import XCTest
import ContainersPreview

#if compiler(>=6.4) && UnstableContainersPreview
@available(SwiftStdlib 6.4, *)
@inlinable
public func checkPermutableContainer<
  C: PermutableContainer & ~Copyable & ~Escapable,
  Expected: Sequence<C.Element>
>(
  _ container: inout C,
  expectedContents: Expected,
  file: StaticString = #filePath,
  line: UInt = #line
) where C.Element: Equatable {
  let entry = TestContext.current.push(
    "checkPermutableContainer", file: file, line: line)
  defer { TestContext.current.pop(entry) }

  do {
    try validatePermutableContainer(
      &container, expectedContents: expectedContents)
  } catch {
    expectFailure(error.message, file: file, line: line)
  }
}

@available(SwiftStdlib 6.4, *)
@inlinable
public func validatePermutableContainer<
  C: PermutableContainer & ~Copyable & ~Escapable,
  Expected: Sequence<C.Element>
>(
  _ container: inout C,
  expectedContents: Expected
) throws(ValidationError) where C.Element: Equatable {
  let expectedContents = Array(expectedContents)
  try validateContainer(
    container,
    expectedContents: expectedContents,
    by: ==,
    printer: { "\($0)" })

  let count = container.count
  var allIndices = [container.startIndex]
  for offset in 0 ..< count {
    allIndices.append(container.index(after: allIndices[offset]))
  }
  var model = expectedContents
  let pairs = (0 ..< count).flatMap { i in (0 ..< count).map { (i, $0) } }
  for (i, j) in pairs + pairs.reversed() {
    container.swapAt(allIndices[i], allIndices[j])
    model.swapAt(i, j)
    for offset in 0 ..< count {
      guard container[allIndices[offset]] == model[offset] else {
        throw ValidationError(
          "`swapAt(_:_:)` must exchange the items at the two indices",
          ["i": allIndices[i],
           "j": allIndices[j],
           "offset": offset,
           "expected": model[offset],
           "actual": container[allIndices[offset]]])
      }
    }
  }
}
#endif
