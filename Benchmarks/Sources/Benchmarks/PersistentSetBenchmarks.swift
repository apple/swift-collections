//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Collections open source project
//
// Copyright (c) 2022 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
//
//===----------------------------------------------------------------------===//

import CollectionsBenchmark
import PersistentCollections

extension Benchmark {
  public mutating func addPersistentSetBenchmarks() {
    self.addSimple(
      title: "PersistentSet<Int> init from range",
      input: Int.self
    ) { size in
      blackHole(PersistentSet(0 ..< size))
    }

    self.addSimple(
      title: "PersistentSet<Int> init from unsafe buffer",
      input: [Int].self
    ) { input in
      input.withUnsafeBufferPointer { buffer in
        blackHole(PersistentSet(buffer))
      }
    }

    self.add(
      title: "PersistentSet<Int> sequential iteration",
      input: Int.self
    ) { size in
      let set = PersistentSet(0 ..< size)
      return { timer in
        for i in set {
          blackHole(i)
        }
      }
    }

    self.add(
      title: "PersistentSet<Int> sequential iteration, indices",
      input: Int.self
    ) { size in
      let set = PersistentSet(0 ..< size)
      return { timer in
        for i in set.indices {
          blackHole(set[i])
        }
      }
    }

    self.add(
      title: "PersistentSet<Int> successful contains",
      input: ([Int], [Int]).self
    ) { input, lookups in
      let set = PersistentSet(input)
      return { timer in
        for i in lookups {
          precondition(set.contains(i))
        }
      }
    }

    self.add(
      title: "PersistentSet<Int> unsuccessful contains",
      input: ([Int], [Int]).self
    ) { input, lookups in
      let set = PersistentSet(input)
      let lookups = lookups.map { $0 + input.count }
      return { timer in
        for i in lookups {
          precondition(!set.contains(i))
        }
      }
    }

    self.addSimple(
      title: "PersistentSet<Int> insert",
      input: [Int].self
    ) { input in
      var set: PersistentSet<Int> = []
      for i in input {
        set.insert(i)
      }
      precondition(set.count == input.count)
      blackHole(set)
    }

    self.addSimple(
      title: "PersistentSet<Int> insert, shared",
      input: [Int].self
    ) { input in
      var set: PersistentSet<Int> = []
      for i in input {
        let copy = set
        set.insert(i)
        blackHole(copy)
      }
      precondition(set.count == input.count)
      blackHole(set)
    }

    self.add(
      title: "PersistentSet<Int> insert one + subtract, shared",
      input: [Int].self
    ) { input in
      let original = PersistentSet(input)
      let newMember = input.count
      return { timer in
        var copy = original
        copy.insert(newMember)
        let diff = copy.subtracting(original)
        precondition(diff.count == 1 && diff.first == newMember)
        blackHole(copy)
      }
    }

    do {
      var timer = Timer()
      let input = 0 ..< 1_000
      let newMember = input.count

      let original = PersistentSet(input)
      timer.measure {
        var copy = original
        copy.insert(newMember)
        let diff = copy.subtracting(original)
        precondition(diff.count == 1 && diff.first == newMember)
        blackHole(copy)
      }
    }

    self.add(
      title: "PersistentSet<Int> remove",
      input: ([Int], [Int]).self
    ) { input, removals in
      return { timer in
        var set = PersistentSet(input)
        for i in removals {
          set.remove(i)
        }
        precondition(set.isEmpty)
        blackHole(set)
      }
    }

    self.add(
      title: "PersistentSet<Int> remove, shared",
      input: ([Int], [Int]).self
    ) { input, removals in
      return { timer in
        var set = PersistentSet(input)
        for i in removals {
          let copy = set
          set.remove(i)
          blackHole(copy)
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
          title: "PersistentSet<Int> union with Self (\(percentage) overlap)",
          input: [Int].self
        ) { input in
          let start = start(input.count)
          let a = PersistentSet(input)
          let b = PersistentSet(start ..< start + input.count)
          return { timer in
            blackHole(a.union(identity(b)))
          }
        }
      }

      for (percentage, start) in overlaps {
        self.add(
          title: "PersistentSet<Int> intersection with Self (\(percentage) overlap)",
          input: [Int].self
        ) { input in
          let start = start(input.count)
          let a = PersistentSet(input)
          let b = PersistentSet(start ..< start + input.count)
          return { timer in
            blackHole(a.intersection(identity(b)))
          }
        }
      }

      for (percentage, start) in overlaps {
        self.add(
          title: "PersistentSet<Int> symmetricDifference with Self (\(percentage) overlap)",
          input: [Int].self
        ) { input in
          let start = start(input.count)
          let a = PersistentSet(input)
          let b = PersistentSet(start ..< start + input.count)
          return { timer in
            blackHole(a.symmetricDifference(identity(b)))
          }
        }
      }

      for (percentage, start) in overlaps {
        self.add(
          title: "PersistentSet<Int> subtracting Self (\(percentage) overlap)",
          input: [Int].self
        ) { input in
          let start = start(input.count)
          let a = PersistentSet(input)
          let b = PersistentSet(start ..< start + input.count)
          return { timer in
            blackHole(a.subtracting(identity(b)))
          }
        }
      }
    }

    // SetAlgebra operations with Array
    do {
      for (percentage, start) in overlaps {
        self.add(
          title: "PersistentSet<Int> union with Array (\(percentage) overlap)",
          input: [Int].self
        ) { input in
          let start = start(input.count)
          let a = PersistentSet(input)
          let b = Array(start ..< start + input.count)
          return { timer in
            blackHole(a.union(identity(b)))
          }
        }
      }

      for (percentage, start) in overlaps {
        self.add(
          title: "PersistentSet<Int> intersection with Array (\(percentage) overlap)",
          input: [Int].self
        ) { input in
          let start = start(input.count)
          let a = PersistentSet(input)
          let b = Array(start ..< start + input.count)
          return { timer in
            blackHole(a.intersection(identity(b)))
          }
        }
      }

      for (percentage, start) in overlaps {
        self.add(
          title: "PersistentSet<Int> symmetricDifference with Array (\(percentage) overlap)",
          input: [Int].self
        ) { input in
          let start = start(input.count)
          let a = PersistentSet(input)
          let b = Array(start ..< start + input.count)
          return { timer in
            blackHole(a.symmetricDifference(identity(b)))
          }
        }
      }

      for (percentage, start) in overlaps {
        self.add(
          title: "PersistentSet<Int> subtracting Array (\(percentage) overlap)",
          input: [Int].self
        ) { input in
          let start = start(input.count)
          let a = PersistentSet(input)
          let b = Array(start ..< start + input.count)
          return { timer in
            blackHole(a.subtracting(identity(b)))
          }
        }
      }
    }

    // SetAlgebra mutations with Self
    do {
      for (percentage, start) in overlaps {
        self.add(
          title: "PersistentSet<Int> formUnion with Self (\(percentage) overlap)",
          input: [Int].self
        ) { input in
          let start = start(input.count)
          let b = PersistentSet(start ..< start + input.count)
          return { timer in
            var a = PersistentSet(input)
            timer.measure {
              a.formUnion(identity(b))
            }
            blackHole(a)
          }
        }
      }

      for (percentage, start) in overlaps {
        self.add(
          title: "PersistentSet<Int> formIntersection with Self (\(percentage) overlap)",
          input: [Int].self
        ) { input in
          let start = start(input.count)
          let b = PersistentSet(start ..< start + input.count)
          return { timer in
            var a = PersistentSet(input)
            timer.measure {
              a.formIntersection(identity(b))
            }
            blackHole(a)
          }
        }
      }

      for (percentage, start) in overlaps {
        self.add(
          title: "PersistentSet<Int> formSymmetricDifference with Self (\(percentage) overlap)",
          input: [Int].self
        ) { input in
          let start = start(input.count)
          let b = PersistentSet(start ..< start + input.count)
          return { timer in
            var a = PersistentSet(input)
            timer.measure {
              a.formSymmetricDifference(identity(b))
            }
            blackHole(a)
          }
        }
      }

      for (percentage, start) in overlaps {
        self.add(
          title: "PersistentSet<Int> subtract Self (\(percentage) overlap)",
          input: [Int].self
        ) { input in
          let start = start(input.count)
          let b = PersistentSet(start ..< start + input.count)
          return { timer in
            var a = PersistentSet(input)
            timer.measure {
              a.subtract(identity(b))
            }
            blackHole(a)
          }
        }
      }
    }

    // SetAlgebra mutations with Array
    do {
      for (percentage, start) in overlaps {
        self.add(
          title: "PersistentSet<Int> formUnion with Array (\(percentage) overlap)",
          input: [Int].self
        ) { input in
          let start = start(input.count)
          let b = Array(start ..< start + input.count)
          return { timer in
            var a = PersistentSet(input)
            timer.measure {
              a.formUnion(identity(b))
            }
            blackHole(a)
          }
        }
      }

      for (percentage, start) in overlaps {
        self.add(
          title: "PersistentSet<Int> formIntersection with Array (\(percentage) overlap)",
          input: [Int].self
        ) { input in
          let start = start(input.count)
          let b = Array(start ..< start + input.count)
          return { timer in
            var a = PersistentSet(input)
            timer.measure {
              a.formIntersection(identity(b))
            }
            blackHole(a)
          }
        }
      }

      for (percentage, start) in overlaps {
        self.add(
          title: "PersistentSet<Int> formSymmetricDifference with Array (\(percentage) overlap)",
          input: [Int].self
        ) { input in
          let start = start(input.count)
          let b = Array(start ..< start + input.count)
          return { timer in
            var a = PersistentSet(input)
            timer.measure {
              a.formSymmetricDifference(identity(b))
            }
            blackHole(a)
          }
        }
      }

      for (percentage, start) in overlaps {
        self.add(
          title: "PersistentSet<Int> subtract Array (\(percentage) overlap)",
          input: [Int].self
        ) { input in
          let start = start(input.count)
          let b = Array(start ..< start + input.count)
          return { timer in
            var a = PersistentSet(input)
            timer.measure {
              a.subtract(identity(b))
            }
            blackHole(a)
          }
        }
      }
    }
  }
}
