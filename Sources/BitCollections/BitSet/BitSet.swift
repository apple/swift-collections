//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Collections open source project
//
// Copyright (c) 2021-2022 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
//
//===----------------------------------------------------------------------===//

/// A sorted collection of small nonnegative integers, implemented as an
/// uncompressed bitmap of as many bits as the value of the largest member.
///
/// Bit sets implement `SetAlgebra` and provide efficient implementations
/// for set operations based on standard binary logic operations.
public struct BitSet<Element: FixedWidthInteger> {
  @usableFromInline
  internal typealias _UnsafeHandle = _BitSet.UnsafeHandle

  @usableFromInline
  internal var _core: _BitSet

  @usableFromInline
  init(_core: _BitSet) {
    self._core = _core
  }

  @usableFromInline
  init(_storage: [_Word], count: Int) {
    self.init(_core: _BitSet(storage: _storage, count: count))
  }
}
