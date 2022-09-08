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

func rangeInsert<T>(
  _ element: T,
  at index: Int,
  intoRange range: Range<UnsafeMutablePointer<T>>
) {
  let seq = range.dropFirst(index)

  let src = seq.startIndex
  let dst = src.successor()

  dst.moveInitialize(from: src, count: seq.count)

  src.initialize(to: element)
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

// `index` is the logical index starting at the rear, indexing to the left
func rangeInsertReversed<T>(
  _ element: T,
  at index: Int,
  intoRange range: Range<UnsafeMutablePointer<T>>
) {
  let seq = range.dropLast(index)

  let src = seq.startIndex
  let dst = src.predecessor()

  dst.moveInitialize(from: src, count: seq.count)

  // requires call to predecessor on "past the end" position
  seq.endIndex.predecessor().initialize(to: element)
}

func rangeRemove<T>(
  at index: Int,
  fromRange range: Range<UnsafeMutablePointer<T>>
) {
  let seq = range.dropFirst(index + 1)

  let src = seq.startIndex
  let dst = src.predecessor()

  dst.deinitialize(count: 1)
  dst.moveInitialize(from: src, count: seq.count)
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

// `index` is the logical index starting at the rear, indexing to the left
func rangeRemoveReversed<T>(
  at index: Int, fromRange range: Range<UnsafeMutablePointer<T>>
) {
  let seq = range.dropLast(index + 1)

  let src = seq.startIndex
  let dst = src.successor()

  seq.endIndex.deinitialize(count: 1)
  dst.moveInitialize(from: src, count: seq.count)
}
