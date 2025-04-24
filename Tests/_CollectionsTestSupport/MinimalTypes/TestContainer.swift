//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2024 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
// See https://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//
//===----------------------------------------------------------------------===//

import Future

public struct TestContainer<Element: ~Copyable>: ~Copyable {
  internal let _contents: RigidArray<Element>
  internal let _spanCounts: [Int]

  public init(contents: consuming RigidArray<Element>, spanCounts: [Int]) {
    precondition(spanCounts.allSatisfy { $0 > 0 })
    self._contents = contents
    self._spanCounts = spanCounts
  }
}

extension TestContainer where Element: ~Copyable {
  public struct Index: Comparable {
    internal var _offset: Int

    internal init(_offset: Int) {
      self._offset = _offset
    }

    public static func == (left: Self, right: Self) -> Bool { left._offset == right._offset }
    public static func < (left: Self, right: Self) -> Bool { left._offset < right._offset }
  }

  func _spanCoordinates(atOffset offset: Int) -> (spanIndex: Int, spanOffset: Int) {
    precondition(offset >= 0 && offset <= _contents.count)
    let modulus = _spanCounts.reduce(into: 0, { $0 += $1 })
    var remainder = offset % modulus
    for i in 0 ..< _spanCounts.count {
      let c = _spanCounts[i]
      if remainder < c {
        return (i, remainder)
      }
      remainder -= c
    }
    return (_spanCounts.count, 0)
  }
}

extension TestContainer where Element: ~Copyable {
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

@available(SwiftCompatibilitySpan 5.0, *)
extension TestContainer: Container where Element: ~Copyable {
  public func formIndex(_ i: inout Index, offsetBy distance: inout Int, limitedBy limit: Index) {
    precondition(i >= startIndex && i <= endIndex)
    _contents.formIndex(&i._offset, offsetBy: &distance, limitedBy: limit._offset)
  }

  @lifetime(borrow self)
  public func borrowElement(at index: Index) -> Future.Borrow<Element> {
    precondition(index >= startIndex && index < endIndex)
    return _contents.borrowElement(at: index._offset)
  }

  @lifetime(borrow self)
  public func nextSpan(after index: inout Index) -> Span<Element> {
    precondition(index >= startIndex && index <= endIndex)
    let (spanIndex, spanOffset) = _spanCoordinates(atOffset: index._offset)
    let span = _contents.span
    guard spanIndex < _spanCounts.count else { return span._extracting(last: 0) }
    let c = _spanCounts[spanIndex] - spanOffset
    index._offset += c
    return span._extracting(index._offset ..< index._offset + c)
  }
}
