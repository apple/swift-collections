//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Collections open source project
//
// Copyright (c) 2021 - 2024 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
//
//===----------------------------------------------------------------------===//

extension Deque {
  @usableFromInline
  internal final class _Storage {
    @usableFromInline
    @exclusivity(unchecked)
    internal var _value: HypoDeque<Element>

    @inlinable
    @inline(__always)
    internal init(_ value: consuming HypoDeque<Element>) {
      self._value = value
    }

    @inlinable
    internal convenience init(capacity: Int) {
      self.init(HypoDeque(capacity: capacity))
    }
  }
}

extension Deque._Storage: CustomStringConvertible {
  @usableFromInline
  internal var description: String {
    "Deque<\(Element.self)>._Storage\(_value._handle.description)"
  }
}

extension Deque._Storage {
#if COLLECTIONS_INTERNAL_CHECKS
  @usableFromInline @inline(never) @_effects(releasenone)
  internal func _checkInvariants() {
    _value._checkInvariants()
  }
#else
  @inlinable @inline(__always)
  internal func _checkInvariants() {}
#endif // COLLECTIONS_INTERNAL_CHECKS
}

extension Deque._Storage {
  @inlinable
  internal var capacity: Int { _value.capacity }

  @inlinable
  internal var startSlot: _DequeSlot { _value._handle.startSlot }
}
