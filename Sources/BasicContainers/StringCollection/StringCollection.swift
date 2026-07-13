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

// MARK: Primary Definition

/// A contiguous,
/// copy-on-write collection of strings optimized for many small values.
///
/// Elements are stored in a compact,
/// normalized scalar representation inside a *single* backing buffer.
///
/// Specifying or retaining element capacity is not supported.
public struct StringCollection: @unchecked Sendable {
  /// Copy-on-write access to the actual elements.
  private var storage: Storage

  public init<S: StringProtocol>(_ elements: some Sequence<S>) {
    let empty = Storage.State()
    let state = Storage.State(
      clone: empty,
      replacing: empty.startIndex..<empty.endIndex,
      with: elements
    )
    self.storage = .init(state)
  }

  /// Create a collection with the given strings, in order.
  public init<each S: StringProtocol>(_ string: repeat each S) {
    // The Swift compiler won't (currently) use this initializer to
    // implement the default initializer.
    var strings = [String]()
    for s in repeat each string {
      strings.append(String(s))
    }
    self.init(strings)
  }
}

// MARK: - Collection conformances

extension StringCollection: BidirectionalCollection, RangeReplaceableCollection
{
  public var count: Int { self.storage.state.count }

  public func _customContainsEquatableElement(_ element: Element) -> Bool? {
    return self.storage.state.contains(element)
  }
  public func _customIndexOfEquatableElement(_ element: Element) -> Index?? {
    return self.storage.state.firstIndex(of: element)
  }
  public func _customLastIndexOfEquatableElement(_ element: Element) -> Index??
  {
    return self.storage.state.lastIndex(of: element)
  }
  public mutating func _customRemoveLast() -> Element? {
    defer { _ = self._customRemoveLast(1) }

    return self.last
  }
  public mutating func _customRemoveLast(_ n: Int) -> Bool {
    let suffixCutoff = self.index(self.endIndex, offsetBy: -n)
    self.replaceSubrange(suffixCutoff..., with: EmptyCollection())
    return true
  }

  public var endIndex: Index { self.storage.state.endIndex }

  public func index(after i: Index) -> Index {
    return self.storage.state.index(after: i)
  }
  public func index(before i: Index) -> Index {
    return self.storage.state.index(before: i)
  }

  public init() {
    self.init(EmptyCollection<String>())
  }
  public init(repeating repeatedValue: String, count: Int) {
    self.init(repeatElement(repeatedValue, count: count))
  }

  public var isEmpty: Bool { self.storage.state.isEmpty }

  public mutating func replaceSubrange<S: StringProtocol>(
    _ subrange: some RangeExpression<Index>,
    with newElements: some Sequence<S>
  ) {
    if isKnownUniquelyReferenced(&self.storage) {
      self.storage.state.replaceSubrange(subrange, with: newElements)
    } else {
      let newState = Self.Storage.State(
        clone: self.storage.state,
        replacing: subrange.relative(to: self),
        with: newElements
      )
      let newStorage = Self.Storage(newState)
      self.storage = newStorage
    }
  }

  public var startIndex: Index { self.storage.state.startIndex }

  public subscript(position: Int) -> String {
    return self.storage.state[position]
  }
}

// MARK: - Comparison conformances

extension StringCollection: Hashable {
  public static func == (lhs: Self, rhs: Self) -> Bool {
    return lhs.storage.state.innerElements
      == rhs.storage.state.innerElements
  }

  public func hash(into hasher: inout Hasher) {
    self.storage.state.innerElements.hash(into: &hasher)
  }
}
