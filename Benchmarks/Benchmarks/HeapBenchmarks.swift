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
import PriorityQueueModule

extension Benchmark {
  public mutating func addHeapBenchmarks() {
    self.addSimple(
      title: "Heap<Int> init from range",
      input: Int.self
    ) { size in
      blackHole(Heap(0..<size))
    }

    self.addSimple(
      title: "Heap<Int> init from buffer",
      input: [Int].self
    ) { input in
      blackHole(Heap(input))
    }

    self.addSimple(
      title: "Heap<Int> insert",
      input: [Int].self
    ) { input in
      var heap = Heap<Int>()
      for i in input {
        heap.insert(i)
      }
      precondition(heap.count == input.count)
      blackHole(heap)
    }

    self.add(
      title: "Heap<Int> insert(contentsOf:)",
      input: ([Int], [Int]).self
    ) { (existing, new) in
      return { timer in
        var heap = Heap(existing)
        heap.insert(contentsOf: new)
        precondition(heap.count == existing.count + new.count)
        blackHole(heap)
      }
    }

    self.add(
      title: "Heap<Int> popMax",
      input: [Int].self
    ) { input in
      return { timer in
        var heap = Heap(input)
        timer.measure {
          while let max = heap.popMax() {
            blackHole(max)
          }
        }
        precondition(heap.isEmpty)
        blackHole(heap)
      }
    }

    self.add(
      title: "Heap<Int> popMin",
      input: [Int].self
    ) { input in
      return { timer in
        var heap = Heap(input)
        timer.measure {
          while let min = heap.popMin() {
            blackHole(min)
          }
        }
        precondition(heap.isEmpty)
        blackHole(heap)
      }
    }

    // MARK: Small Struct Benchmarks

    self.addSimple(
      title: "Heap<Task> insert",
      input: [Int].self
    ) { input in
      var heap = Heap<HeapTask>()
      for i in input {
        heap.insert(HeapTask(priority: i))
      }
      precondition(heap.count == input.count)
      blackHole(heap)
    }
    self.add(
      title: "Heap<Task> popMax",
      input: [Int].self
    ) { input in
      return { timer in
        var heap = Heap(input.map { HeapTask(priority: $0) })
        timer.measure {
          while let max = heap.popMax() {
            blackHole(max)
          }
        }
        precondition(heap.isEmpty)
        blackHole(heap)
      }
    }

    self.add(
      title: "Heap<Task> popMin",
      input: [Int].self
    ) { input in
      return { timer in
        var heap = Heap(input.map { HeapTask(priority: $0) })
        timer.measure {
          while let min = heap.popMin() {
            blackHole(min)
          }
        }
        precondition(heap.isEmpty)
        blackHole(heap)
      }
    }
  }

  struct HeapTask: Comparable {
    let name: String
    let priority: Int
    let work: () -> Void

    init(name: String = "", priority: Int, work: @escaping () -> Void = {}) {
      self.name = name
      self.priority = priority
      self.work = work
    }

    static func < (lhs: Self, rhs: Self) -> Bool {
      lhs.priority < rhs.priority
    }

    static func == (lhs: Self, rhs: Self) -> Bool {
      lhs.priority == rhs.priority
    }
  }
}
