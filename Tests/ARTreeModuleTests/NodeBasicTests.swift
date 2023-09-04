//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Collections open source project
//
// Copyright (c) 2023 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
//
//===----------------------------------------------------------------------===//

import _CollectionsTestSupport
@testable import ARTreeModule

final class ARTreeNodeBasicTests: CollectionTestCase {
  func testNodeSizes() throws {
    let header = MemoryLayout<InternalNodeHeader>.stride
    expectEqual(header, 12)

    typealias Spec = DefaultSpec<Int>
    let childSlotSize = MemoryLayout<RawNode?>.stride
    let ptrSize = MemoryLayout<Int>.stride
    let refSize = MemoryLayout<RawNode?>.stride
    let size4 = Node4<Spec>.size
    let size16 = Node16<Spec>.size
    let size48 = Node48<Spec>.size
    let size256 = Node256<Spec>.size

    print("sizeof(RawNode?) = \(refSize)")
    print("sizeOf(Int) = \(ptrSize)")
    print("sizeOf(childSlot) = \(childSlotSize)")
    print("sizeOf(Header) = \(header)")
    print("sizeOf(.node4) = \(size4)")
    print("sizeOf(.node16) = \(size16)")
    print("sizeOf(.node48) = \(size48)")
    print("sizeOf(.node256) = \(size256)")

    expectEqual(size4, header + 4 + 4 * ptrSize)
    expectEqual(size16, header + 16 + 16 * ptrSize)
    expectEqual(size48, header + 256 + 48 * ptrSize)
    expectEqual(size256, header + 256 * ptrSize)
  }
}
