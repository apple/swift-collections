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

#if compiler(>=6.4) && UnstableHashedContainers

@available(SwiftStdlib 5.0, *)
extension RigidDictionary where Key: ~Copyable, Value: ~Copyable {
  @inlinable
  public mutating func reallocate(capacity newCapacity: Int) {
    precondition(newCapacity >= count, "RigidDictionary capacity overflow")
    guard newCapacity != capacity else { return }
    let newScale = _HTable.minimumScale(forCapacity: newCapacity)
    self._resize(scale: newScale, capacity: newCapacity)
  }
  
  @inlinable
  public mutating func reserveCapacity(_ n: Int) {
    guard capacity < n else { return }
    reallocate(capacity: n)
  }

  @inlinable
  package mutating func _resize(
    scale: UInt8,
    capacity: Int,
  ) {
    assert(unsafe scale != self._keys._table.scale || capacity != self.capacity)
    assert(self.count <= capacity)
    assert(capacity <= _HTable.maximumCapacity(forScale: scale))
    assert(capacity >= _HTable.minimumCapacity(forScale: scale))
    if scale != 0, unsafe scale == self._keys._table.scale {
      // Large result with matching scales. We don't need to rehash or
      // reallocate, we just need to update the logical capacity.
      unsafe self._keys._table._capacity = capacity
      return
    }

    let newTable = _HTable(_capacity: capacity, scale: scale)
    var old = exchange(&self, with: Self(_table: newTable))
    guard old.count > 0 else {
      return
    }

    let sourceKeys = unsafe old._keys._members.unsafelyUnwrapped
    let sourceValues = unsafe old._values
    let targetKeys = unsafe self._keys._members.unsafelyUnwrapped
    let targetValues = unsafe self._values
    if self._keys._isSmall {
      unsafe self._keys._table.migrateItems_Small(from: &old._keys._table) { src, dst in
        unsafe (targetKeys + dst.offset).initialize(to: (sourceKeys + src.offset).move())
        unsafe (targetValues + dst.offset).initialize(to: (sourceValues + src.offset).move())
      }
    } else {
      let seed = self._keys._seed
      var srcKey = unsafe sourceKeys
      var srcValue = unsafe sourceValues
      unsafe self._keys._table.migrateItems_Large(
        from: &old._keys._table,
        selector: {
          unsafe srcKey = sourceKeys + $0.offset
          unsafe srcValue = sourceValues + $0.offset
          return unsafe srcKey.pointee._rawHashValue(seed: seed)
        },
        hashGenerator: {
          unsafe targetKeys[$0.offset]._rawHashValue(seed: seed)
        },
        swapper: {
          unsafe swap(&srcKey.pointee, &targetKeys[$0.offset])
          unsafe swap(&srcValue.pointee, &targetValues[$0.offset])
        },
        finalizer: {
          unsafe (targetKeys + $0.offset).initialize(to: srcKey.move())
          unsafe (targetValues + $0.offset).initialize(to: srcValue.move())
        }
      )
    }
  }
}

#endif
