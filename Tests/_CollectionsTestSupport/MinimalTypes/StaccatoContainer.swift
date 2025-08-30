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
import ContainersPreview
#endif

#if compiler(>=6.2) && COLLECTIONS_UNSTABLE_CONTAINERS_PREVIEW
/// A container type with user-defined contents and storage chunks.
/// Useful for testing.
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

public struct _StaccatoContainerIndex: Comparable {
  internal var _offset: Int

  internal init(_offset: Int) {
    self._offset = _offset
  }

  public static func == (left: Self, right: Self) -> Bool { left._offset == right._offset }
  public static func < (left: Self, right: Self) -> Bool { left._offset < right._offset }
}

extension StaccatoContainer where Element: ~Copyable {
  public typealias Index = _StaccatoContainerIndex // rdar://150240032

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
}

extension StaccatoContainer where Element: ~Copyable {
  public var isEmpty: Bool { _contents.isEmpty }
  public var count: Int { _contents.count }
  public var startIndex: Index { Index(_offset: 0) }
  public var endIndex: Index { Index(_offset: _contents.count) }
  public func index(after index: Index) -> Index {
    precondition(index >= startIndex && index < endIndex)
    return Index(_offset: index._offset + 1)
  }
  public func formIndex(after i: inout Index) {
    i = index(after: i)
  }
  public func index(_ index: Index, offsetBy n: Int) -> Index {
    precondition(index._offset >= 0 && index._offset <= _contents.count)
    let offset = index._offset + n
    precondition(offset >= 0 && offset <= _contents.count)
    return Index(_offset: offset)
  }

  public func distance(from start: Index, to end: Index) -> Int {
    precondition(start >= startIndex && start <= endIndex)
    precondition(end >= startIndex && end <= endIndex)
    return end._offset - start._offset
  }
}

@available(SwiftStdlib 6.2, *)
extension StaccatoContainer: Container where Element: ~Copyable {
  public func formIndex(_ i: inout Index, offsetBy distance: inout Int, limitedBy limit: Index) {
    precondition(i >= startIndex && i <= endIndex)
    _contents.formIndex(&i._offset, offsetBy: &distance, limitedBy: limit._offset)
  }

  @lifetime(borrow self)
  public func borrowElement(at index: Index) -> Future.Borrow<Element> {
    precondition(index >= startIndex && index < endIndex, "Index out of bounds")
    return _contents.borrowElement(at: index._offset)
  }

  @lifetime(borrow self)
  public func nextSpan(after index: inout Index) -> Span<Element> {
    precondition(index >= startIndex && index <= endIndex)
    let span = _contents.span
    let (spanIndex, spanOffset) = _spanCoordinates(atOffset: index._offset)
    let c = _spanCounts[spanIndex] - spanOffset
    let startOffset = index._offset
    let endOffset = Swift.min(startOffset + c, span.count)
    index._offset = endOffset
    return span._extracting(startOffset ..< endOffset)
  }
}
#endif
