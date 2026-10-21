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
#if !COLLECTIONS_SINGLE_MODULE
import _CollectionsTestSupport
#endif

final class SetAlgebraMemberIdentityTests: CollectionTestCase {
  func testSet() {
    checkSetAlgebraMemberIdentity(
      Set<LifetimeTracked<Int>>.self,
      models: [[], [0], [0, 1, 2, 3], Set(stride(from: 0, to: 200, by: 2))],
      members: { Array($0) })
  }
}
