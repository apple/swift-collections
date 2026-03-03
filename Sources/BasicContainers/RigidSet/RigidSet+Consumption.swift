//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Collections open source project
//
// Copyright (c) 2026 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
//
//===----------------------------------------------------------------------===//

#if !COLLECTIONS_SINGLE_MODULE
import ContainersPreview
#endif

#if compiler(>=6.3) && COLLECTIONS_UNSTABLE_NONCOPYABLE_KEYS

@available(SwiftStdlib 5.0, *)
extension RigidSet where Element: ~Copyable {
#if COLLECTIONS_UNSTABLE_CONTAINERS_PREVIEW
  @inlinable
  public mutating func consumeAll(
    consumingWith consumer: (inout InputSpan<Element>) -> Void
  ) {
    let storage = self._memberBuf
    _table.consumeAll { buckets in
      let buffer = storage._extracting(buckets)
      var span = InputSpan(buffer: buffer, initializedCount: buffer.count)
      consumer(&span)
      _ = consume span
    }
  }
#endif
  
  @inlinable
  public mutating func _consumeAll(
    consumingWith consumer: (UnsafeMutableBufferPointer<Element>) -> Void
  ) {
    let storage = self._memberBuf
    _table.consumeAll { buckets in
      consumer(storage._extracting(buckets))
    }
  }
}

#endif
