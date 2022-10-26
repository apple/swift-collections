//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Collections open source project
//
// Copyright (c) 2022 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
//
//===----------------------------------------------------------------------===//

extension PersistentSet {
  @frozen
  public struct Index {
    @usableFromInline
    internal let _root: _UnmanagedNode

    @usableFromInline
    internal var _version: UInt

    @usableFromInline
    internal var _path: _UnsafePath

    @inlinable @inline(__always)
    internal init(
      _root: _UnmanagedNode, version: UInt, path: _UnsafePath
    ) {
      self._root = _root
      self._version = version
      self._path = path
    }
  }
}

#if swift(>=5.5)
extension PersistentSet.Index: @unchecked Sendable
where Element: Sendable {}
#endif

extension PersistentSet.Index: Equatable {
  @inlinable
  public static func ==(left: Self, right: Self) -> Bool {
    precondition(
      left._root == right._root && left._version == right._version,
      "Indices from different set values aren't comparable")
    return left._path == right._path
  }
}

extension PersistentSet.Index: Comparable {
  @inlinable
  public static func <(left: Self, right: Self) -> Bool {
    precondition(
      left._root == right._root && left._version == right._version,
      "Indices from different set values aren't comparable")
    return left._path < right._path
  }
}

extension PersistentSet.Index: Hashable {
  @inlinable
  public func hash(into hasher: inout Hasher) {
    hasher.combine(_path)
  }
}

extension PersistentSet.Index: CustomStringConvertible {
  // A textual representation of this instance.
  public var description: String {
    _path.description
  }
}

extension PersistentSet.Index: CustomDebugStringConvertible {
  /// A textual representation of this instance, suitable for debugging.
  public var debugDescription: String {
    description
  }
}

extension PersistentSet: Collection {
  @inlinable
  public var isEmpty: Bool {
    _root.count == 0
  }

  @inlinable
  public var count: Int {
    _root.count
  }

  public var startIndex: Index {
    var path = _UnsafePath(root: _root.raw)
    path.descendToLeftMostItem()
    return Index(_root: _root.unmanaged, version: _version, path: path)
  }

  @inlinable
  public var endIndex: Index {
    var path = _UnsafePath(root: _root.raw)
    path.selectEnd()
    return Index(_root: _root.unmanaged, version: _version, path: path)
  }

  @inlinable @inline(__always)
  internal func _isValid(_ i: Index) -> Bool {
    _root.isIdentical(to: i._root) && i._version == self._version
  }

  @inlinable @inline(__always)
  internal mutating func _invalidateIndices() {
    _version &+= 1
  }

  /// Accesses the key-value pair at the specified position.
  @inlinable
  public subscript(i: Index) -> Element {
    precondition(_isValid(i), "Invalid index")
    precondition(i._path.isOnItem, "Can't get element at endIndex")
    return _UnsafeHandle.read(i._path.node) {
      $0[item: i._path.currentItemSlot].key
    }
  }

  @inlinable
  public func formIndex(after i: inout Index) {
    precondition(_isValid(i), "Invalid index")
    guard i._path.findSuccessorItem(under: _root.raw) else {
      preconditionFailure("The end index has no successor")
    }
  }

  @inlinable @inline(__always)
  public func index(after i: Index) -> Index {
    var i = i
    formIndex(after: &i)
    return i
  }

  @inlinable
  public func distance(from start: Index, to end: Index) -> Int {
    precondition(_isValid(start) && _isValid(end), "Invalid index")
    return _root.raw.distance(.top, from: start._path, to: end._path)
  }

  @inlinable
  public func index(_ i: Index, offsetBy distance: Int) -> Index {
    precondition(_isValid(i), "Invalid index")
    var i = i
    let r = _root.raw.seek(.top, &i._path, offsetBy: distance)
    precondition(r, "Index offset out of bounds")
    return i
  }

  @inlinable
  public func index(
    _ i: Index, offsetBy distance: Int, limitedBy limit: Index
  ) -> Index? {
    precondition(_isValid(i), "Invalid index")
    precondition(_isValid(limit), "Invalid limit index")
    var i = i
    let (found, limited) = _root.raw.seek(
      .top, &i._path, offsetBy: distance, limitedBy: limit._path
    )
    if found { return i }
    precondition(limited, "Index offset out of bounds")
    return nil
  }

  @inlinable @inline(__always)
  public func _customIndexOfEquatableElement(
    _ element: Element
  ) -> Index?? {
    _index(of: element)
  }

  @inlinable @inline(__always)
  public func _customLastIndexOfEquatableElement(
    _ element: Element
  ) -> Index?? {
    _index(of: element)
  }

  @inlinable
  internal func _index(of element: Element) -> Index? {
    let hash = _Hash(element)
    guard let path = _root.path(to: element, hash) else { return nil }
    return Index(_root: _root.unmanaged, version: _version, path: path)
  }

  public func _failEarlyRangeCheck(
    _ index: Index, bounds: Range<Index>
  ) {
    precondition(_isValid(index))
  }

  public func _failEarlyRangeCheck(
    _ index: Index, bounds: ClosedRange<Index>
  ) {
    precondition(_isValid(index))
  }

  public func _failEarlyRangeCheck(
    _ range: Range<Index>, bounds: Range<Index>
  ) {
    precondition(_isValid(range.lowerBound) && _isValid(range.upperBound))
  }
}

#if false
// Note: Let's not do this. `BidirectionalCollection` would imply that
// the ordering of elements would be meaningful, which isn't true for
// `PersistentSet`.
extension PersistentSet: BidirectionalCollection {
  /// Replaces the given index with its predecessor.
  ///
  /// - Parameter i: A valid index of the collection.
  ///     `i` must be greater than `startIndex`.
  ///
  /// - Complexity: O(1)
  @inlinable
  public func formIndex(before i: inout Index) {
    precondition(_isValid(i), "Invalid index")
    guard i._path.findPredecessorItem(under: _root.raw) else {
      preconditionFailure("The start index has no predecessor")
    }
  }

  /// Returns the position immediately before the given index.
  ///
  /// - Parameter i: A valid index of the collection.
  ///    `i` must be greater than `startIndex`.
  ///
  /// - Complexity: O(1)
  @inlinable @inline(__always)
  public func index(before i: Index) -> Index {
    var i = i
    formIndex(before: &i)
    return i
  }
}
#endif
