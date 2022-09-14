//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Collections open source project
//
// Copyright (c) 2019 - 2022 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
//
//===----------------------------------------------------------------------===//

@inlinable @inline(__always)
internal func _computeHash<T: Hashable>(_ value: T) -> Int {
  value.hashValue
}

@inlinable @inline(__always)
internal var _bitPartitionSize: Int { 5 }

@inlinable @inline(__always)
internal var _bitPartitionMask: Int { (1 << _bitPartitionSize) - 1 }

@inlinable @inline(__always)
internal var _hashCodeLength: Int { Int.bitWidth }

@inlinable @inline(__always)
internal var _maxDepth: Int {
  (_hashCodeLength + _bitPartitionSize - 1) / _bitPartitionSize
}

// NEW
@inlinable @inline(__always)
internal func _rangeInsert<T>(
  _ element: T,
  at index: Int,
  into baseAddress: UnsafeMutablePointer<T>,
  count: Int
) {
  let src = baseAddress.advanced(by: index)
  let dst = src.successor()

  dst.moveInitialize(from: src, count: count - index)

  src.initialize(to: element)
}

// NEW
@inlinable @inline(__always)
internal func _rangeRemove<T>(
  at index: Int,
  from baseAddress: UnsafeMutablePointer<T>,
  count: Int
) {
  let src = baseAddress.advanced(by: index + 1)
  let dst = src.predecessor()

  dst.deinitialize(count: 1)
  dst.moveInitialize(from: src, count: count - index - 1)
}
