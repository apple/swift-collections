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
import CppBenchmarks

extension Benchmark {
  public mutating func addHeapBenchmarks() {
    self.addSimple(
      title: "Heap<Int> init from range",
      input: Int.self
    ) { size in
      blackHole(Heap(0..<size))
    }

    self.addSimple(
      title: "Heap<Int> insert",
      input: [Int].self
    ) { input in
      var queue = Heap<Int>()
      for i in input {
        queue.insert(i)
      }
      precondition(queue.count == input.count)
      blackHole(queue)
    }

    self.add(
      title: "Heap<Int> insert(contentsOf:)",
      input: ([Int], [Int]).self
    ) { (existing, new) in
      return { timer in
        var queue = Heap(existing)
        queue.insert(contentsOf: new)
        precondition(queue.count == existing.count + new.count)
        blackHole(queue)
      }
    }

    self.add(
      title: "Heap<Int> popMax",
      input: [Int].self
    ) { input in
      return { timer in
        var queue = Heap(input)
        while let max = queue.popMax() {
          blackHole(max)
        }
        precondition(queue.isEmpty)
        blackHole(queue)
      }
    }

    self.add(
      title: "Heap<Int> popMin",
      input: [Int].self
    ) { input in
      return { timer in
        var queue = Heap(input)
        while let min = queue.popMin() {
          blackHole(min)
        }
        precondition(queue.isEmpty)
        blackHole(queue)
      }
    }
  }
}

// MARK: -

extension Benchmark {
  public mutating func addCFBinaryHeapBenchmarks() {
    self.addSimple(
      title: "CFBinaryHeap insert",
      input: [Int].self
    ) { input in
      let heap = BinaryHeap()
      for i in input {
        heap.insert(i)
      }
      precondition(heap.count == input.count)
      blackHole(heap)
    }

    self.add(
      title: "CFBinaryHeap removeMinimumValue",
      input: [Int].self
    ) { input in
      return { timer in
        let heap = BinaryHeap()
        for i in input {
          heap.insert(i)
        }

        while heap.count > 0 {
          let min = heap.popMinimum()
          blackHole(min)
        }
        precondition(heap.count == 0)
        blackHole(heap)
      }
    }
  }
}
