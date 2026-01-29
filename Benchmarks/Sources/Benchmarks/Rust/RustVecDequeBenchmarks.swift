//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Collections open source project
//
// Copyright (c) 2025 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
//
//===----------------------------------------------------------------------===//

import CollectionsBenchmark

@_extern(c, "rust_vecdeque_create")
func rust_vecdeque_create(
  _: UnsafeRawPointer?,
  _: Int
) -> UnsafeMutableRawPointer?

@_extern(c, "rust_vecdeque_destroy")
func rust_vecdeque_destroy(_: UnsafeMutableRawPointer?)

@_extern(c, "rust_vecdeque_from_int_range")
func rust_vecdeque_from_int_range(_: Int)

@_extern(c, "rust_vecdeque_from_int_buffer")
func rust_vecdeque_from_int_buffer(_: UnsafePointer<Int>?, _: Int)

@_extern(c, "rust_vecdeque_append_integers")
func rust_vecdeque_append_integers(_: UnsafePointer<Int>?, _: Int)

@_extern(c, "rust_vecdeque_append_integers_with_capacity")
func rust_vecdeque_append_integers_with_capacity(_: UnsafePointer<Int>?, _: Int)

@_extern(c, "rust_vecdeque_prepend_integers")
func rust_vecdeque_prepend_integers(_: UnsafePointer<Int>?, _: Int)

@_extern(c, "rust_vecdeque_prepend_integers_with_capacity")
func rust_vecdeque_prepend_integers_with_capacity(_: UnsafePointer<Int>?, _: Int)

@_extern(c, "rust_vecdeque_random_insertions")
func rust_vecdeque_random_insertions(_: UnsafePointer<Int>?, _: Int)

@_extern(c, "rust_vecdeque_iterate")
func rust_vecdeque_iterate(_: UnsafeMutableRawPointer?)

internal class RustDeque {
  var ptr: UnsafeMutableRawPointer?

  init(_ input: [Int]) {
    self.ptr = input.withUnsafeBufferPointer { buffer in
      rust_vecdeque_create(buffer.baseAddress, buffer.count)
    }
  }

  deinit {
    destroy()
  }

  func destroy() {
    if let ptr = ptr {
      rust_vecdeque_destroy(ptr)
    }
    ptr = nil
  }
}

extension Benchmark {
  internal mutating func _addRustVecDequeBenchmarks() {
    self.addSimple(
      title: "VecDeque<isize> push_back from integer range",
      input: Int.self
    ) { count in
      rust_vecdeque_from_int_range(count)
    }

    self.addSimple(
      title: "VecDeque<isize> constructor from buffer",
      input: [Int].self
    ) { input in
      input.withUnsafeBufferPointer { buffer in
        rust_vecdeque_from_int_buffer(buffer.baseAddress, buffer.count)
      }
    }

    self.addSimple(
      title: "VecDeque<isize> push_back",
      input: [Int].self
    ) { input in
      input.withUnsafeBufferPointer { buffer in
        rust_vecdeque_append_integers(buffer.baseAddress, buffer.count)
      }
    }

    self.addSimple(
      title: "VecDeque<isize> push_back, reserving capacity",
      input: [Int].self
    ) { input in
      input.withUnsafeBufferPointer { buffer in
        rust_vecdeque_append_integers_with_capacity(buffer.baseAddress, buffer.count)
      }
    }

    self.addSimple(
      title: "VecDeque<isize> push_front",
      input: [Int].self
    ) { input in
      input.withUnsafeBufferPointer { buffer in
        rust_vecdeque_prepend_integers(buffer.baseAddress, buffer.count)
      }
    }

    self.addSimple(
      title: "VecDeque<isize> push_front, reserving capacity",
      input: [Int].self
    ) { input in
      input.withUnsafeBufferPointer { buffer in
        rust_vecdeque_prepend_integers_with_capacity(buffer.baseAddress, buffer.count)
      }
    }

    self.addSimple(
      title: "VecDeque<isize> random insertions",
      input: Insertions.self
    ) { insertions in
      insertions.values.withUnsafeBufferPointer { buffer in
        rust_vecdeque_random_insertions(buffer.baseAddress, buffer.count)
      }
    }

    self.add(
      title: "VecDeque<isize> sequential iteration",
      input: [Int].self
    ) { input in
      let deque = RustDeque(input)
      return { timer in
        rust_vecdeque_iterate(deque.ptr)
      }
    }
  }
}
