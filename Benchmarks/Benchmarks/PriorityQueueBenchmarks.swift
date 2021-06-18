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
  public mutating func addPriorityQueueBenchmarks() {
    self.addSimple(
      title: "PriorityQueue<Int> init from range",
      input: Int.self
    ) { size in
      blackHole(PriorityQueue(0..<size))
    }

    self.addSimple(
      title: "PriorityQueue<Int> insert",
      input: [Int].self
    ) { input in
      var queue = PriorityQueue<Int>()
      for i in input {
        queue.insert(i)
      }
      precondition(queue.count == input.count)
      blackHole(queue)
    }

    self.add(
      title: "PriorityQueue<Int> removeMax",
      input: [Int].self
    ) { input in
      return { timer in
        var queue = PriorityQueue(input)
        while let max = queue.popMax() {
          blackHole(max)
        }
        precondition(queue.isEmpty)
        blackHole(queue)
      }
    }

    self.add(
      title: "PriorityQueue<Int> removeMin",
      input: [Int].self
    ) { input in
      return { timer in
        var queue = PriorityQueue(input)
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
