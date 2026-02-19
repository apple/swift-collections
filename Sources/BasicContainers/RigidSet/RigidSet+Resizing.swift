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
    capacity: Int
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

    var old = exchange(
      &self,
      with: Self(_table: _HTable(_capacity: capacity, scale: scale)))
    guard old.count > 0 else {
      return
    }

    if scale == 0 {
      // Small result. Let's reverse the order of members, to emphasize
      // that this is not an ordered container.
      let c = old.count
      self._table._count = c
      self._table._totalProbeLength = c * (c + 1) / 2
      let start = self._members.unsafelyUnwrapped
      var dst = start + c
      old._consumeAll { src in
        var i = 0
        while i < src.count {
          precondition(dst > start, "Internal inconsistency")
          dst -= 1
          dst.initialize(to: src.moveElement(from: i))
          i &+= 1
        }
      }
      return
    }
    // Large result. Move & rehash items one by one.
    old._consumeAll { src in
      var i = 0
      while i < src.count {
        _ = self._insertNew_Large(src.moveElement(from: i))
        i &+= 1
      }
    }
  }
}

#endif
