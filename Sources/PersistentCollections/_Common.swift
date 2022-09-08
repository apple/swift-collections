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

func computeHash<T: Hashable>(_ value: T) -> Int {
  value.hashValue
}

typealias Bitmap = UInt32

let bitPartitionSize: Int = 5

let bitPartitionMask: Int = (1 << bitPartitionSize) - 1

// TODO: restore type to `UInt8` after reworking hash-collisions to grow in
// depth instead of width
typealias Capacity = UInt32

let hashCodeLength: Int = Int.bitWidth

let maxDepth = Int((Double(hashCodeLength) / Double(bitPartitionSize)).rounded(.up))

func maskFrom(_ hash: Int, _ shift: Int) -> Int {
  (hash >> shift) & bitPartitionMask
}

func bitposFrom(_ mask: Int) -> Bitmap {
  1 << mask
}

func indexFrom(_ bitmap: Bitmap, _ bitpos: Bitmap) -> Int {
  (bitmap & (bitpos &- 1)).nonzeroBitCount
}

func indexFrom(_ bitmap: Bitmap, _ mask: Int, _ bitpos: Bitmap) -> Int {
  (bitmap == Bitmap.max) ? mask : indexFrom(bitmap, bitpos)
}

// NEW
@inlinable
@inline(__always)
func rangeInsert<T>(
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
func rangeRemove<T>(
  at index: Int,
  from baseAddress: UnsafeMutablePointer<T>,
  count: Int
) {
  let src = baseAddress.advanced(by: index + 1)
  let dst = src.predecessor()

  dst.deinitialize(count: 1)
  dst.moveInitialize(from: src, count: count - index - 1)
}
