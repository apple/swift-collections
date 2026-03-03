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
extension RigidDictionary where Key: ~Copyable, Value: ~Copyable {
#if COLLECTIONS_UNSTABLE_CONTAINERS_PREVIEW
  @inlinable
  public mutating func consumeAll(
    consumingWith consumer: (
      inout InputSpan<Key>,
      inout InputSpan<Value>
    ) -> Void
  ) {
    let keys = self._keys._memberBuf
    let values = self._valueBuf
    _keys._table.consumeAll { buckets in
      let keyBuffer = keys._extracting(buckets)
      let valueBuffer = values._extracting(buckets)
      var keySpan = InputSpan(buffer: keyBuffer, initializedCount: keyBuffer.count)
      var valueSpan = InputSpan(buffer: valueBuffer, initializedCount: valueBuffer.count)
      consumer(&keySpan, &valueSpan)
      _ = consume keySpan
      _ = consume valueSpan
    }
  }
#endif
  
  @inlinable
  public mutating func _consumeAll(
    consumingWith consumer: (
      UnsafeMutableBufferPointer<Key>,
      UnsafeMutableBufferPointer<Value>
    ) -> Void
  ) {
    let keys = self._keys._memberBuf
    let values = self._valueBuf
    _keys._table.consumeAll { buckets in
      consumer(keys._extracting(buckets), values._extracting(buckets))
    }
  }
}

#endif
