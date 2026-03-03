//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Collections open source project
//
// Copyright (c) 2026 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
//
//===----------------------------------------------------------------------===//

#if compiler(>=6.3) && COLLECTIONS_UNSTABLE_NONCOPYABLE_KEYS

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
    assert(scale != self._keys._table.scale || capacity != self.capacity)
    assert(self.count <= capacity)
    assert(capacity <= _HTable.maximumCapacity(forScale: scale))
    assert(capacity >= _HTable.minimumCapacity(forScale: scale))
    if scale != 0, scale == self._keys._table.scale {
      // Large result with matching scales. We don't need to rehash or
      // reallocate, we just need to update the logical capacity.
      self._keys._table._capacity = capacity
      return
    }

    let newTable = _HTable(_capacity: capacity, scale: scale)
    var old = exchange(&self, with: Self(_table: newTable))
    guard old.count > 0 else {
      return
    }

    let sourceKeys = old._keys._members.unsafelyUnwrapped
    let sourceValues = old._values.unsafelyUnwrapped
    let targetKeys = self._keys._members.unsafelyUnwrapped
    let targetValues = self._values.unsafelyUnwrapped
    if self._keys._table.isSmall {
      self._keys._table.migrateItems_Small(from: &old._keys._table) { src, dst in
        (targetKeys + dst.offset).initialize(to: (sourceKeys + src.offset).move())
        (targetValues + dst.offset).initialize(to: (sourceValues + src.offset).move())
      }
    } else {
      let seed = self._keys._seed
      var srcKey = sourceKeys
      var srcValue = sourceValues
      self._keys._table.migrateItems_Large(
        from: &old._keys._table,
        selector: {
          srcKey = sourceKeys + $0.offset
          srcValue = sourceValues + $0.offset
          return srcKey.pointee._rawHashValue_temp(seed: seed)
        },
        hashGenerator: {
          targetKeys[$0.offset]._rawHashValue_temp(seed: seed)
        },
        swapper: {
          swap(&srcKey.pointee, &targetKeys[$0.offset])
          swap(&srcValue.pointee, &targetValues[$0.offset])
        },
        finalizer: {
          (targetKeys + $0.offset).initialize(to: srcKey.move())
          (targetValues + $0.offset).initialize(to: srcValue.move())
        }
      )
    }
  }
}

#endif
