//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Collections open source project
//
// Copyright (c) 2025 - 2026 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
//
//===----------------------------------------------------------------------===//

#if COLLECTIONS_SINGLE_MODULE
import Collections
#else
import InternalCollectionsUtilities
import BasicContainers
import ContainersPreview
#endif

#if compiler(>=6.2) && COLLECTIONS_UNSTABLE_CONTAINERS_PREVIEW

@available(SwiftStdlib 5.0, *)
package struct CustomDrain<Element: ~Copyable>: ~Copyable {
  package let underestimatedCount: Int
  package let _chunkSize: Int
  package let _generator: () -> Element?
  package var _buffer: RigidArray<Element>
  package var _remainder: Int

  package init(
    underestimatedCount: Int = 0,
    chunkSize: Int,
    generatingWith generator: @escaping () -> Element?
  ) {
    self.underestimatedCount = underestimatedCount
    self._chunkSize = chunkSize
    self._generator = generator
    self._buffer = .init(capacity: _chunkSize)
    self._remainder = _chunkSize
  }
}

@available(SwiftStdlib 5.0, *)
extension CustomDrain: Drain where Element: ~Copyable {
  @_lifetime(&self)
  package mutating func drainNext(maximumCount: Int) -> InputSpan<Element> {
    assert(_buffer.isEmpty)
    if _remainder == 0 {
      _remainder = _chunkSize
    }
    let c = Swift.min(maximumCount, _remainder)
    _remainder -= c
    for _ in 0 ..< c {
      guard let next = _generator() else { break }
      _buffer.append(next)
    }
    return _buffer._consumeAll()
  }
}

#endif
