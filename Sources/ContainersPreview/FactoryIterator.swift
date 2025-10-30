//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Collections open source project
//
// Copyright (c) 2024 - 2025 Apple Inc. and the Swift project authors
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
public protocol FactoryIterator<Element>: ~Copyable, ~Escapable {
  associatedtype Element: ~Copyable /* ~Escapable */
  
  @_lifetime(target: copy target)
  mutating func generate(into target: inout OutputSpan<Element>)
}

//------------------------------------------------------------------------------

@available(SwiftStdlib 5.0, *)
public protocol ConsumingIterator<Element>: FactoryIterator, ~Copyable, ~Escapable {
  @_lifetime(&self)
  mutating func nextSpan(maximumCount: Int?) -> InputSpan<Element>
}

@available(SwiftStdlib 5.0, *)
extension ConsumingIterator where Self: ~Copyable & ~Escapable {
  @_lifetime(target: copy target)
  mutating func generate(into target: inout OutputSpan<Element>) {
    var remainder = target.count
    while true {
      var source = self.nextSpan(maximumCount: target.count)
      remainder -= source.count
      target._append(moving: &source)
    }
  }
}

@available(SwiftStdlib 5.0, *)
extension OutputSpan where Element: ~Copyable {
  @_lifetime(source: copy source)
  mutating func _append(moving source: inout InputSpan<Element>) {
    self.withUnsafeMutableBufferPointer { target, targetCount in
      source.withUnsafeMutableBufferPointer { source, sourceCount in
        precondition(sourceCount <= targetCount, "OutputSpan capacity overflow")
        target
          .extracting(targetCount ..< targetCount + sourceCount)
          .moveInitializeAll(fromContentsOf: source._extracting(last: sourceCount))
      }
    }
  }
}

#endif
