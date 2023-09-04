//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Collections open source project
//
// Copyright (c) 2023 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
//
//===----------------------------------------------------------------------===//

extension FixedArray {
  @inlinable
  @inline(__always)
  mutating func copy(src: ArraySlice<Element>, start: Int, count: Int) {
    // TODO: memcpy?
    for ii in 0..<Swift.min(Self.capacity, count) {
      self[ii] = src[src.startIndex + start + ii]
    }
  }

  @inlinable
  @inline(__always)
  mutating func copy(src: UnsafeMutableBufferPointer<Element>, start: Int, count: Int) {
    for ii in 0..<Swift.min(Self.capacity, count) {
      self[ii] = src[start + ii]
    }
  }

  @inlinable
  @inline(__always)
  mutating func shiftLeft(toIndex: Int) {
    for ii in toIndex..<Self.capacity {
      self[ii - toIndex] = self[ii]
    }
  }

  @inlinable
  @inline(__always)
  mutating func shiftRight() {
    for ii in (1..<Self.capacity).reversed() {
      self[ii] = self[ii - 1]
    }
  }
}
