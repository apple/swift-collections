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

/// Do nothing and immediately return.
///
/// Some compiler optimizations can eliminate operations whose results don't
/// get used, and this could potentially interfere with the accuracy of a
/// benchmark. To defeat these optimizations, pass such unused results to
/// this function so that the compiler considers them used.
@inline(never)
@_optimize(none)
fileprivate func blackHole(_ value: borrowing RigidDeque<Int>) {}

@inline(never)
fileprivate func appendReserveCapacity(_ input: UnsafeBufferPointer<Int>) {
  var deque = RigidDeque<Int>(capacity: input.count)
  for i in input {
    deque.append(i)
  }
  blackHole(deque)
}

@inline(never)
fileprivate func prependReserveCapacity(_ input: UnsafeBufferPointer<Int>) {
  var deque = RigidDeque<Int>(capacity: input.count)
  for i in input {
    deque.prepend(i)
  }
  blackHole(deque)
}

extension Benchmark {
  public mutating func addRigidDequeBenchmarks() {
    self.addSimple(
      title: "RigidDeque<Int> append, reserving capacity",
      input: [Int].self
    ) { input in
      input.withUnsafeBufferPointer {
        appendReserveCapacity($0)
      }
    }

    self.addSimple(
      title: "RigidDeque<Int> prepend, reserving capacity",
      input: [Int].self
    ) { input in
      input.withUnsafeBufferPointer {
        prependReserveCapacity($0)
      }
    }
  }
}
