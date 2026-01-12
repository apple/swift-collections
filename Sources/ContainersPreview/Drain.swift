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
public protocol Drain<Element>: Producer, ~Copyable, ~Escapable {
  @_lifetime(&self)
  mutating func nextSpan(maximumCount: Int?) -> InputSpan<Element>
}

@available(SwiftStdlib 5.0, *)
extension Drain where Self: ~Copyable & ~Escapable {
  @_lifetime(target: copy target)
  mutating func drain(filling target: inout OutputSpan<Element>) {
    while target.freeCapacity > 0 {
      var source = self.nextSpan(maximumCount: target.freeCapacity)
      target._append(moving: &source)
    }
  }
}

@available(SwiftStdlib 5.0, *)
extension OutputSpan where Element: ~Copyable {
  @_lifetime(source: copy source)
  mutating func _append(moving source: inout InputSpan<Element>) {
    self.withUnsafeMutableBufferPointer { dst, dstCount in
      source.withUnsafeMutableBufferPointer { src, srcCount in
        precondition(srcCount <= dstCount, "OutputSpan capacity overflow")
        dst
          .extracting(dstCount ..< dstCount + srcCount)
          .moveInitializeAll(fromContentsOf: src._extracting(last: srcCount))
      }
    }
  }
}

#endif
