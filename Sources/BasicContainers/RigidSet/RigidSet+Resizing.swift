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
extension RigidSet where Element: ~Copyable {
  @inlinable
  public mutating func reallocate(capacity newCapacity: Int) {
    precondition(newCapacity >= count, "RigidSet capacity overflow")
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
    assert(scale != self._table.scale || capacity != self.capacity)
    assert(self.count <= capacity)
    assert(capacity <= _HTable.maximumCapacity(forScale: scale))
    assert(capacity >= _HTable.minimumCapacity(forScale: scale))
    if scale != 0, scale == self._table.scale {
      // Large result with matching scales. We don't need to rehash or
      // reallocate, we just need to update the logical capacity.
      self._table._capacity = capacity
      return
    }
    
    let newTable = _HTable(_capacity: capacity, scale: scale)
    var old = exchange(&self, with: Self(_table: newTable))
    guard old.count > 0 else {
      return
    }
    
    let source = old._members.unsafelyUnwrapped
    let target = self._members.unsafelyUnwrapped
    if self._table.isSmall {
      self._table.migrateItems_Small(from: &old._table) { src, dst in
        (target + dst.offset).initialize(to: (source + src.offset).move())
      }
      return
    }
    
    let seed = self._seed
    var src = source
    self._table.migrateItems_Large(
      from: &old._table,
      selector: {
        src = source + $0.offset
        return src.pointee._rawHashValue_temp(seed: seed)
      },
      hashGenerator: {
        target[$0.offset]._rawHashValue_temp(seed: seed)
      },
      swapper: {
        swap(&src.pointee, &target[$0.offset])
      },
      finalizer: {
        (target + $0.offset).initialize(to: src.move())
      }
    )
  }
}

#endif
