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

#if false // SortedCollections is not a thing yet
import CollectionsBenchmark
import SortedCollections

extension Benchmark {
  public mutating func addSortedSetBenchmarks() {
    self.addSimple(
      title: "SortedSet<Int> init from range",
      input: Int.self
    ) { size in
      blackHole(SortedSet(0 ..< size))
    }
    
    self.addSimple(
      title: "SortedSet<Int> init(sortedElements:) from range",
      input: Int.self
    ) { size in
      blackHole(SortedSet(sortedElements: 0 ..< size))
    }
    self.add(
      title: "SortedSet<Int> sequential iteration",
      input: [Int].self
    ) { input in
      let set = SortedSet(input)
      return { timer in
        for i in set {
          blackHole(i)
        }
      }
    }
    
    self.add(
      title: "SortedSet<Int> forEach iteration",
      input: [Int].self
    ) { input in
      let set = SortedSet(input)
      return { timer in
        set.forEach { i in
          blackHole(i)
        }
      }
    }

    self.add(
      title: "SortedSet<Int> successful contains",
      input: ([Int], [Int]).self
    ) { input, lookups in
      let set = SortedSet(input)
      return { timer in
        for i in lookups {
          precondition(set.contains(i))
        }
      }
    }

    self.add(
      title: "SortedSet<Int> unsuccessful contains",
      input: ([Int], [Int]).self
    ) { input, lookups in
      let set = SortedSet(input)
      let lookups = lookups.map { $0 + input.count }
      return { timer in
        for i in lookups {
          precondition(!set.contains(i))
        }
      }
    }

    self.addSimple(
      title: "SortedSet<Int> insertions",
      input: [Int].self
    ) { input in
      var set: SortedSet<Int> = []
      for i in input {
        set.insert(i)
      }
      precondition(set.count == input.count)
      blackHole(set)
    }

    self.add(
      title: "SortedSet<Int> remove",
      input: ([Int], [Int]).self
    ) { input, removals in
      return { timer in
        var set = SortedSet(input)
        timer.measure {
          for i in removals {
            set.remove(i)
          }
        }
        precondition(set.isEmpty)
        blackHole(set)
      }
    }

    self.add(
      title: "SortedSet<Int> removeLast",
      input: Int.self
    ) { size in
      return { timer in
        var set = SortedSet(0 ..< size)
        timer.measure {
          for _ in 0 ..< size {
            set.removeLast()
          }
        }
        precondition(set.isEmpty)
        blackHole(set)
      }
    }

    self.add(
      title: "SortedSet<Int> removeFirst",
      input: Int.self
    ) { size in
      return { timer in
        var set = SortedSet(0 ..< size)
        timer.measure {
          for _ in 0 ..< size {
            set.removeFirst()
          }
        }
        precondition(set.isEmpty)
        blackHole(set)
      }
    }

    let overlaps: [(String, (Int) -> Int)] = [
      ("0%",   { c in c }),
      ("25%",  { c in 3 * c / 4 }),
      ("50%",  { c in c / 2 }),
      ("75%",  { c in c / 4 }),
      ("100%", { c in 0 }),
    ]

    // SetAlgebra operations with Self
    do {
      for (percentage, start) in overlaps {
        self.add(
          title: "SortedSet<Int> union with Self (\(percentage) overlap)",
          input: [Int].self
        ) { input in
          let start = start(input.count)
          let a = SortedSet(input)
          let b = SortedSet(start ..< start + input.count)
          return { timer in
            blackHole(a.union(b))
          }
        }
      }

      for (percentage, start) in overlaps {
        self.add(
          title: "SortedSet<Int> intersection with Self (\(percentage) overlap)",
          input: [Int].self
        ) { input in
          let start = start(input.count)
          let a = SortedSet(input)
          let b = SortedSet(start ..< start + input.count)
          return { timer in
            blackHole(a.intersection(b))
          }
        }
      }

      for (percentage, start) in overlaps {
        self.add(
          title: "SortedSet<Int> symmetricDifference with Self (\(percentage) overlap)",
          input: [Int].self
        ) { input in
          let start = start(input.count)
          let a = SortedSet(input)
          let b = SortedSet(start ..< start + input.count)
          return { timer in
            blackHole(a.symmetricDifference(b))
          }
        }
      }

      for (percentage, start) in overlaps {
        self.add(
          title: "SortedSet<Int> subtracting Self (\(percentage) overlap)",
          input: [Int].self
        ) { input in
          let start = start(input.count)
          let a = SortedSet(input)
          let b = SortedSet(start ..< start + input.count)
          return { timer in
            blackHole(a.subtracting(b))
          }
        }
      }
    }

  }
}
#endif
