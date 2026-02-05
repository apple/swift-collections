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
  internal let _params: _StaccatoParameters

  public init(contents: consuming RigidArray<Element>, spanCounts: [Int]) {
    // FIXME: Make this take an arbitrary consumable container
    self._contents = contents
    self._params = _StaccatoParameters(
      count: _contents.count, spanCounts: spanCounts)
  }
}

@available(SwiftStdlib 5.0, *)
extension StaccatoContainer {
  public init(contents: Array<Element>, spanCounts: [Int]) {
    self._contents = RigidArray(copying: contents)
    self._params = _StaccatoParameters(
      count: _contents.count, spanCounts: spanCounts)
  }
}

@available(SwiftStdlib 5.0, *)
package struct _StaccatoParameters {
  internal let _count: Int
  internal let _spanCounts: [Int]
  internal let _modulus: Int

  internal init(count: Int, spanCounts: [Int]) {
    precondition(!spanCounts.isEmpty && spanCounts.allSatisfy { $0 > 0 })
    self._count = count
    self._spanCounts = spanCounts
    self._modulus = spanCounts.reduce(into: 0, { $0 += $1 })
  }

  internal func endOffset(
    fromOffset startOffset: Int,
    maximumCount: Int
  ) -> Int {
    precondition(maximumCount > 0)
    precondition(startOffset >= 0 && startOffset <= _count)
    var cycleOffset = startOffset % _modulus
    var i = 0
    while i < _spanCounts.count {
      let c = _spanCounts[i]
      if cycleOffset < c { break }
      cycleOffset -= c
      i += 1
    }
    let c = _spanCounts[i]
    return Swift.min(_count, startOffset + Swift.min(c - cycleOffset, maximumCount))
  }
}

@available(SwiftStdlib 5.0, *)
public struct _StaccatoBorrowingIterator<Element: ~Copyable>: BorrowingIteratorProtocol, ~Escapable {
  internal let _contents: Span<Element>
  internal let _params: _StaccatoParameters
  internal var _offset: Int

  @_lifetime(copy contents)
  internal init(contents: Span<Element>, params: _StaccatoParameters) {
    self._contents = contents
    self._params = params
    self._offset = 0
  }

  @_lifetime(copy self)
  public mutating func nextSpan(maximumCount: Int) -> Span<Element> {
    let endOffset = _params.endOffset(fromOffset: _offset, maximumCount: maximumCount)
    let startOffset = _offset
    _offset = endOffset
    return _contents.extracting(startOffset ..< endOffset)
  }
}

@available(SwiftStdlib 5.0, *)
public struct _StaccatoIndex: Comparable {
  var _offset: Int
  init(_offset: Int) {
    self._offset = _offset
  }
  
  public static func ==(left: Self, right: Self) -> Bool {
    left._offset == right._offset
  }
  
  public static func <(left: Self, right: Self) -> Bool {
    left._offset < right._offset
  }
}

@available(SwiftStdlib 5.0, *)
extension StaccatoContainer: BorrowingSequence where Element: ~Copyable {
  public typealias BorrowingIterator = _StaccatoBorrowingIterator<Element> // FIXME rdar://150240032
  
  public var estimatedCount: EstimatedCount {
    .exactly(count)
  }

  public func makeBorrowingIterator() -> BorrowingIterator {
    BorrowingIterator(contents: _contents.span, params: _params)
  }
}

@available(SwiftStdlib 5.0, *)
extension StaccatoContainer: Container where Element: ~Copyable {
  public typealias Index = _StaccatoIndex
  
  public var isEmpty: Bool { _contents.isEmpty }
  public var count: Int { _contents.count }
  
  
  package func _isValid(_ index: Index) -> Bool {
    index._offset >= 0 && index._offset <= count
  }

  public var startIndex: Index { Index(_offset: 0) }
  public var endIndex: Index { Index(_offset: _contents.count) }
  
  public func index(after index: Index) -> Index {
    precondition(index._offset >= 0 && index._offset < count)
    return Index(_offset: index._offset + 1)
  }
  
  public func index(before index: Index) -> Index {
    precondition(index._offset > 0 && index._offset <= count)
    return Index(_offset: index._offset - 1)
  }
  
  public func index(_ index: Index, offsetBy n: Int) -> Index {
    precondition(index._offset >= 0 && index._offset <= count)
    let j = index._offset + n
    precondition(j >= 0 && j <= count)
    return Index(_offset: j)
  }
  
  public func distance(from start: Index, to end: Index) -> Int {
    precondition(_isValid(start) && _isValid(end))
    return end._offset - start._offset
  }
  
  public func formIndex(
    _ index: inout Index, offsetBy n: inout Int, limitedBy limit: Index
  ) {
    precondition(_isValid(index) && _isValid(limit))
    index._offset._advance(by: &n, limitedBy: limit._offset)
    precondition(_isValid(index))
  }
  
  @_lifetime(borrow self)
  public func nextSpan(
    after index: inout Index, maximumCount: Int
  ) -> Span<Element> {
    precondition(_isValid(index))
    let startOffset = index._offset
    let endOffset = _params.endOffset(fromOffset: index._offset, maximumCount: maximumCount)
    print("\(startOffset) .-> \(endOffset)")
    index._offset = endOffset
    return _contents.span.extracting(startOffset ..< endOffset)
  }
}
#endif
