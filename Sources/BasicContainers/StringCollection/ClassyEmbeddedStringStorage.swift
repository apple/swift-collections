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

import Foundation
import Synchronization

// MARK: Primary Definition

/// A compact, bidirectional collection of `String` values stored in a
/// single contiguous buffer.
///
/// This type is a class wrapping an internal value-type collection,
/// and will be wrapped in turn by the public collection value-type.
@available(macOS 15.0, *)
final class ClassyEmbeddedStringStorage: Hashable, Sendable {
  static func == (
    lhs: ClassyEmbeddedStringStorage,
    rhs: ClassyEmbeddedStringStorage
  ) -> Bool {
    let leftCopy = lhs.storageState.withLock(\.self)
    let rightCopy = rhs.storageState.withLock(\.self)
    guard leftCopy.logicalCount == rightCopy.logicalCount else {
      return false
    }

    return leftCopy.bulk.elementsEqual(rightCopy.bulk)
  }

  func hash(into hasher: inout Hasher) {
    self.storageState.withLockIfAvailable {
      $0.hash(into: &hasher)
    }
  }

  convenience init(cloning original: ClassyEmbeddedStringStorage) {
    let originalCopy = original.storageState.withLock(\.self)
    self.init(valueStorage: originalCopy)
  }
  init(valueStorage: EmbeddedStringStorage) {
    self.storageState = Mutex(valueStorage)
  }

  private let storageState: Mutex<EmbeddedStringStorage>
}

// MARK: - Collection Conformance

@available(macOS 15.0, *)
extension ClassyEmbeddedStringStorage: BidirectionalCollection,
  RangeReplaceableCollection
{
  var count: Int { self.storageState.withLock(\.count) }

  func _customContainsEquatableElement(_ element: Element) -> Bool? {
    self.storageState.withLock {
      return $0._customContainsEquatableElement(element)
    }
  }

  func _customIndexOfEquatableElement(_ element: Element) -> Index?? {
    self.storageState.withLock {
      return $0._customIndexOfEquatableElement(element)
    }
  }
  func _customLastIndexOfEquatableElement(_ element: Element) -> Index?? {
    self.storageState.withLock {
      return $0._customLastIndexOfEquatableElement(element)
    }
  }

  func _customRemoveLast() -> Element? {
    self.storageState.withLock { return $0._customRemoveLast() }
  }
  func _customRemoveLast(_ n: Int) -> Bool {
    self.storageState.withLock { return $0._customRemoveLast(n) }
  }

  var endIndex: Index { self.storageState.withLock(\.endIndex) }

  func index(after i: Index) -> Index {
    self.storageState.withLock { return $0.index(after: i) }
  }
  func index(before i: Index) -> Index {
    self.storageState.withLock { return $0.index(before: i) }
  }

  convenience init() {
    self.init(valueStorage: .init())
  }

  var isEmpty: Bool { self.storageState.withLock(\.isEmpty) }

  var startIndex: Index { self.storageState.withLock(\.startIndex) }

  subscript(position: Int) -> String {
    self.storageState.withLock { return $0[position] }
  }

  func removeAll(keepingCapacity keepCapacity: Bool = false) {
    self.storageState.withLock {
      $0.removeAll(keepingCapacity: keepCapacity)
    }
  }

  func replaceSubrange<S: StringProtocol & Sendable>(
    _ subrange: some RangeExpression<Index>,
    with newElements: some Sequence<S>
  ) {
    self.storageState.withLock {
      $0.replaceSubrange(subrange, with: newElements)
    }
  }
}
