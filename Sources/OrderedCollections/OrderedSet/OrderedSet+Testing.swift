//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Collections open source project
//
// Copyright (c) 2021 - 2026 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
//
// SPDX-License-Identifier: Apache-2.0 WITH Swift-exception
//
//===----------------------------------------------------------------------===//

#if !COLLECTIONS_SINGLE_MODULE
import InternalCollectionsUtilities
#endif

extension OrderedSet._UnstableInternals {
  package var capacity: Int { base._capacity }
  package var minimumCapacity: Int { base._minimumCapacity }
  package var scale: Int { base._scale }
  package var reservedScale: Int { base._reservedScale }
  package var bias: Int { base._bias }

  public static var isConsistencyCheckingEnabled: Bool {
    _isCollectionsInternalCheckingEnabled
  }
}

extension OrderedSet {
  @_alwaysEmitIntoClient
  package static var _minimumScale: Int {
    _HashTable.minimumScale
  }

  @_alwaysEmitIntoClient
  package static func _minimumCapacity(forScale scale: Int) -> Int {
    _HashTable.minimumCapacity(forScale: scale)
  }

  @_alwaysEmitIntoClient
  package static func _maximumCapacity(forScale scale: Int) -> Int {
    _HashTable.maximumCapacity(forScale: scale)
  }

  @_alwaysEmitIntoClient
  package static func _scale(forCapacity capacity: Int) -> Int {
    _HashTable.scale(forCapacity: capacity)
  }

  @_alwaysEmitIntoClient
  package static func _biasRange(scale: Int) -> Range<Int> {
    guard scale != 0 else { return Range(uncheckedBounds: (0, 1)) }
    return Range(uncheckedBounds: (0, (1 &<< scale) - 1))
  }
}

extension OrderedSet._UnstableInternals {
  @_alwaysEmitIntoClient
  package var hasHashTable: Bool { base._table != nil }

  @_alwaysEmitIntoClient
  package var hashTableIdentity: ObjectIdentifier? {
    guard let storage = base.__storage else { return nil }
    return ObjectIdentifier(storage)
  }

  package var hashTableContents: [Int?] {
    guard let table = base._table else { return [] }
    return table.read { hashTable in
      hashTable.debugContents()
    }
  }

  @_alwaysEmitIntoClient
  package mutating func _regenerateHashTable(bias: Int) {
    base._ensureUnique()
    let new = base._table!.copy()
    base._table!.read { source in
      new.update { target in
        target.bias = bias
        var it = source.bucketIterator(startingAt: _Bucket(offset: 0))
        repeat {
          target[it.currentBucket] = it.currentValue
          it.advance()
        } while it.currentBucket.offset != 0
      }
    }
    base._table = new
    base._checkInvariants()
  }

  @_alwaysEmitIntoClient
  package mutating func reserveCapacity(
    _ minimumCapacity: Int,
    persistent: Bool
  ) {
    base._reserveCapacity(minimumCapacity, persistent: persistent)
    base._checkInvariants()
  }
}

extension OrderedSet {
  package init(
    _scale scale: Int,
    bias: Int,
    contents: some Sequence<Element>
  ) {
    let contents = ContiguousArray(contents)
    precondition(scale >= _HashTable.scale(forCapacity: contents.count))
    precondition(scale <= _HashTable.maximumScale)
    precondition(bias >= 0 && Self._biasRange(scale: scale).contains(bias))
    precondition(scale >= _HashTable.minimumScale || bias == 0)
    let table = _HashTable(scale: Swift.max(scale, _HashTable.minimumScale))
    table.header.bias = bias
    let (success, index) = table.update { hashTable in
      hashTable.fill(untilFirstDuplicateIn: contents)
    }
    precondition(success, "Duplicate element at index \(index)")
    self.init(
      _uniqueElements: contents,
      scale < _HashTable.minimumScale ? nil : table)
    precondition(self._scale == scale)
    precondition(self._bias == bias)
    _checkInvariants()
  }
}
