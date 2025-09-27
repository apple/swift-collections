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

#if COLLECTIONS_SINGLE_MODULE
import Collections
#else
import BasicContainers
import ContainersPreview
#endif

#if compiler(>=6.2) && COLLECTIONS_UNSTABLE_CONTAINERS_PREVIEW
/// A container type with user-defined contents and storage chunks.
/// Useful for testing.
@available(SwiftStdlib 5.0, *)
public struct StaccatoContainer<Element: ~Copyable>: ~Copyable {
  internal let _contents: RigidArray<Element>
  internal let _spanCounts: [Int]
  internal let _modulus: Int

  public init(contents: consuming RigidArray<Element>, spanCounts: [Int]) {
    // FIXME: Make this take an arbitrary consumable container
    precondition(!spanCounts.isEmpty && spanCounts.allSatisfy { $0 > 0 })
    self._contents = contents
    self._spanCounts = spanCounts
    self._modulus = spanCounts.reduce(into: 0, { $0 += $1 })
  }
}

@available(SwiftStdlib 5.0, *)
public struct _StaccatoBorrowIterator<Element: ~Copyable>: BorrowIteratorProtocol, ~Escapable {
  internal let _contents: Span<Element>
  internal let _spanCounts: [Int]
  internal let _modulus: Int
  internal var _offset: Int

  @_lifetime(copy contents)
  internal init(contents: Span<Element>, spanCounts: [Int]) {
    self._contents = contents
    self._spanCounts = spanCounts
    self._modulus = spanCounts.reduce(into: 0, { $0 += $1 })
    self._offset = 0
  }

  func _spanCoordinates(atOffset offset: Int) -> (spanIndex: Int, spanOffset: Int) {
    precondition(offset >= 0 && offset <= _contents.count)
    var remainder = offset % _modulus
    var i = 0
    while i < _spanCounts.count {
      let c = _spanCounts[i]
      if remainder < c { break }
      remainder -= c
      i += 1
    }
    return (i, remainder)
  }

  @_lifetime(copy self)
  public mutating func nextSpan(maximumCount: Int?) -> Span<Element> {
    let (spanIndex, spanOffset) = _spanCoordinates(atOffset: _offset)
    let c = _spanCounts[spanIndex] - spanOffset
    let startOffset = _offset
    let endOffset = Swift.min(startOffset + c, _contents.count)
    _offset = endOffset
    return _contents.extracting(startOffset ..< endOffset)

  }
}


@available(SwiftStdlib 5.0, *)
extension StaccatoContainer: Container where Element: ~Copyable {
  public typealias BorrowIterator = _StaccatoBorrowIterator<Element> // FIXME rdar://150240032
  public var isEmpty: Bool { _contents.isEmpty }
  public var count: Int { _contents.count }

  public func startBorrowIteration() -> BorrowIterator {
    BorrowIterator(contents: _contents.span, spanCounts: _spanCounts)
  }
}
#endif
