//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Collections open source project
//
// Copyright (c) 2021 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
//
//===----------------------------------------------------------------------===//

import CollectionsBenchmark

#if os(macOS) || os(iOS) || os(watchOS) || os(tvOS)
import FoundationBenchmarks

internal class FoundationBinaryHeap {
  var ptr: UnsafeMutableRawPointer?

  init(_ input: [Int]) {
    self.ptr = input.withUnsafeBufferPointer { buffer in
      fnd_binary_heap_create(buffer.baseAddress, buffer.count)
    }
  }

  convenience init() {
    self.init([])
  }

  deinit {
    destroy()
  }

  func destroy() {
    if let ptr = ptr {
      fnd_binary_heap_destroy(ptr)
    }
    ptr = nil
  }

  func add(_ value: Int) {
    fnd_binary_heap_add(ptr, value)
  }

  func add(_ values: [Int]) {
    values.withUnsafeBufferPointer { buffer in
      fnd_binary_heap_add_loop(ptr, buffer.baseAddress, buffer.count)
    }
  }

  func removeMin() -> Int {
    fnd_binary_heap_remove_min(ptr)
  }

  func removeAll() {
    fnd_binary_heap_remove_min_all(ptr)
  }
}
#endif

extension Benchmark {
  public mutating func addFoundationBenchmarks() {
    self.add(
      title: "CFBinaryHeapAddValue",
      input: [Int].self
    ) { input in
#if os(macOS) || os(iOS) || os(watchOS) || os(tvOS)
      return { timer in
        let heap = FoundationBinaryHeap()
        timer.measure {
          heap.add(input)
        }
        blackHole(heap)
      }
#else
      return nil
#endif
    }

    self.add(
      title: "CFBinaryHeapRemoveMinimumValue",
      input: [Int].self
    ) { input in
#if os(macOS) || os(iOS) || os(watchOS) || os(tvOS)
      return { timer in
        let heap = FoundationBinaryHeap(input)
        timer.measure {
          heap.removeAll()
        }
        blackHole(heap)
      }
#else
      return nil
#endif
    }
  }
}
