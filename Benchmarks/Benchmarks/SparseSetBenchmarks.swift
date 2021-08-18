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
import SparseSetModule

private typealias Key = Int

extension Benchmark {
  public mutating func addSparseSetBenchmarks() {
    self.add(
      title: "SparseSet<\(Key.self), Int> init(uniqueKeysWithValues:)",
      input: [Int].self
    ) { input in
      let keysAndValues = input.map { (Key($0), 2 * $0) }
      return { timer in
        blackHole(SparseSet<Key, Int>(uniqueKeysWithValues: keysAndValues))
      }
    }

    self.add(
      title: "SparseSet<\(Key.self), Int> init(uncheckedUniqueKeysWithValues:)",
      input: [Int].self
    ) { input in
      let keysAndValues = input.map { (Key($0), 2 * $0) }
      return { timer in
        blackHole(
          SparseSet<Key, Int>(uncheckedUniqueKeysWithValues: keysAndValues))
      }
    }

    self.add(
      title: "SparseSet<\(Key.self), Int> init(uncheckedUniqueKeys:values:)",
      input: [Int].self
    ) { input in
      let keys = input.map { Key($0) }
      let values = input.map { 2 * Int($0) }
      return { timer in
        blackHole(
          SparseSet<Key, Int>(uncheckedUniqueKeys: keys, values: values))
      }
    }

    self.add(
      title: "SparseSet<\(Key.self), Int> sequential iteration",
      input: [Int].self
    ) { input in
      let keys = input.map { Key($0) }
      let values = input.map { 2 * $0 }
      let s = SparseSet<Key, Int>(
        uncheckedUniqueKeys: keys, values: values)
      return { timer in
        for item in s {
          blackHole(item)
        }
      }
    }

    self.add(
      title: "SparseSet<\(Key.self), Int>.Keys sequential iteration",
      input: [Int].self
    ) { input in
      let keys = input.map { Key($0) }
      let values = input.map { 2 * $0 }
      let s = SparseSet<Key, Int>(
        uncheckedUniqueKeys: keys, values: values)
      return { timer in
        for item in s.keys {
          blackHole(item)
        }
      }
    }

    self.add(
      title: "SparseSet<\(Key.self), Int>.Values sequential iteration",
      input: [Int].self
    ) { input in
      let keys = input.map { Key($0) }
      let values = input.map { 2 * $0 }
      let s = SparseSet<Key, Int>(
        uncheckedUniqueKeys: keys, values: values)
      return { timer in
        for item in s.values {
          blackHole(item)
        }
      }
    }

    self.add(
      title: "SparseSet<\(Key.self), Int> subscript, successful lookups",
      input: ([Int], [Int]).self
    ) { input, lookups in
      let keys = input.map { Key($0) }
      let values = input.map { 2 * $0 }
      let s = SparseSet<Key, Int>(
        uncheckedUniqueKeys: keys, values: values)
      return { timer in
        for i in lookups {
          precondition(s[Key(i)] == 2 * i)
        }
      }
    }

    self.add(
      title: "SparseSet<\(Key.self), Int> subscript, unsuccessful lookups",
      input: ([Int], [Int]).self
    ) { input, lookups in
      let keys = input.map { Key($0) }
      let values = input.map { 2 * $0 }
      let s = SparseSet<Key, Int>(
        uncheckedUniqueKeys: keys, values: values)
      let c = input.count
      return { timer in
        for i in lookups {
          precondition(s[Key(i + c)] == nil)
        }
      }
    }

    self.add(
      title: "SparseSet<\(Key.self), Int> subscript, noop setter",
      input: ([Int], [Int]).self
    ) { input, lookups in
      return { timer in
        let keysAndValues = input.map { (Key($0), 2 * $0) }
        var s = SparseSet<Key, Int>(
          uncheckedUniqueKeysWithValues: keysAndValues)
        let c = input.count
        timer.measure {
          for i in lookups {
            s[Key(i + c)] = nil
          }
        }
        precondition(s.count == input.count)
        blackHole(s)
      }
    }

    self.add(
      title: "SparseSet<\(Key.self), Int> subscript, set existing",
      input: ([Int], [Int]).self
    ) { input, lookups in
      return { timer in
        let keysAndValues = input.map { (Key($0), 2 * $0) }
        var s = SparseSet<Key, Int>(
          uncheckedUniqueKeysWithValues: keysAndValues)
        timer.measure {
          for i in lookups {
            s[Key(i)] = 0
          }
        }
        precondition(s.count == input.count)
        blackHole(s)
      }
    }

    self.add(
      title: "SparseSet<\(Key.self), Int> subscript, _modify",
      input: ([Int], [Int]).self
    ) { input, lookups in
      return { timer in
        let keysAndValues = input.map { (Key($0), 2 * $0) }
        var s = SparseSet<Key, Int>(
          uncheckedUniqueKeysWithValues: keysAndValues)
        timer.measure {
          for i in lookups {
            s[Key(i)]! *= 2
          }
        }
        precondition(s.count == input.count)
        blackHole(s)
      }
    }

    self.addSimple(
      title: "SparseSet<\(Key.self), Int> subscript, append",
      input: [Int].self
    ) { input in
      var s: SparseSet<Key, Int> = [:]
      for i in input {
        s[Key(i)] = 2 * i
      }
      precondition(s.count == input.count)
      blackHole(s)
    }

    self.addSimple(
      title: "SparseSet<\(Key.self), Int> subscript, append, reserving capacity",
      input: [Int].self
    ) { input in
      let universeSize: Int = input.max().map { $0 + 1 } ?? 0
      var s: SparseSet<Key, Int> = SparseSet(minimumCapacity: input.count, universeSize: universeSize)
      for i in input {
        s[Key(i)] = 2 * i
      }
      precondition(s.count == input.count)
      blackHole(s)
    }

    self.add(
      title: "SparseSet<\(Key.self), Int> subscript, remove existing",
      input: ([Int], [Int]).self
    ) { input, lookups in
      return { timer in
        let keysAndValues = input.map { (Key($0), 2 * $0) }
        var s = SparseSet<Key, Int>(
          uncheckedUniqueKeysWithValues: keysAndValues)
        timer.measure {
          for i in lookups {
            s[Key(i)] = nil
          }
        }
        precondition(s.isEmpty)
        blackHole(s)
      }
    }

    self.add(
      title: "SparseSet<\(Key.self), Int> subscript, remove missing",
      input: ([Int], [Int]).self
    ) { input, lookups in
      return { timer in
        let keysAndValues = input.map { (Key($0), 2 * $0) }
        var s = SparseSet<Key, Int>(
          uncheckedUniqueKeysWithValues: keysAndValues)
        let c = input.count
        timer.measure {
          for i in lookups {
            s[Key(i + c)] = nil
          }
        }
        precondition(s.count == input.count)
        blackHole(s)
      }
    }

    self.add(
      title: "SparseSet<\(Key.self), Int> defaulted subscript, successful lookups",
      input: ([Int], [Int]).self
    ) { input, lookups in
      let keysAndValues = input.map { (Key($0), 2 * $0) }
      let s = SparseSet<Key, Int>(
        uncheckedUniqueKeysWithValues: keysAndValues)
      return { timer in
        for i in lookups {
          precondition(s[Key(i), default: -1] != -1)
        }
      }
    }

    self.add(
      title: "SparseSet<\(Key.self), Int> defaulted subscript, unsuccessful lookups",
      input: ([Int], [Int]).self
    ) { input, lookups in
      let keysAndValues = input.map { (Key($0), 2 * $0) }
      let s = SparseSet<Key, Int>(
        uncheckedUniqueKeysWithValues: keysAndValues)
      return { timer in
        let c = s.count
        for i in lookups {
          precondition(s[Key(i + c), default: -1] == -1)
        }
      }
    }

    self.add(
      title: "SparseSet<\(Key.self), Int> defaulted subscript, _modify existing",
      input: ([Int], [Int]).self
    ) { input, lookups in
      return { timer in
        let keysAndValues = input.map { (Key($0), 2 * $0) }
        var s = SparseSet<Key, Int>(
          uncheckedUniqueKeysWithValues: keysAndValues)
        timer.measure {
          for i in lookups {
            s[Key(i), default: -1] *= 2
          }
        }
        precondition(s.count == input.count)
        blackHole(s)
      }
    }

    self.add(
      title: "SparseSet<\(Key.self), Int> defaulted subscript, _modify missing",
      input: ([Int], [Int]).self
    ) { input, lookups in
      return { timer in
        let keysAndValues = input.map { (Key($0), 2 * $0) }
        var s = SparseSet<Key, Int>(
          uncheckedUniqueKeysWithValues: keysAndValues)
        let c = input.count
        timer.measure {
          for i in lookups {
            s[Key(c + i), default: -1] *= 2
          }
        }
        precondition(s.count == 2 * input.count)
        blackHole(s)
      }
    }

    self.add(
      title: "SparseSet<\(Key.self), Int> successful index(forKey:)",
      input: ([Int], [Int]).self
    ) { input, lookups in
      let keys = input.map { Key($0) }
      let values = input.map { 2 * $0 }
      let s = SparseSet<Key, Int>(
        uncheckedUniqueKeys: keys,
        values: values)
      return { timer in
        for i in lookups {
          precondition(s.index(forKey: Key(i)) != nil)
        }
      }
    }

    self.add(
      title: "SparseSet<\(Key.self), Int> unsuccessful index(forKey:)",
      input: ([Int], [Int]).self
    ) { input, lookups in
      let keys = input.map { Key($0) }
      let values = input.map { 2 * $0 }
      let s = SparseSet<Key, Int>(
        uncheckedUniqueKeys: keys,
        values: values)
      return { timer in
        for i in lookups {
          precondition(s.index(forKey: Key(lookups.count + i)) == nil)
        }
      }
    }

    self.add(
      title: "SparseSet<\(Key.self), Int> updateValue(_:forKey:), existing",
      input: ([Int], [Int]).self
    ) { input, lookups in
      return { timer in
        let keysAndValues = input.map { (Key($0), 2 * $0) }
        var s = SparseSet<Key, Int>(
          uncheckedUniqueKeysWithValues: keysAndValues)
        timer.measure {
          for i in lookups {
            s.updateValue(0, forKey: Key(i))
          }
        }
        precondition(s.count == input.count)
        blackHole(s)
      }
    }

    self.add(
      title: "SparseSet<\(Key.self), Int> updateValue(_:forKey:), append",
      input: ([Int], [Int]).self
    ) { input, lookups in
      return { timer in
        let keysAndValues = input.map { (Key($0), 2 * $0) }
        var s = SparseSet<Key, Int>(
          uncheckedUniqueKeysWithValues: keysAndValues)
        timer.measure {
          for i in lookups {
            s.updateValue(0, forKey: Key(input.count + i))
          }
        }
        precondition(s.count == 2 * input.count)
        blackHole(s)
      }
    }

    self.add(
      title: "SparseSet<\(Key.self), Int> random swaps",
      input: [Int].self
    ) { input in
      return { timer in
        let keysAndValues = input.map { (Key($0), 2 * $0) }
        var s = SparseSet<Key, Int>(
          uncheckedUniqueKeysWithValues: keysAndValues)
        timer.measure {
          var v = 0
          for i in input {
            s.swapAt(Int(i), v)
            v += 1
          }
        }
        blackHole(s)
      }
    }

    self.add(
      title: "SparseSet<\(Key.self), Int> partitioning around middle",
      input: [Int].self
    ) { input in
      return { timer in
        let keysAndValues = input.map { (Key($0), 2 * $0) }
        var s = SparseSet<Key, Int>(
          uncheckedUniqueKeysWithValues: keysAndValues)
        let pivot = input.count / 2
        timer.measure {
          let r = s.partition(by: { $0.key >= pivot })
          precondition(r == pivot)
        }
        blackHole(s)
      }
    }

    self.add(
      title: "SparseSet<\(Key.self), Int> sort",
      input: [Int].self
    ) { input in
      return { timer in
        let keysAndValues = input.map { (Key($0), 2 * $0) }
        var s = SparseSet<Key, Int>(
          uncheckedUniqueKeysWithValues: keysAndValues)
        timer.measure {
          s.sort()
        }
        precondition(s.keys.elementsEqual((0 ..< input.count).lazy.map { Key($0) }))
        precondition(s.values.elementsEqual((0 ..< input.count).lazy.map { 2 * $0 }))
      }
    }

    self.add(
      title: "SparseSet<\(Key.self), Int> removeLast",
      input: Int.self
    ) { size in
      return { timer in
        var s = SparseSet<Key, Int>(
          uncheckedUniqueKeys: (0 ..< size).map { Key($0) },
          values: size ..< 2 * size)
        timer.measure {
          for _ in 0 ..< size {
            s.removeLast()
          }
        }
        precondition(s.isEmpty)
        blackHole(s)
      }
    }

    self.add(
      title: "SparseSet<\(Key.self), Int> removeFirst",
      input: Int.self
    ) { size in
      return { timer in
        var s = SparseSet<Key, Int>(
          uncheckedUniqueKeys: (0 ..< size).map { Key($0) },
          values: size ..< 2 * size)
        timer.measure {
          for _ in 0 ..< size {
            s.removeFirst()
          }
        }
        precondition(s.isEmpty)
        blackHole(s)
      }
    }

    self.add(
      title: "SparseSet<\(Key.self), Int> random removals (offset-based)",
      input: Insertions.self
    ) { insertions in
      return { timer in
        let insertions = insertions.values
        var s = SparseSet<Key, Int>(
          uncheckedUniqueKeys: (0 ..< insertions.count).map { Key($0) },
          values: insertions.count ..< 2 * insertions.count)
        timer.measure {
          for i in stride(from: insertions.count, to: 0, by: -1) {
            s.remove(at: insertions[i - 1])
          }
        }
        blackHole(s)
      }
    }

    self.add(
      title: "SparseSet<\(Key.self), Int> random removals (existing keys)",
      input: ([Int], [Int]).self
    ) { input, lookups in
      return { timer in
        let keysAndValues = input.map { (Key($0), 2 * $0) }
        var s = SparseSet<Key, Int>(
          uncheckedUniqueKeysWithValues: keysAndValues)
        timer.measure {
          for i in lookups {
            precondition(s.removeValue(forKey: Key(i)) != nil)
          }
        }
        precondition(s.count == 0)
        blackHole(s)
      }
    }

    self.add(
      title: "SparseSet<\(Key.self), Int> random removals (missing keys)",
      input: ([Int], [Int]).self
    ) { input, lookups in
      return { timer in
        let c = input.count
        let keysAndValues = input.map { (Key(c + $0), 2 * $0) }
        var s = SparseSet<Key, Int>(
          uncheckedUniqueKeysWithValues: keysAndValues)
        timer.measure {
          for i in lookups {
            precondition(s.removeValue(forKey: Key(i)) == nil)
          }
        }
        precondition(s.count == input.count)
        blackHole(s)
      }
    }
  }
}
