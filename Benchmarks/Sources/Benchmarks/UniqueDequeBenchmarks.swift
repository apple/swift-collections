//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Collections open source project
//
// Copyright (c) 2021 - 2024 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
//
//===----------------------------------------------------------------------===//

import CollectionsBenchmark
@_spi(Testing) import DequeModule

@inline(never)
@_optimize(none)
fileprivate func blackHole(_ value: Int) {}

@inline(never)
@_optimize(none)
fileprivate func blackHole(_ value: borrowing UniqueDeque<Int>) {}

@inline(never)
fileprivate func append(_ input: UnsafeBufferPointer<Int>) {
  var deque = UniqueDeque<Int>()
  for i in input {
    deque.append(i)
  }
  blackHole(deque)
}

@inline(never)
fileprivate func appendReserveCapacity(_ input: UnsafeBufferPointer<Int>) {
  var deque = UniqueDeque<Int>(capacity: input.count)
  for i in input {
    deque.append(i)
  }
  blackHole(deque)
}

@inline(never)
fileprivate func prepend(_ input: UnsafeBufferPointer<Int>) {
  var deque = UniqueDeque<Int>()
  for i in input {
    deque.prepend(i)
  }
  blackHole(deque)
}

@inline(never)
fileprivate func prependReserveCapacity(_ input: UnsafeBufferPointer<Int>) {
  var deque = UniqueDeque<Int>(capacity: input.count)
  for i in input {
    deque.prepend(i)
  }
  blackHole(deque)
}

@inline(never)
fileprivate func randomInsertions(_ insertions: UnsafeBufferPointer<Int>) {
  var deque = UniqueDeque<Int>()
  for i in insertions.indices {
    deque.insert(i, at: insertions[i])
  }
  blackHole(deque)
}

@inline(never)
fileprivate func sequentialIteration(_ deque: borrowing UniqueDeque<Int>) {
  for i in deque.indices {
    blackHole(deque[i])
  }
}

extension Benchmark {
  public mutating func addUniqueDequeBenchmarks() {
    self.addSimple(
      title: "UniqueDeque<Int> append",
      input: [Int].self
    ) { input in
      input.withUnsafeBufferPointer {
        append($0)
      }
    }

    self.addSimple(
      title: "UniqueDeque<Int> append, reserving capacity",
      input: [Int].self
    ) { input in
      input.withUnsafeBufferPointer {
        appendReserveCapacity($0)
      }
    }

    self.addSimple(
      title: "UniqueDeque<Int> prepend",
      input: [Int].self
    ) { input in
      input.withUnsafeBufferPointer {
        prepend($0)
      }
    }

    self.addSimple(
      title: "UniqueDeque<Int> prepend, reserving capacity",
      input: [Int].self
    ) { input in
      input.withUnsafeBufferPointer {
        prependReserveCapacity($0)
      }
    }

    self.addSimple(
      title: "UniqueDeque<Int> random insertions",
      input: Insertions.self
    ) { insertions in
      insertions.values.withUnsafeBufferPointer {
        randomInsertions($0)
      }
    }

    self.add(
      title: "UniqueDeque<Int> sequential iteration",
      input: [Int].self
    ) { input in
      let deque = UniqueDeque(copying: input)
      return { timer in
        sequentialIteration(deque)
      }
    }
  }
}
