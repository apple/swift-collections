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
import CppBenchmarks

internal class CppVector {
  var ptr: UnsafeMutableRawPointer?

  init(_ input: [Int]) {
    self.ptr = input.withUnsafeBufferPointer { buffer in
      cpp_vector_create(buffer.baseAddress, buffer.count)
    }
  }

  deinit {
    destroy()
  }

  func destroy() {
    if let ptr = ptr {
      cpp_vector_destroy(ptr)
    }
    ptr = nil
  }
}

internal class CppDeque {
  var ptr: UnsafeMutableRawPointer?

  init(_ input: [Int]) {
    self.ptr = input.withUnsafeBufferPointer { buffer in
      cpp_deque_create(buffer.baseAddress, buffer.count)
    }
  }

  deinit {
    destroy()
  }

  func destroy() {
    if let ptr = ptr {
      cpp_deque_destroy(ptr)
    }
    ptr = nil
  }
}

internal class CppUnorderedSet {
  var ptr: UnsafeMutableRawPointer?

  init(_ input: [Int]) {
    self.ptr = input.withUnsafeBufferPointer { buffer in
      cpp_unordered_set_create(buffer.baseAddress, buffer.count)
    }
  }

  deinit {
    destroy()
  }

  func destroy() {
    if let ptr = ptr {
      cpp_unordered_set_destroy(ptr)
    }
    ptr = nil
  }
}

internal class CppUnorderedMap {
  var ptr: UnsafeMutableRawPointer?

  init(_ input: [Int]) {
    self.ptr = input.withUnsafeBufferPointer { buffer in
      cpp_unordered_map_create(buffer.baseAddress, buffer.count)
    }
  }

  deinit {
    destroy()
  }

  func destroy() {
    if let ptr = ptr {
      cpp_unordered_map_destroy(ptr)
    }
    ptr = nil
  }
}


