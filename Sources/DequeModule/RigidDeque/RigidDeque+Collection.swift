//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Collections open source project
//
// Copyright (c) 2025 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
//
//===----------------------------------------------------------------------===//

#if !COLLECTIONS_SINGLE_MODULE
import InternalCollectionsUtilities
import ContainersPreview
#endif

#if compiler(>=6.2)

@available(SwiftStdlib 5.0, *)
extension RigidDeque {
  @inlinable
  public func _copyToContiguousArray() -> ContiguousArray<Element> {
    ContiguousArray(unsafeUninitializedCapacity: count) { target, count in
      let segments = _handle.segments()
      let c = segments.first.count
      target[..<c].initializeAll(fromContentsOf: segments.first)
      count += segments.first.count
      if let second = segments.second {
        target[c ..< c + second.count].initializeAll(fromContentsOf: second)
        count += second.count
      }
      assert(count == _handle.count)
    }
  }
}

#endif
