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

internal func _computeHash<T: Hashable>(_ value: T) -> Int {
  value.hashValue
}

internal typealias _Bitmap = UInt32

// TODO: restore type to `UInt8` after reworking hash-collisions to grow in
// depth instead of width
internal typealias _Capacity = UInt32

internal let _bitPartitionSize: Int = 5

internal let _bitPartitionMask: Int = (1 << _bitPartitionSize) - 1

internal let _hashCodeLength: Int = Int.bitWidth

internal let _maxDepth = (_hashCodeLength + _bitPartitionSize - 1) / _bitPartitionSize

internal func _maskFrom(_ hash: Int, _ shift: Int) -> Int {
  (hash >> shift) & _bitPartitionMask
}

internal func _bitposFrom(_ mask: Int) -> _Bitmap {
  1 << mask
}

internal func _indexFrom(_ bitmap: _Bitmap, _ bitpos: _Bitmap) -> Int {
  (bitmap & (bitpos &- 1)).nonzeroBitCount
}

internal func _indexFrom(_ bitmap: _Bitmap, _ mask: Int, _ bitpos: _Bitmap) -> Int {
  (bitmap == _Bitmap.max) ? mask : _indexFrom(bitmap, bitpos)
}

// NEW
@inlinable
@inline(__always)
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
@inlinable
@inline(__always)
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
