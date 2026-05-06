//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Collections open source project
//
// Copyright (c) 2024 - 2026 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
//
// SPDX-License-Identifier: Apache-2.0 WITH Swift-exception
//
//===----------------------------------------------------------------------===//

import XCTest
#if COLLECTIONS_SINGLE_MODULE
import Collections
#else
import _CollectionsTestSupport
import ContainersPreview
#endif

#if compiler(>=6.2)
final class UniqueBoxTests: CollectionTestCase {
  func test_basic() {
    var box = UniqueBox<Int>(0)

    expectEqual(box.value, 0)

    box.value = 123

    expectEqual(box.value, 123)

    expectEqual(box.clone().value, 123)

#if compiler(>=6.3) && COLLECTIONS_UNSTABLE_CONTAINERS_PREVIEW
    var boxRef = box.leak()

    expectEqual(boxRef.value, 123)

    boxRef.value = 321

    expectEqual(boxRef.value, 321)
#endif
  }
}
#endif
