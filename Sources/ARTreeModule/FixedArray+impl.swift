//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2023 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
//
//===----------------------------------------------------------------------===//

extension FixedArray: RandomAccessCollection, MutableCollection {
  typealias Index = Int

  internal var startIndex: Index {
    return 0
  }

  internal var endIndex: Index {
    return capacity
  }

  internal subscript(i: Index) -> Element {
    @inline(__always)
    get {
      let capacity = Self.capacity
      assert(i >= 0 && i < capacity)
      let res: Element = withUnsafeBytes(of: storage) {
        (rawPtr: UnsafeRawBufferPointer) -> Element in
        let stride = MemoryLayout<Element>.stride
        assert(rawPtr.count == capacity * stride, "layout mismatch?")
        let bufPtr = UnsafeBufferPointer(
          start: rawPtr.baseAddress!.assumingMemoryBound(to: Element.self),
          count: capacity)
        return bufPtr[i]
      }
      return res
    }
    @inline(__always)
    set {
      assert(i >= 0 && i < count)
      self.withUnsafeMutableBufferPointer { buffer in
        buffer[i] = newValue
      }
    }
  }

  @inline(__always)
  internal func index(after i: Index) -> Index {
    return i + 1
  }

  @inline(__always)
  internal func index(before i: Index) -> Index {
    return i - 1
  }
}

extension FixedArray {
  internal mutating func withUnsafeMutableBufferPointer<R>(
    _ body: (UnsafeMutableBufferPointer<Element>) throws -> R
  ) rethrows -> R {
    let capacity = Self.capacity
    return try withUnsafeMutableBytes(of: &storage) { rawBuffer in
      assert(
        rawBuffer.count == capacity * MemoryLayout<Element>.stride,
        "layout mismatch?")
      let buffer = UnsafeMutableBufferPointer<Element>(
        start: rawBuffer.baseAddress!.assumingMemoryBound(to: Element.self),
        count: capacity)
      return try body(buffer)
    }
  }

  internal mutating func withUnsafeBufferPointer<R>(
    _ body: (UnsafeBufferPointer<Element>) throws -> R
  ) rethrows -> R {
    let capacity = Self.capacity
    return try withUnsafeBytes(of: &storage) { rawBuffer in
      assert(
        rawBuffer.count == capacity * MemoryLayout<Element>.stride,
        "layout mismatch?")
      let buffer = UnsafeBufferPointer<Element>(
        start: rawBuffer.baseAddress!.assumingMemoryBound(to: Element.self),
        count: capacity)
      return try body(buffer)
    }
  }
}
