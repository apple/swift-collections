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

#if compiler(>=6.3) && COLLECTIONS_UNSTABLE_NONCOPYABLE_KEYS && COLLECTIONS_UNSTABLE_CONTAINERS_PREVIEW

@available(SwiftStdlib 5.0, *)
extension UniqueSet where Element: ~Copyable {
#if COLLECTIONS_UNSTABLE_CONTAINERS_PREVIEW
  @inlinable
  public mutating func consumeAll(
    consumingWith consumer: (inout InputSpan<Element>) -> Void
  ) {
    self._consumeAll { buffer in
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
    _storage._consumeAll(consumingWith: consumer)
  }

}

#endif
