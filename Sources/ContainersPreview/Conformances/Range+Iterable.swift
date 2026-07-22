//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Collections open source project
//
// Copyright (c) 2026 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
//
// SPDX-License-Identifier: Apache-2.0 WITH Swift-exception
//
//===----------------------------------------------------------------------===//

#if compiler(>=6.4) && UnstableContainersPreview

@available(SwiftStdlib 6.4, *)
extension Range: Iterable_
where Bound: Strideable, Bound.Stride: SignedInteger
{
  public typealias Element_ = Bound

  @frozen
  public struct BorrowingIterator_: BorrowingIteratorProtocol_, ~Copyable {
    @usableFromInline
    internal var _current: InlineArray<1, Bound>

    @usableFromInline
    internal var _end: Bound

    @usableFromInline
    internal var _progress: Bool

    @inlinable
    internal init(_ base: Range<Bound>) {
      self._current = .init(repeating: base.lowerBound)
      self._end = base.upperBound
      self._progress = false
    }
    @inlinable
    @_lifetime(&self)
    public mutating func nextSpan_(maxCount: Int) -> Span<Bound> {
      if _progress {
        _current[0] = _current[0].advanced(by: 1)
      }
      guard _current[0] < _end else {
        _progress = false
        return .init()
      }
      _progress = true
      return _current.span
    }
  }

  @inlinable
  public var underestimatedCount_: Int {
    guard let count = Int(exactly: lowerBound.distance(to: upperBound)) else {
      return 0
    }
    return count
  }

  @inlinable
  public func makeBorrowingIterator_() -> BorrowingIterator_ {
    BorrowingIterator_(self)
  }
}

#endif
