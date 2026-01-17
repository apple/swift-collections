//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Collections open source project
//
// Copyright (c) 2024 - 2026 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
//
//===----------------------------------------------------------------------===//

#if compiler(>=6.2) && COLLECTIONS_UNSTABLE_CONTAINERS_PREVIEW

#if !COLLECTIONS_SINGLE_MODULE
import InternalCollectionsUtilities
#endif

@available(SwiftStdlib 5.0, *)
@_alwaysEmitIntoClient
internal func withTemporaryOutputSpan<Element: ~Copyable, E: Error, R: ~Copyable>(
  of type: Element.Type,
  capacity: Int,
  _ body: (inout OutputSpan<Element>) throws(E) -> R
) throws(E) -> R {
  try withUnsafeTemporaryAllocation(
    of: Element.self, capacity: capacity
  ) { buffer throws(E) in
    var span = OutputSpan(buffer: buffer, initializedCount: 0)
    return try body(&span)
  }
}

@available(SwiftStdlib 5.0, *)
extension OutputSpan where Element: ~Copyable {
  /// Removes and returns the last element of this output span, if it exists.
  ///
  /// - Returns: The last element of the original span if it wasn't empty;
  ///    otherwise, `nil`.
  ///
  /// - Complexity: O(1)
  @inlinable
  internal mutating func _popLast() -> Element? {
    // FIXME: This needs to be in the stdlib.
    withUnsafeMutableBufferPointer { buffer, count in
      guard count > 0 else { return nil }
      count &-= 1
      return buffer.moveElement(from: count)
    }
  }
}

@available(SwiftStdlib 5.0, *)
extension OutputSpan where Element: ~Copyable {
  @_lifetime(source: copy source)
  @inlinable
  internal mutating func _append(moving source: inout InputSpan<Element>) {
    // FIXME: This needs to be in the stdlib.
    self.withUnsafeMutableBufferPointer { dst, dstCount in
      source.withUnsafeMutableBufferPointer { src, srcCount in
        let dstEnd = dstCount + srcCount
        let srcStart = src.count - srcCount
        precondition(dstEnd <= dst.count, "OutputSpan capacity overflow")
        let srcItems = src._extracting(uncheckedFrom: srcStart, to: src.count)
        dst
          ._extracting(uncheckedFrom: dstCount, to: dstEnd)
          .moveInitializeAll(fromContentsOf: srcItems)
        dstCount &+= srcCount
        srcCount = 0
      }
    }
  }
}


#endif
