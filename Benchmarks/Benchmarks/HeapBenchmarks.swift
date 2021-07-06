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
      title: "Heap<Int> init from buffer",
      input: [Int].self
    ) { input in
      blackHole(Heap(input))
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
        timer.measure {
          while let max = queue.popMax() {
            blackHole(max)
          }
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
        timer.measure {
          while let min = queue.popMin() {
            blackHole(min)
          }
        }
        precondition(queue.isEmpty)
        blackHole(queue)
      }
    }
  }

  // MARK: - PriorityQueue

  struct Task {
    let name: String
    let work: () -> Void

    init(name: String = "", work: @escaping () -> Void = {}) {
      self.name = name
      self.work = work
    }
  }

  public mutating func addPriorityQueueBenchmarks() {
    self.addSimple(
      title: "PriorityQueue<Int, Int> insert",
      input: [Int].self
    ) { input in
      var queue = PriorityQueue<Int, Int>()
      for i in input {
        queue.insert(i, priority: i)
      }
      precondition(queue.count == input.count)
      blackHole(queue)
    }

    self.add(
      title: "PriorityQueue<Int, Int> popMax",
      input: [Int].self
    ) { input in
      return { timer in
        var queue = PriorityQueue(input.map({ ($0, $0) }))
        while let max = queue.popMax() {
          blackHole(max)
        }
        precondition(queue.isEmpty)
        blackHole(queue)
      }
    }

    self.add(
      title: "PriorityQueue<Int, Int> popMin",
      input: [Int].self
    ) { input in
      return { timer in
        var queue = PriorityQueue(input.map({ ($0, $0) }))
        while let min = queue.popMin() {
          blackHole(min)
        }
        precondition(queue.isEmpty)
        blackHole(queue)
      }
    }

    // MARK: Small Struct Benchmarks

    self.addSimple(
      title: "PriorityQueue<Task, Int> insert",
      input: [Int].self
    ) { input in
      var queue = PriorityQueue<Task, Int>()
      for i in input {
        queue.insert(Task(name: "Test", work: {}), priority: i)
      }
      precondition(queue.count == input.count)
      blackHole(queue)
    }

    self.add(
      title: "PriorityQueue<Task, Int> popMax",
      input: [Int].self
    ) { input in
      return { timer in
        var queue = PriorityQueue<Task, Int>(
          input.map({ (Task(name: $0.description), $0) })
        )
        while let max = queue.popMax() {
          blackHole(max)
        }
        precondition(queue.isEmpty)
        blackHole(queue)
      }
    }

    self.add(
      title: "PriorityQueue<Task, Int> popMin",
      input: [Int].self
    ) { input in
      return { timer in
        var queue = PriorityQueue(
          input.map({ (Task(name: $0.description), $0) })
        )
        while let min = queue.popMin() {
          blackHole(min)
        }
        precondition(queue.isEmpty)
        blackHole(queue)
      }
    }
  }
}
