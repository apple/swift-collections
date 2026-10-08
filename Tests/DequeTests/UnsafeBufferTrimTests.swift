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
#if COLLECTIONS_SINGLE_MODULE
import Collections
#else
import _CollectionsTestSupport
import InternalCollectionsUtilities
#endif

/// Tests for the `_trim(first:)` and `_trim(last:)` helpers on the unsafe
/// buffer pointer types in `InternalCollectionsUtilities`. These are used by
/// the deque consumption/segment machinery, so a wrong result here corrupts
/// the spans that get handed out to clients.
final class UnsafeBufferTrimTests: CollectionTestCase {
  func test_mutableBuffer_trimFirst() {
    let values = [10, 20, 30, 40, 50]
    values.withUnsafeBufferPointer { source in
      let storage = UnsafeMutableBufferPointer<Int>.allocate(capacity: source.count)
      defer { unsafe storage.deallocate() }
      _ = unsafe storage.initialize(fromContentsOf: source)
      defer { unsafe storage.deinitialize() }

      var rest = unsafe storage
      let head = unsafe rest._trim(first: 2)
      expectEqual(unsafe Array(head), [10, 20])
      expectEqual(unsafe Array(rest), [30, 40, 50])

      // Trimming more than the count yields everything.
      var all = unsafe storage
      let everything = unsafe all._trim(first: 99)
      expectEqual(unsafe Array(everything), [10, 20, 30, 40, 50])
      expectEqual(all.count, 0)
    }
  }

  func test_mutableBuffer_trimLast() {
    let values = [10, 20, 30, 40, 50]
    values.withUnsafeBufferPointer { source in
      let storage = UnsafeMutableBufferPointer<Int>.allocate(capacity: source.count)
      defer { unsafe storage.deallocate() }
      _ = unsafe storage.initialize(fromContentsOf: source)
      defer { unsafe storage.deinitialize() }

      var rest = unsafe storage
      let tail = unsafe rest._trim(last: 2)
      expectEqual(unsafe Array(tail), [40, 50])
      expectEqual(unsafe Array(rest), [10, 20, 30])

      var all = unsafe storage
      let everything = unsafe all._trim(last: 99)
      expectEqual(unsafe Array(everything), [10, 20, 30, 40, 50])
      expectEqual(all.count, 0)
    }
  }

  func test_immutableBuffer_trimFirst() {
    let values = [10, 20, 30, 40, 50]
    values.withUnsafeBufferPointer { source in
      var rest = unsafe source
      let head = rest._trim(first: 2)
      expectEqual(unsafe Array(head), [10, 20])
      expectEqual(unsafe Array(rest), [30, 40, 50])

      var all = unsafe source
      let everything = all._trim(first: 99)
      expectEqual(unsafe Array(everything), [10, 20, 30, 40, 50])
      expectEqual(all.count, 0)
    }
  }

  func test_immutableBuffer_trimLast() {
    let values = [10, 20, 30, 40, 50]
    values.withUnsafeBufferPointer { source in
      var rest = unsafe source
      let tail = rest._trim(last: 2)
      expectEqual(unsafe Array(tail), [40, 50])
      expectEqual(unsafe Array(rest), [10, 20, 30])

      var all = unsafe source
      let everything = all._trim(last: 99)
      expectEqual(unsafe Array(everything), [10, 20, 30, 40, 50])
      expectEqual(all.count, 0)
    }
  }

  func test_trim_zeroIsNoOp() {
    let values = [1, 2, 3]
    values.withUnsafeBufferPointer { source in
      var a = unsafe source
      expectEqual(a._trim(first: 0).count, 0)
      expectEqual(unsafe Array(a), [1, 2, 3])

      var b = unsafe source
      expectEqual(b._trim(last: 0).count, 0)
      expectEqual(unsafe Array(b), [1, 2, 3])
    }
  }
}
