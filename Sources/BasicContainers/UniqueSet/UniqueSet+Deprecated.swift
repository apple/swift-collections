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

#if COLLECTIONS_SINGLE_MODULE // Don't define these outside the Xcode project

#if compiler(>=6.4) && UnstableHashedContainers
@available(SwiftStdlib 5.0, *)
extension UniqueSet where Element: ~Copyable {
  @available(*, deprecated, renamed: "insert(addingCount:initializingWith:)")
  @_alwaysEmitIntoClient
  public mutating func insert<E: Error>(
    maximumCount: Int,
    initializingWith initializer: (inout OutputSpan<Element>) throws(E) -> Void
  ) throws(E) -> Void {
    try self.insert(addingCount: maximumCount, initializingWith: initializer)
  }
}
#endif

#endif
