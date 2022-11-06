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
import ShareableHashedCollections

extension Benchmark {
  public mutating func addShareableSetBenchmarks() {
    self.addSimple(
      title: "ShareableSet<Int> init from range",
      input: Int.self
    ) { size in
      blackHole(ShareableSet(0 ..< size))
    }

    self.addSimple(
      title: "ShareableSet<Int> init from unsafe buffer",
      input: [Int].self
    ) { input in
      input.withUnsafeBufferPointer { buffer in
        blackHole(ShareableSet(buffer))
      }
    }

    self.add(
      title: "ShareableSet<Int> sequential iteration",
      input: Int.self
    ) { size in
      let set = ShareableSet(0 ..< size)
      return { timer in
        for i in set {
          blackHole(i)
        }
      }
    }

    self.add(
      title: "ShareableSet<Int> sequential iteration, indices",
      input: Int.self
    ) { size in
      let set = ShareableSet(0 ..< size)
      return { timer in
        for i in set.indices {
          blackHole(set[i])
        }
      }
    }

    self.add(
      title: "ShareableSet<Int> successful contains",
      input: ([Int], [Int]).self
    ) { input, lookups in
      let set = ShareableSet(input)
      return { timer in
        for i in lookups {
          precondition(set.contains(i))
        }
      }
    }

    self.add(
      title: "ShareableSet<Int> unsuccessful contains",
      input: ([Int], [Int]).self
    ) { input, lookups in
      let set = ShareableSet(input)
      let lookups = lookups.map { $0 + input.count }
      return { timer in
        for i in lookups {
          precondition(!set.contains(i))
        }
      }
    }

    self.addSimple(
      title: "ShareableSet<Int> insert",
      input: [Int].self
    ) { input in
      var set: ShareableSet<Int> = []
      for i in input {
        set.insert(i)
      }
      precondition(set.count == input.count)
      blackHole(set)
    }

    self.addSimple(
      title: "ShareableSet<Int> insert, shared",
      input: [Int].self
    ) { input in
      var set: ShareableSet<Int> = []
      for i in input {
        let copy = set
        set.insert(i)
        blackHole(copy)
      }
      precondition(set.count == input.count)
      blackHole(set)
    }

    self.add(
      title: "ShareableSet<Int> insert one + subtract, shared",
      input: [Int].self
    ) { input in
      let original = ShareableSet(input)
      let newMember = input.count
      return { timer in
        var copy = original
        copy.insert(newMember)
        let diff = copy.subtracting(original)
        precondition(diff.count == 1 && diff.first == newMember)
        blackHole(copy)
      }
    }

    self.addSimple(
      title: "ShareableSet<Int> model diffing",
      input: Int.self
    ) { input in
      typealias Model = ShareableSet<Int>

      var _state: Model = [] // Private
      func updateState(
        with model: Model
      ) -> (insertions: Model, removals: Model) {
        let insertions = model.subtracting(_state)
        let removals = _state.subtracting(model)
        _state = model
        return (insertions, removals)
      }

      var model: Model = []
      for i in 0 ..< input {
        model.insert(i)
        let r = updateState(with: model)
        precondition(r.insertions.count == 1 && r.removals.count == 0)
      }
    }

    self.add(
      title: "ShareableSet<Int> remove",
      input: ([Int], [Int]).self
    ) { input, removals in
      return { timer in
        var set = ShareableSet(input)
        for i in removals {
          set.remove(i)
        }
        precondition(set.isEmpty)
        blackHole(set)
      }
    }

    self.add(
      title: "ShareableSet<Int> remove, shared",
      input: ([Int], [Int]).self
    ) { input, removals in
      return { timer in
        var set = ShareableSet(input)
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
          title: "ShareableSet<Int> union with Self (\(percentage) overlap)",
          input: [Int].self
        ) { input in
          let start = start(input.count)
          let a = ShareableSet(input)
          let b = ShareableSet(start ..< start + input.count)
          return { timer in
            blackHole(a.union(identity(b)))
          }
        }
      }

      for (percentage, start) in overlaps {
        self.add(
          title: "ShareableSet<Int> intersection with Self (\(percentage) overlap)",
          input: [Int].self
        ) { input in
          let start = start(input.count)
          let a = ShareableSet(input)
          let b = ShareableSet(start ..< start + input.count)
          return { timer in
            blackHole(a.intersection(identity(b)))
          }
        }
      }

      for (percentage, start) in overlaps {
        self.add(
          title: "ShareableSet<Int> symmetricDifference with Self (\(percentage) overlap)",
          input: [Int].self
        ) { input in
          let start = start(input.count)
          let a = ShareableSet(input)
          let b = ShareableSet(start ..< start + input.count)
          return { timer in
            blackHole(a.symmetricDifference(identity(b)))
          }
        }
      }

      for (percentage, start) in overlaps {
        self.add(
          title: "ShareableSet<Int> subtracting Self (\(percentage) overlap)",
          input: [Int].self
        ) { input in
          let start = start(input.count)
          let a = ShareableSet(input)
          let b = ShareableSet(start ..< start + input.count)
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
          title: "ShareableSet<Int> union with Array (\(percentage) overlap)",
          input: [Int].self
        ) { input in
          let start = start(input.count)
          let a = ShareableSet(input)
          let b = Array(start ..< start + input.count)
          return { timer in
            blackHole(a.union(identity(b)))
          }
        }
      }

      for (percentage, start) in overlaps {
        self.add(
          title: "ShareableSet<Int> intersection with Array (\(percentage) overlap)",
          input: [Int].self
        ) { input in
          let start = start(input.count)
          let a = ShareableSet(input)
          let b = Array(start ..< start + input.count)
          return { timer in
            blackHole(a.intersection(identity(b)))
          }
        }
      }

      for (percentage, start) in overlaps {
        self.add(
          title: "ShareableSet<Int> symmetricDifference with Array (\(percentage) overlap)",
          input: [Int].self
        ) { input in
          let start = start(input.count)
          let a = ShareableSet(input)
          let b = Array(start ..< start + input.count)
          return { timer in
            blackHole(a.symmetricDifference(identity(b)))
          }
        }
      }

      for (percentage, start) in overlaps {
        self.add(
          title: "ShareableSet<Int> subtracting Array (\(percentage) overlap)",
          input: [Int].self
        ) { input in
          let start = start(input.count)
          let a = ShareableSet(input)
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
          title: "ShareableSet<Int> formUnion with Self (\(percentage) overlap)",
          input: [Int].self
        ) { input in
          let start = start(input.count)
          let b = ShareableSet(start ..< start + input.count)
          return { timer in
            var a = ShareableSet(input)
            timer.measure {
              a.formUnion(identity(b))
            }
            blackHole(a)
          }
        }
      }

      for (percentage, start) in overlaps {
        self.add(
          title: "ShareableSet<Int> formIntersection with Self (\(percentage) overlap)",
          input: [Int].self
        ) { input in
          let start = start(input.count)
          let b = ShareableSet(start ..< start + input.count)
          return { timer in
            var a = ShareableSet(input)
            timer.measure {
              a.formIntersection(identity(b))
            }
            blackHole(a)
          }
        }
      }

      for (percentage, start) in overlaps {
        self.add(
          title: "ShareableSet<Int> formSymmetricDifference with Self (\(percentage) overlap)",
          input: [Int].self
        ) { input in
          let start = start(input.count)
          let b = ShareableSet(start ..< start + input.count)
          return { timer in
            var a = ShareableSet(input)
            timer.measure {
              a.formSymmetricDifference(identity(b))
            }
            blackHole(a)
          }
        }
      }

      for (percentage, start) in overlaps {
        self.add(
          title: "ShareableSet<Int> subtract Self (\(percentage) overlap)",
          input: [Int].self
        ) { input in
          let start = start(input.count)
          let b = ShareableSet(start ..< start + input.count)
          return { timer in
            var a = ShareableSet(input)
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
          title: "ShareableSet<Int> formUnion with Array (\(percentage) overlap)",
          input: [Int].self
        ) { input in
          let start = start(input.count)
          let b = Array(start ..< start + input.count)
          return { timer in
            var a = ShareableSet(input)
            timer.measure {
              a.formUnion(identity(b))
            }
            blackHole(a)
          }
        }
      }

      for (percentage, start) in overlaps {
        self.add(
          title: "ShareableSet<Int> formIntersection with Array (\(percentage) overlap)",
          input: [Int].self
        ) { input in
          let start = start(input.count)
          let b = Array(start ..< start + input.count)
          return { timer in
            var a = ShareableSet(input)
            timer.measure {
              a.formIntersection(identity(b))
            }
            blackHole(a)
          }
        }
      }

      for (percentage, start) in overlaps {
        self.add(
          title: "ShareableSet<Int> formSymmetricDifference with Array (\(percentage) overlap)",
          input: [Int].self
        ) { input in
          let start = start(input.count)
          let b = Array(start ..< start + input.count)
          return { timer in
            var a = ShareableSet(input)
            timer.measure {
              a.formSymmetricDifference(identity(b))
            }
            blackHole(a)
          }
        }
      }

      for (percentage, start) in overlaps {
        self.add(
          title: "ShareableSet<Int> subtract Array (\(percentage) overlap)",
          input: [Int].self
        ) { input in
          let start = start(input.count)
          let b = Array(start ..< start + input.count)
          return { timer in
            var a = ShareableSet(input)
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