extension Benchmark {
  public mutating func addCppBenchmarks() {
    cpp_set_hash_fn { value in value._rawHashValue(seed: 0) }

    self.addSimple(
      title: "std::hash<intptr_t>",
      input: [Int].self
    ) { input in
      input.withUnsafeBufferPointer { buffer in
        cpp_hash(buffer.baseAddress, buffer.count)
      }
    }

    self.addSimple(
      title: "custom_intptr_hash (using Swift.Hasher)",
      input: [Int].self
    ) { input in
      input.withUnsafeBufferPointer { buffer in
        cpp_custom_hash(buffer.baseAddress, buffer.count)
      }
    }

    self.addSimple(
      title: "std::vector<intptr_t> push_back from integer range",
      input: Int.self
    ) { count in
      cpp_vector_from_int_range(count)
    }

    self.addSimple(
      title: "std::deque<intptr_t> push_back from integer range",
      input: Int.self
    ) { count in
      cpp_deque_from_int_range(count)
    }

    //--------------------------------------------------------------------------

    self.addSimple(
      title: "std::vector<intptr_t> constructor from buffer",
      input: [Int].self
    ) { input in
      input.withUnsafeBufferPointer { buffer in
        cpp_vector_from_int_buffer(buffer.baseAddress, buffer.count)
      }
    }

    self.addSimple(
      title: "std::deque<intptr_t> constructor from buffer",
      input: [Int].self
    ) { input in
      input.withUnsafeBufferPointer { buffer in
        cpp_deque_from_int_buffer(buffer.baseAddress, buffer.count)
      }
    }

    //--------------------------------------------------------------------------

    self.add(
      title: "std::vector<intptr_t> sequential iteration",
      input: [Int].self
    ) { input in
      let vector = CppVector(input)
      return { timer in
        cpp_vector_iterate(vector.ptr)
      }
    }

    self.add(
      title: "std::deque<intptr_t> sequential iteration",
      input: [Int].self
    ) { input in
      let deque = CppDeque(input)
      return { timer in
        cpp_deque_iterate(deque.ptr)
      }
    }

    //--------------------------------------------------------------------------

    self.add(
      title: "std::vector<intptr_t> random-access offset lookups (operator [])",
      input: ([Int], [Int]).self
    ) { input, lookups in
      let vector = CppVector(input)
      return { timer in
        lookups.withUnsafeBufferPointer { buffer in
          cpp_vector_lookups_subscript(vector.ptr, buffer.baseAddress, buffer.count)
        }
      }
    }

    self.add(
      title: "std::deque<intptr_t> random-access offset lookups (operator [])",
      input: ([Int], [Int]).self
    ) { input, lookups in
      let vector = CppDeque(input)
      return { timer in
        lookups.withUnsafeBufferPointer { buffer in
          cpp_deque_lookups_subscript(vector.ptr, buffer.baseAddress, buffer.count)
        }
      }
    }

    //--------------------------------------------------------------------------

    self.add(
      title: "std::vector<intptr_t> random-access offset lookups (at)",
      input: ([Int], [Int]).self
    ) { input, lookups in
      let deque = CppVector(input)
      return { timer in
        lookups.withUnsafeBufferPointer { buffer in
          cpp_vector_lookups_at(deque.ptr, buffer.baseAddress, buffer.count)
        }
      }
    }

    self.add(
      title: "std::deque<intptr_t> at, random offsets",
      input: ([Int], [Int]).self
    ) { input, lookups in
      let deque = CppDeque(input)
      return { timer in
        lookups.withUnsafeBufferPointer { buffer in
          cpp_deque_lookups_at(deque.ptr, buffer.baseAddress, buffer.count)
        }
      }
    }

    //--------------------------------------------------------------------------

    self.addSimple(
      title: "std::vector<intptr_t> push_back",
      input: [Int].self
    ) { input in
      input.withUnsafeBufferPointer { buffer in
        cpp_vector_append_integers(buffer.baseAddress, buffer.count, false)
      }
    }

    self.addSimple(
      title: "std::vector<intptr_t> push_back, reserving capacity",
      input: [Int].self
    ) { input in
      input.withUnsafeBufferPointer { buffer in
        cpp_vector_append_integers(buffer.baseAddress, buffer.count, true)
      }
    }

    self.addSimple(
      title: "std::deque<intptr_t> push_back",
      input: [Int].self
    ) { input in
      input.withUnsafeBufferPointer { buffer in
        cpp_deque_append_integers(buffer.baseAddress, buffer.count)
      }
    }

    //--------------------------------------------------------------------------

    self.addSimple(
      title: "std::vector<intptr_t> insert at front",
      input: [Int].self
    ) { input in
      input.withUnsafeBufferPointer { buffer in
        cpp_vector_prepend_integers(buffer.baseAddress, buffer.count, false)
      }
    }

    self.addSimple(
      title: "std::vector<intptr_t> insert at front, reserving capacity",
      input: [Int].self
    ) { input in
      input.withUnsafeBufferPointer { buffer in
        cpp_vector_prepend_integers(buffer.baseAddress, buffer.count, true)
      }
    }

    self.addSimple(
      title: "std::deque<intptr_t> push_front",
      input: [Int].self
    ) { input in
      input.withUnsafeBufferPointer { buffer in
        cpp_deque_prepend_integers(buffer.baseAddress, buffer.count)
      }
    }

    //--------------------------------------------------------------------------

    self.addSimple(
      title: "std::vector<intptr_t> random insertions",
      input: Insertions.self
    ) { insertions in
      insertions.values.withUnsafeBufferPointer { buffer in
        cpp_vector_random_insertions(buffer.baseAddress, buffer.count, false)
      }
    }

    self.addSimple(
      title: "std::deque<intptr_t> random insertions",
      input: Insertions.self
    ) { insertions in
      insertions.values.withUnsafeBufferPointer { buffer in
        cpp_deque_random_insertions(buffer.baseAddress, buffer.count)
      }
    }

    //--------------------------------------------------------------------------

    self.add(
      title: "std::vector<intptr_t> pop_back",
      input: Int.self
    ) { size in
      return { timer in
        let vector = CppVector(Array(0 ..< size))
        timer.measure {
          cpp_vector_pop_back(vector.ptr)
        }
        vector.destroy()
      }
    }

    self.add(
      title: "std::deque<intptr_t> pop_back",
      input: Int.self
    ) { size in
      return { timer in
        let deque = CppDeque(Array(0 ..< size))
        timer.measure {
          cpp_deque_pop_back(deque.ptr)
        }
        deque.destroy()
      }
    }

    //--------------------------------------------------------------------------

    self.add(
      title: "std::vector<intptr_t> erase first",
      input: Int.self
    ) { size in
      return { timer in
        let vector = CppVector(Array(0 ..< size))
        timer.measure {
          cpp_vector_pop_front(vector.ptr)
        }
        vector.destroy()
      }
    }

    self.add(
      title: "std::deque<intptr_t> pop_front",
      input: Int.self
    ) { size in
      return { timer in
        let deque = CppDeque(Array(0 ..< size))
        timer.measure {
          cpp_deque_pop_front(deque.ptr)
        }
        deque.destroy()
      }
    }

    //--------------------------------------------------------------------------

    self.add(
      title: "std::vector<intptr_t> random removals",
      input: Insertions.self
    ) { insertions in
      let removals = Array(insertions.values.reversed())
      return { timer in
        let vector = CppVector(Array(0 ..< removals.count))
        timer.measure {
          removals.withUnsafeBufferPointer { buffer in
            cpp_vector_random_removals(vector.ptr, buffer.baseAddress, buffer.count)
          }
        }
        vector.destroy()
      }
    }

    self.add(
      title: "std::deque<intptr_t> random removals",
      input: Insertions.self
    ) { insertions in
      let removals = Array(insertions.values.reversed())
      return { timer in
        let deque = CppDeque(Array(0 ..< removals.count))
        timer.measure {
          removals.withUnsafeBufferPointer { buffer in
            cpp_deque_random_removals(deque.ptr, buffer.baseAddress, buffer.count)
          }
        }
        deque.destroy()
      }
    }

    //--------------------------------------------------------------------------

    self.add(
      title: "std::vector<intptr_t> sort",
      input: [Int].self
    ) { input in
      return { timer in
        let vector = CppVector(input)
        timer.measure {
          cpp_vector_sort(vector.ptr)
        }
        vector.destroy()
      }
    }

    self.add(
      title: "std::deque<intptr_t> sort",
      input: [Int].self
    ) { input in
      return { timer in
        let deque = CppDeque(input)
        timer.measure {
          cpp_deque_sort(deque.ptr)
        }
        deque.destroy()
      }
    }

    //--------------------------------------------------------------------------

    self.addSimple(
      title: "std::unordered_set<intptr_t> insert from integer range",
      input: Int.self
    ) { count in
      cpp_unordered_set_from_int_range(count)
    }

    self.addSimple(
      title: "std::unordered_set<intptr_t> constructor from buffer",
      input: [Int].self
    ) { input in
      input.withUnsafeBufferPointer { buffer in
        cpp_unordered_set_from_int_buffer(buffer.baseAddress, buffer.count)
      }
    }

    self.add(
      title: "std::unordered_set<intptr_t> sequential iteration",
      input: [Int].self
    ) { input in
      let set = CppUnorderedSet(input)
      return { timer in
        cpp_unordered_set_iterate(set.ptr)
      }
    }

    self.add(
      title: "std::unordered_set<intptr_t> successful find",
      input: ([Int], [Int]).self
    ) { input, lookups in
      let set = CppUnorderedSet(input)
      return { timer in
        lookups.withUnsafeBufferPointer { buffer in
          cpp_unordered_set_lookups(set.ptr, buffer.baseAddress, buffer.count, true)
        }
      }
    }

    self.add(
      title: "std::unordered_set<intptr_t> unsuccessful find",
      input: ([Int], [Int]).self
    ) { input, lookups in
      let set = CppUnorderedSet(input)
      let lookups = lookups.map { $0 + input.count }
      return { timer in
        lookups.withUnsafeBufferPointer { buffer in
          cpp_unordered_set_lookups(set.ptr, buffer.baseAddress, buffer.count, false)
        }
      }
    }

    self.addSimple(
      title: "std::unordered_set<intptr_t> insert",
      input: [Int].self
    ) { input in
      input.withUnsafeBufferPointer { buffer in
        cpp_unordered_set_insert_integers(buffer.baseAddress, buffer.count, false)
      }
    }

    self.addSimple(
      title: "std::unordered_set<intptr_t> insert, reserving capacity",
      input: [Int].self
    ) { input in
      input.withUnsafeBufferPointer { buffer in
        cpp_unordered_set_insert_integers(buffer.baseAddress, buffer.count, true)
      }
    }

    self.add(
      title: "std::unordered_set<intptr_t> erase",
      input: ([Int], [Int]).self
    ) { input, removals in
      return { timer in
        let set = CppUnorderedSet(input)
        timer.measure {
          removals.withUnsafeBufferPointer { buffer in
            cpp_unordered_set_removals(set.ptr, buffer.baseAddress, buffer.count)
          }
        }
        set.destroy()
      }
    }

    //--------------------------------------------------------------------------

    self.addSimple(
      title: "std::unordered_map<intptr_t, intptr_t> insert from integer range",
      input: Int.self
    ) { count in
      cpp_unordered_map_from_int_range(count)
    }

    self.add(
      title: "std::unordered_map<intptr_t, intptr_t> sequential iteration",
      input: [Int].self
    ) { input in
      let set = CppUnorderedMap(input)
      return { timer in
        cpp_unordered_map_iterate(set.ptr)
      }
    }

    self.add(
      title: "std::unordered_map<intptr_t, intptr_t> successful find",
      input: ([Int], [Int]).self
    ) { input, lookups in
      let map = CppUnorderedMap(input)
      return { timer in
        lookups.withUnsafeBufferPointer { buffer in
          cpp_unordered_map_lookups(map.ptr, buffer.baseAddress, buffer.count, true)
        }
      }
    }

    self.add(
      title: "std::unordered_map<intptr_t, intptr_t> unsuccessful find",
      input: ([Int], [Int]).self
    ) { input, lookups in
      let map = CppUnorderedMap(input)
      let lookups = lookups.map { $0 + input.count }
      return { timer in
        lookups.withUnsafeBufferPointer { buffer in
          cpp_unordered_map_lookups(map.ptr, buffer.baseAddress, buffer.count, false)
        }
      }
    }

    self.add(
      title: "std::unordered_map<intptr_t, intptr_t> subscript, existing key",
      input: ([Int], [Int]).self
    ) { input, lookups in
      let map = CppUnorderedMap(input)
      return { timer in
        lookups.withUnsafeBufferPointer { buffer in
          cpp_unordered_map_subscript(map.ptr, buffer.baseAddress, buffer.count)
        }
      }
    }

    self.add(
      title: "std::unordered_map<intptr_t, intptr_t> subscript, new key",
      input: ([Int], [Int]).self
    ) { input, lookups in
      let map = CppUnorderedMap(input)
      let lookups = lookups.map { $0 + input.count }
      return { timer in
        lookups.withUnsafeBufferPointer { buffer in
          cpp_unordered_map_subscript(map.ptr, buffer.baseAddress, buffer.count)
        }
      }
    }

    self.addSimple(
      title: "std::unordered_map<intptr_t, intptr_t> insert",
      input: [Int].self
    ) { input in
      input.withUnsafeBufferPointer { buffer in
        cpp_unordered_map_insert_integers(buffer.baseAddress, buffer.count, false)
      }
    }

    self.addSimple(
      title: "std::unordered_map<intptr_t, intptr_t> insert, reserving capacity",
      input: [Int].self
    ) { input in
      input.withUnsafeBufferPointer { buffer in
        cpp_unordered_map_insert_integers(buffer.baseAddress, buffer.count, true)
      }
    }

    self.add(
      title: "std::unordered_map<intptr_t, intptr_t> erase existing",
      input: ([Int], [Int]).self
    ) { input, removals in
      return { timer in
        let map = CppUnorderedMap(input)
        timer.measure {
          removals.withUnsafeBufferPointer { buffer in
            cpp_unordered_map_removals(map.ptr, buffer.baseAddress, buffer.count)
          }
        }
        map.destroy()
      }
    }

    self.add(
      title: "std::unordered_map<intptr_t, intptr_t> erase missing",
      input: ([Int], [Int]).self
    ) { input, removals in
      return { timer in
        let map = CppUnorderedMap(input.map { input.count + $0 })
        timer.measure {
          removals.withUnsafeBufferPointer { buffer in
            cpp_unordered_map_removals(map.ptr, buffer.baseAddress, buffer.count)
          }
        }
        map.destroy()
      }
    }
  }
}
