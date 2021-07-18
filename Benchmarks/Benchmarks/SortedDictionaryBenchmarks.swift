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

extension Benchmark {
  public mutating func addSortedDictionaryBenchmarks() {
//    self.add(
//      title: "SortedDictionary<Int, Int> init(uniqueKeysWithValues:)",
//      input: [Int].self
//    ) { input in
//      let keysAndValues = input.lazy.map { (key: $0, value: 2 * $0) }
//
//      return { timer in
//        blackHole(SortedDictionary(uniqueKeysWithValues: keysAndValues))
//      }
//    }
//
//    self.add(
//      title: "SortedDictionary<Int, Int> subscript, append",
//      input: [Int].self
//    ) { input in
//      let keysAndValues = input.lazy.map { (key: $0, value: 2 * $0) }
//      var sortedDictionary = SortedDictionary<Int, Int>()
//
//      return { timer in
//        for (key, value) in keysAndValues {
//          sortedDictionary[key] = value
//        }
//        blackHole(sortedDictionary)
//      }
//    }
//
//    self.add(
//      title: "SortedDictionary<Int, Int> subscript, successful lookups",
//      input: ([Int], [Int]).self
//    ) { input, lookups in
//      let keysAndValues = input.lazy.map { (key: $0, value: 2 * $0) }
//      let sortedDictionary = SortedDictionary<Int, Int>(uniqueKeysWithValues: keysAndValues)
//
//      return { timer in
//        for key in lookups {
//          precondition(sortedDictionary._root.contains(key: key))
//        }
//      }
//    }
    
    self.add(
      title: "SortedDictionary<Int, Int>._BTree subscript, successful lookups",
      input: ([Int], [Int]).self
    ) { input, lookups in
      let keysAndValues = input.lazy.map { (key: $0, value: 2 * $0) }
      var tree = _BTree<Int, Int>()
      
      for (k, v) in keysAndValues {
        tree.setAnyValue(v, forKey: k)
      }

      return { timer in
        for key in lookups {
          precondition(tree.contains(key: key))
        }
      }
    }
  }
}
