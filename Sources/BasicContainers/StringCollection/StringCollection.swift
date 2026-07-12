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
/// Blocks support efficient appends and removals at the ends
/// (except prepending).
///
/// Specifying or retaining element capacity is not supported.
@available(macOS 15.0, *)
public struct StringCollection: Hashable, Sendable {
  /// Ensures that the instance has unique ownership of its storage before
  /// mutation.
  ///
  /// If the backing storage is shared with other copies,
  /// this method clones it so that subsequent mutations do not affect other
  /// values.
  /// This underpins the type's copy-on-write semantics.
  mutating func ensureUnique() {
    if !isKnownUniquelyReferenced(&self.inner) {
      self.inner = .init(cloning: self.inner)
    }
  }

  public init() {
    self.inner = .init()
  }
  /// Creates a block with the individually-given strings (in order).
  ///
  /// - Parameter string: The strings to store.
  public init<each S: StringProtocol>(_ string: repeat each S) {
    self.init()
    for str in repeat each string {
      self.inner.append(String(str))
    }
  }

  /// The elements stored to enable copy-on-write.
  var inner: ClassyEmbeddedStringStorage
}

// MARK: - Conformances

@available(macOS 15.0, *)
extension StringCollection: BidirectionalCollection,
  RangeReplaceableCollection
{
  public var count: Int { self.inner.count }

  public func _customContainsEquatableElement(_ element: Element) -> Bool? {
    return self.inner._customContainsEquatableElement(element)
  }

  public func _customIndexOfEquatableElement(_ element: Element) -> Index?? {
    return self.inner._customIndexOfEquatableElement(element)
  }
  public func _customLastIndexOfEquatableElement(_ element: Element)
    -> Index??
  {
    return self.inner._customLastIndexOfEquatableElement(element)
  }

  public mutating func _customRemoveLast() -> Element? {
    self.ensureUnique()
    return self.inner._customRemoveLast()
  }
  public mutating func _customRemoveLast(_ n: Int) -> Bool {
    self.ensureUnique()
    return self.inner._customRemoveLast(n)
  }

  public var endIndex: Index { self.inner.endIndex }

  public func index(after i: Index) -> Index {
    return self.inner.index(after: i)
  }
  public func index(before i: Index) -> Index {
    return self.inner.index(before: i)
  }

  public var isEmpty: Bool { self.inner.isEmpty }

  public var startIndex: Index { self.inner.startIndex }

  public subscript(position: Int) -> String {
    return self.inner[position]
  }

  public mutating func removeAll(keepingCapacity keepCapacity: Bool = false) {
    self.ensureUnique()
    self.inner.removeAll(keepingCapacity: keepCapacity)
  }

  public mutating func replaceSubrange<S: StringProtocol & Sendable>(
    _ subrange: some RangeExpression<Index>,
    with newElements: some Sequence<S>
  ) {
    self.ensureUnique()
    self.inner.replaceSubrange(subrange, with: newElements)
  }
}
