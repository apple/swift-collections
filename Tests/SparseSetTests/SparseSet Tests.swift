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

import XCTest
import CollectionsTestSupport
@testable import SparseSetModule

final class SparseSetTests: CollectionTestCase {
  func test_isEmpty() {
    let set = SparseSet<Int, Int>()
    expectEqual(set.count, 0)
    expectTrue(set.isEmpty)
    expectEqualElements(set, [])
  }

  func test_init_minimumCapacity_universeSize() {
    let s = SparseSet<Int, Int>(minimumCapacity: 1_000, universeSize: 10_000)
    expectGreaterThanOrEqual(s._dense.keys.capacity, 1_000)
    expectGreaterThanOrEqual(s._dense.values.capacity, 1_000)
    expectEqual(s._sparse.capacity, 10_000)
  }

  func test_uniqueKeysWithValues_Dictionary() {
    let items: Dictionary<Int, String> = [
      0: "zero",
      1: "one",
      2: "two",
      3: "three",
    ]
    let s = SparseSet(uncheckedUniqueKeysWithValues: items)
    expectEqualElements(s, items)
  }

  func test_uniqueKeysWithValues_labeled_tuples() {
    let items: KeyValuePairs<Int, String> = [
      0: "zero",
      1: "one",
      2: "two",
      3: "three",
    ]
    let s = SparseSet(uncheckedUniqueKeysWithValues: items)
    expectEqualElements(s, items)
  }

  func test_uniqueKeysWithValues_unlabeled_tuples() {
    let items: [(Int, String)] = [
      (0, "zero"),
      (1, "one"),
      (2, "two"),
      (3, "three"),
    ]
    let s = SparseSet(uncheckedUniqueKeysWithValues: items)
    expectEqualElements(s, items)
  }

  func test_uniqueKeys_values() {
    let s = SparseSet(
      uncheckedUniqueKeys: [0, 1, 2, 3],
      values: ["zero", "one", "two", "three"])
    expectEqualElements(s, [
      (key: 0, value: "zero"),
      (key: 1, value: "one"),
      (key: 2, value: "two"),
      (key: 3, value: "three"),
    ])
  }

  func test_uniquing_initializer_labeled_tuples() {
    let items: KeyValuePairs<Int, String> = [
      0: "a",
      1: "a",
      2: "a",
      0: "b",
      0: "c",
      1: "b",
      3: "c",
    ]
    let s = SparseSet(items, uniquingKeysWith: +)
    expectEqualElements(s, [
      (key: 0, value: "abc"),
      (key: 1, value: "ab"),
      (key: 2, value: "a"),
      (key: 3, value: "c")
    ])
  }

  func test_uniquing_initializer_unlabeled_tuples() {
    let items: [(Int, String)] = [
      (0, "a"),
      (1, "a"),
      (2, "a"),
      (0, "b"),
      (0, "c"),
      (1, "b"),
      (3, "c"),
    ]
    let s = SparseSet(items, uniquingKeysWith: +)
    expectEqualElements(s, [
      (key: 0, value: "abc"),
      (key: 1, value: "ab"),
      (key: 2, value: "a"),
      (key: 3, value: "c")
    ])
  }

  func test_uncheckedUniqueKeysWithValues_labeled_tuples() {
    let items: KeyValuePairs<Int, String> = [
      0: "zero",
      1: "one",
      2: "two",
      3: "three",
    ]
    let s = SparseSet(uncheckedUniqueKeysWithValues: items)
    expectEqualElements(s, items)
  }

  func test_uncheckedUniqueKeysWithValues_unlabeled_tuples() {
    let items: [(Int, String)] = [
      (0, "zero"),
      (1, "one"),
      (2, "two"),
      (3, "three"),
    ]
    let s = SparseSet(uncheckedUniqueKeysWithValues: items)
    expectEqualElements(s, items)
  }

  func test_uncheckedUniqueKeys_values() {
    let s = SparseSet(
      uncheckedUniqueKeys: [0, 1, 2, 3],
      values: ["zero", "one", "two", "three"])
    expectEqualElements(s, [
      (key: 0, value: "zero"),
      (key: 1, value: "one"),
      (key: 2, value: "two"),
      (key: 3, value: "three"),
    ])
  }

  func test_ExpressibleByDictionaryLiteral() {
    let s0: SparseSet<Int, String> = [:]
    expectTrue(s0.isEmpty)

    let s1: SparseSet<Int, String> = [
      1: "one",
      2: "two",
      3: "three",
      4: "four",
    ]
    expectEqualElements(s1.map { $0.key }, [1, 2, 3, 4])
    expectEqualElements(s1.map { $0.value }, ["one", "two", "three", "four"])
  }

  func test_keys() {
    let s: SparseSet = [
      1: "one",
      2: "two",
      3: "three",
      4: "four",
    ]
    expectEqual(s.keys, [1, 2, 3, 4])
  }

  func test_counts() {
    withEvery("count", in: 0 ..< 30) { count in
      withLifetimeTracking { tracker in
        let (sparseSet, _, _) = tracker.sparseSet(keys: 0 ..< count)
        expectEqual(sparseSet.isEmpty, count == 0)
        expectEqual(sparseSet.count, count)
        expectEqual(sparseSet.underestimatedCount, count)
      }
    }
  }

  func test_index_forKey() {
    withEvery("count", in: 0 ..< 30) { count in
      withLifetimeTracking { tracker in
        let (sparseSet, keys, _) = tracker.sparseSet(keys: 0 ..< count)
        withEvery("offset", in: 0 ..< count) { offset in
          expectEqual(sparseSet.index(forKey: keys[offset]), offset)
        }
        expectNil(sparseSet.index(forKey: -1))
        expectNil(sparseSet.index(forKey: count))
      }
    }
  }

  func test_subscript_getter() {
    withEvery("count", in: 0 ..< 30) { count in
      withLifetimeTracking { tracker in
        let (sparseSet, keys, values) = tracker.sparseSet(keys: 0 ..< count)
        withEvery("offset", in: 0 ..< count) { offset in
          expectEqual(sparseSet[keys[offset]], values[offset])
        }
        expectNil(sparseSet[count])
      }
    }
  }

  func test_subscript_setter_update() {
    withEvery("count", in: 0 ..< 30) { count in
      withEvery("offset", in: 0 ..< count) { offset in
        withEvery("isShared", in: [false, true]) { isShared in
          withLifetimeTracking { tracker in
            var (sparseSet, keys, values) = tracker.sparseSet(keys: 0 ..< count)
            let replacement = tracker.instance(for: -1)
            withHiddenCopies(if: isShared, of: &sparseSet) { sparseSet in
              sparseSet[keys[offset]] = replacement
              values[offset] = replacement
              withEvery("i", in: 0 ..< count) { i in
                let (k, v) = sparseSet[offset: i]
                expectEqual(k, keys[i])
                expectEqual(v, values[i])
              }
            }
          }
        }
      }
    }
  }

  func test_subscript_setter_remove() {
    withEvery("count", in: 0 ..< 30) { count in
      withEvery("offset", in: 0 ..< count) { offset in
        withEvery("isShared", in: [false, true]) { isShared in
          withLifetimeTracking { tracker in
            var (sparseSet, keys, values) = tracker.sparseSet(keys: 0 ..< count)
            withHiddenCopies(if: isShared, of: &sparseSet) { sparseSet in
              sparseSet[keys[offset]] = nil
              // Mimic expected sparse set removal: remove the element at
              // offset, replacing it with the final element.
              keys.swapAt(offset, keys.endIndex - 1)
              keys.removeLast()
              values.swapAt(offset, values.endIndex - 1)
              values.removeLast()
              withEvery("i", in: 0 ..< count - 1) { i in
                let (k, v) = sparseSet[offset: i]
                expectEqual(k, keys[i])
                expectEqual(v, values[i])
              }
            }
          }
        }
      }
    }
  }

  func test_subscript_setter_insert() {
    withEvery("count", in: 0 ..< 30) { count in
      let keys = 0 ..< count
      withEvery("isShared", in: [false, true]) { isShared in
        withLifetimeTracking { tracker in
          let values = tracker.instances(for: (0 ..< count).map { 100 + $0 })
          var sparseSet: SparseSet<Int, LifetimeTracked<Int>> = [:]
          withEvery("offset", in: 0 ..< count) { offset in
            withHiddenCopies(if: isShared, of: &sparseSet) { sparseSet in
              sparseSet[keys[offset]] = values[offset]
              withEvery("i", in: 0 ... offset) { i in
                let (k, v) = sparseSet[offset: i]
                expectEqual(k, keys[i])
                expectEqual(v, values[i])
              }
            }
          }
        }
      }
    }
  }

  func test_subscript_setter_noop() {
    withEvery("count", in: 0 ..< 30) { count in
      withEvery("isShared", in: [false, true]) { isShared in
        withLifetimeTracking { tracker in
          var (sparseSet, keys, values) = tracker.sparseSet(keys: 0 ..< count)
          let key = -1
          withHiddenCopies(if: isShared, of: &sparseSet) { sparseSet in
            sparseSet[key] = nil
          }
          withEvery("i", in: 0 ..< count) { i in
            let (k, v) = sparseSet[offset: i]
            expectEqual(k, keys[i])
            expectEqual(v, values[i])
          }
        }
      }
    }
  }

  func mutate<T, R>(
    _ value: inout T,
    _ body: (inout T) throws -> R
  ) rethrows -> R {
    try body(&value)
  }

  func test_subscript_modify_update() {
    withEvery("count", in: 0 ..< 30) { count in
      withEvery("offset", in: 0 ..< count) { offset in
        withEvery("isShared", in: [false, true]) { isShared in
          withLifetimeTracking { tracker in
            var (sparseSet, keys, values) = tracker.sparseSet(keys: 0 ..< count)
            let replacement = tracker.instance(for: -1)
            withHiddenCopies(if: isShared, of: &sparseSet) { sparseSet in
              mutate(&sparseSet[keys[offset]]) { $0 = replacement }
              values[offset] = replacement
              withEvery("i", in: 0 ..< count) { i in
                let (k, v) = sparseSet[offset: i]
                expectEqual(k, keys[i])
                expectEqual(v, values[i])
              }
            }
          }
        }
      }
    }
  }


  func test_subscript_modify_remove() {
    withEvery("count", in: 0 ..< 30) { count in
      withEvery("offset", in: 0 ..< count) { offset in
        withEvery("isShared", in: [false, true]) { isShared in
          withLifetimeTracking { tracker in
            var (sparseSet, keys, values) = tracker.sparseSet(keys: 0 ..< count)
            withHiddenCopies(if: isShared, of: &sparseSet) { sparseSet in
              let key = keys[offset]
              mutate(&sparseSet[key]) { v in
                expectEqual(v, values[offset])
                v = nil
              }
              // Mimic expected sparse set removal: remove the element at
              // offset, replacing it with the final element.
              keys.swapAt(offset, keys.endIndex - 1)
              keys.removeLast()
              values.swapAt(offset, values.endIndex - 1)
              values.removeLast()
              withEvery("i", in: 0 ..< count - 1) { i in
                let (k, v) = sparseSet[offset: i]
                expectEqual(k, keys[i])
                expectEqual(v, values[i])
              }
            }
          }
        }
      }
    }
  }

  func test_subscript_modify_insert() {
    withEvery("count", in: 0 ..< 30) { count in
      let keys = 0 ..< count
      withEvery("isShared", in: [false, true]) { isShared in
        withLifetimeTracking { tracker in
          let values = tracker.instances(for: (0 ..< count).map { 100 + $0 })
          var sparseSet: SparseSet<Int, LifetimeTracked<Int>> = [:]
          withEvery("offset", in: 0 ..< count) { offset in
            withHiddenCopies(if: isShared, of: &sparseSet) { sparseSet in
              mutate(&sparseSet[keys[offset]]) { v in
                expectNil(v)
                v = values[offset]
              }
              expectEqual(sparseSet.count, offset + 1)
              withEvery("i", in: 0 ... offset) { i in
                let (k, v) = sparseSet[offset: i]
                expectEqual(k, keys[i])
                expectEqual(v, values[i])
              }
            }
          }
        }
      }
    }
  }

  func test_subscript_modify_noop() {
    withEvery("count", in: 0 ..< 30) { count in
      withEvery("isShared", in: [false, true]) { isShared in
        withLifetimeTracking { tracker in
          var (sparseSet, keys, values) = tracker.sparseSet(keys: 0 ..< count)
          let key = -1
          withHiddenCopies(if: isShared, of: &sparseSet) { sparseSet in
            mutate(&sparseSet[key]) { v in
              expectNil(v)
              v = nil
            }
          }
          withEvery("i", in: 0 ..< count) { i in
            let (k, v) = sparseSet[offset: i]
            expectEqual(k, keys[i])
            expectEqual(v, values[i])
          }
        }
      }
    }
  }

  func test_defaulted_subscript_getter() {
    withEvery("count", in: 0 ..< 30) { count in
      withEvery("isShared", in: [false, true]) { isShared in
        withLifetimeTracking { tracker in
          let (sparseSet, keys, values) = tracker.sparseSet(keys: 0 ..< count)
          let fallback = tracker.instance(for: -1)
          withEvery("offset", in: 0 ..< count) { offset in
            let key = keys[offset]
            expectEqual(sparseSet[key, default: fallback], values[offset])
          }
          expectEqual(
            sparseSet[-1, default: fallback],
            fallback)
          expectEqual(
            sparseSet[count, default: fallback],
            fallback)
        }
      }
    }
  }

  func test_defaulted_subscript_modify_update() {
    withEvery("count", in: 0 ..< 30) { count in
      withEvery("offset", in: 0 ..< count) { offset in
        withEvery("isShared", in: [false, true]) { isShared in
          withLifetimeTracking { tracker in
            var (sparseSet, keys, values) = tracker.sparseSet(keys: 0 ..< count)
            let replacement = tracker.instance(for: -1)
            let fallback = tracker.instance(for: -1)
            withHiddenCopies(if: isShared, of: &sparseSet) { sparseSet in
              let key = keys[offset]
              mutate(&sparseSet[key, default: fallback]) { v in
                expectEqual(v, values[offset])
                v = replacement
              }
              values[offset] = replacement
              withEvery("i", in: 0 ..< count) { i in
                let (k, v) = sparseSet[offset: i]
                expectEqual(k, keys[i])
                expectEqual(v, values[i])
              }
            }
          }
        }
      }
    }
  }

  func test_defaulted_subscript_modify_insert() {
    withEvery("count", in: 0 ..< 30) { count in
      let keys = 0 ..< count
      withEvery("isShared", in: [false, true]) { isShared in
        withLifetimeTracking { tracker in
          let values = tracker.instances(for: (0 ..< count).map { 100 + $0 })
          var sparseSet: SparseSet<Int, LifetimeTracked<Int>> = [:]
          let fallback = tracker.instance(for: -1)
          withEvery("offset", in: 0 ..< count) { offset in
            withHiddenCopies(if: isShared, of: &sparseSet) { sparseSet in
              let key = keys[offset]
              mutate(&sparseSet[key, default: fallback]) { v in
                expectEqual(v, fallback)
                v = values[offset]
              }
              expectEqual(sparseSet.count, offset + 1)
              withEvery("i", in: 0 ... offset) { i in
                let (k, v) = sparseSet[offset: i]
                expectEqual(k, keys[i])
                expectEqual(v, values[i])
              }
            }
          }
        }
      }
    }
  }

  func test_updateValue_forKey_update() {
    withEvery("count", in: 0 ..< 30) { count in
      withEvery("offset", in: 0 ..< count) { offset in
        withEvery("isShared", in: [false, true]) { isShared in
          withLifetimeTracking { tracker in
            var (sparseSet, keys, values) = tracker.sparseSet(keys: 0 ..< count)
            let replacement = tracker.instance(for: -1)
            withHiddenCopies(if: isShared, of: &sparseSet) { sparseSet in
              let key = keys[offset]
              let old = sparseSet.updateValue(replacement, forKey: key)
              expectEqual(old, values[offset])
              values[offset] = replacement
              withEvery("i", in: 0 ..< count) { i in
                let (k, v) = sparseSet[offset: i]
                expectEqual(k, keys[i])
                expectEqual(v, values[i])
              }
            }
          }
        }
      }
    }
  }

  func test_updateValue_forKey_insert() {
    withEvery("count", in: 0 ..< 30) { count in
      let keys = 0 ..< count
      withEvery("isShared", in: [false, true]) { isShared in
        withLifetimeTracking { tracker in
          let values = tracker.instances(for: (0 ..< count).map { 100 + $0 })
          var sparseSet: SparseSet<Int, LifetimeTracked<Int>> = [:]
          withEvery("offset", in: 0 ..< count) { offset in
            withHiddenCopies(if: isShared, of: &sparseSet) { sparseSet in
              let key = keys[offset]
              let old = sparseSet.updateValue(values[offset], forKey: key)
              expectNil(old)
              expectEqual(sparseSet.count, offset + 1)
              withEvery("i", in: 0 ... offset) { i in
                let (k, v) = sparseSet[offset: i]
                expectEqual(k, keys[i])
                expectEqual(v, values[i])
              }
            }
          }
        }
      }
    }
  }

  func test_modifyValue_forKey_default_closure_update() {
    withEvery("count", in: 0 ..< 30) { count in
      withEvery("offset", in: 0 ..< count) { offset in
        withEvery("isShared", in: [false, true]) { isShared in
          withLifetimeTracking { tracker in
            var (sparseSet, keys, values) = tracker.sparseSet(keys: 0 ..< count)
            let replacement = tracker.instance(for: -1)
            let fallback = tracker.instance(for: -2)
            withHiddenCopies(if: isShared, of: &sparseSet) { sparseSet in
              let key = keys[offset]
              sparseSet.modifyValue(forKey: key, default: fallback) { value in
                expectEqual(value, values[offset])
                value = replacement
              }
              values[offset] = replacement
              withEvery("i", in: 0 ..< count) { i in
                let (k, v) = sparseSet[offset: i]
                expectEqual(k, keys[i])
                expectEqual(v, values[i])
              }
            }
          }
        }
      }
    }
  }

  func test_modifyValue_forKey_default_closure_insert() {
    withEvery("count", in: 0 ..< 30) { count in
      let keys = 0 ..< count
      withEvery("isShared", in: [false, true]) { isShared in
        withLifetimeTracking { tracker in
          let values = tracker.instances(for: (0 ..< count).map { 100 + $0 })
          var sparseSet: SparseSet<Int, LifetimeTracked<Int>> = [:]
          let fallback = tracker.instance(for: -2)
          withEvery("offset", in: 0 ..< count) { offset in
            withHiddenCopies(if: isShared, of: &sparseSet) { sparseSet in
              let key = keys[offset]
              sparseSet.modifyValue(forKey: key, default: fallback) { value in
                expectEqual(value, fallback)
                value = values[offset]
              }
              expectEqual(sparseSet.count, offset + 1)
              withEvery("i", in: 0 ... offset) { i in
                let (k, v) = sparseSet[offset: i]
                expectEqual(k, keys[i])
                expectEqual(v, values[i])
              }
            }
          }
        }
      }
    }
  }

  func test_removeValue_forKey() {
    withEvery("count", in: 0 ..< 30) { count in
      withEvery("offset", in: 0 ..< count) { offset in
        withEvery("isShared", in: [false, true]) { isShared in
          withLifetimeTracking { tracker in
            var (sparseSet, keys, values) = tracker.sparseSet(keys: 0 ..< count)
            withHiddenCopies(if: isShared, of: &sparseSet) { sparseSet in
              // Mimic expected sparse set removal: remove the element at
              // offset, replacing it with the final element.
              keys.swapAt(offset, keys.endIndex - 1)
              let key = keys.removeLast()
              values.swapAt(offset, values.endIndex - 1)
              let expected = values.removeLast()
              let actual = sparseSet.removeValue(forKey: key)
              expectEqual(actual, expected)
              expectEqual(sparseSet.count, values.count)
              withEvery("i", in: 0 ..< values.count) { i in
                let (k, v) = sparseSet[offset: i]
                expectEqual(k, keys[i])
                expectEqual(v, values[i])
              }
              expectNil(sparseSet.removeValue(forKey: key))
            }
          }
        }
      }
    }
  }

  func test_merge_labeled_tuple() {
    var s: SparseSet = [
      1: "a",
      2: "b",
      3: "c",
    ]

    let items: KeyValuePairs = [
      1: "d",
      1: "e",
      3: "f",
      4: "g",
      1: "h",
    ]

    s.merge(items, uniquingKeysWith: +)

    expectEqualElements(s, [
      1: "adeh",
      2: "b",
      3: "cf",
      4: "g",
    ] as KeyValuePairs)
  }

  func test_merge_unlabeled_tuple() {
    var s: SparseSet = [
      1: "a",
      2: "b",
      3: "c",
    ]

    let items: [(Int, String)] = [
      (1, "d"),
      (1, "e"),
      (3, "f"),
      (4, "g"),
      (1, "h"),
    ]

    s.merge(items, uniquingKeysWith: +)

    expectEqualElements(s, [
      1: "adeh",
      2: "b",
      3: "cf",
      4: "g",
    ] as KeyValuePairs)
  }

  func test_merging_labeled_tuple() {
    let s: SparseSet = [
      1: "a",
      2: "b",
      3: "c",
    ]

    let items: KeyValuePairs = [
      1: "d",
      1: "e",
      3: "f",
      4: "g",
      1: "h",
    ]

    let s2 = s.merging(items, uniquingKeysWith: +)

    expectEqualElements(s, [
      1: "a",
      2: "b",
      3: "c",
    ] as KeyValuePairs)

    expectEqualElements(s2, [
      1: "adeh",
      2: "b",
      3: "cf",
      4: "g",
    ] as KeyValuePairs)
  }

  func test_merging_unlabeled_tuple() {
    let s: SparseSet = [
      1: "a",
      2: "b",
      3: "c",
    ]

    let items: [(Int, String)] = [
      (1, "d"),
      (1, "e"),
      (3, "f"),
      (4, "g"),
      (1, "h"),
    ]

    let s2 = s.merging(items, uniquingKeysWith: +)

    expectEqualElements(s, [
      1: "a",
      2: "b",
      3: "c",
    ] as KeyValuePairs)

    expectEqualElements(s2, [
      1: "adeh",
      2: "b",
      3: "cf",
      4: "g",
    ] as KeyValuePairs)
  }

  func test_filter() {
    let items = (0 ..< 100).map { ($0, 100 * $0) }
    let s = SparseSet(uniqueKeysWithValues: items)

    var c = 0
    let s2 = s.filter { item in
      c += 1
      expectEqual(item.value, 100 * item.key)
      return item.key.isMultiple(of: 2)
    }
    expectEqual(c, 100)
    expectEqualElements(s, items)

    expectEqualElements(s2, (0 ..< 50).compactMap { key in
      return (key: 2 * key, value: 200 * key)
    })
  }

  func test_mapValues() {
    let items = (0 ..< 100).map { ($0, 100 * $0) }
    let s = SparseSet(uniqueKeysWithValues: items)

    var c = 0
    let s2 = s.mapValues { value -> String in
      c += 1
      expectTrue(value.isMultiple(of: 100))
      return "\(value)"
    }
    expectEqual(c, 100)
    expectEqualElements(s, items)

    expectEqualElements(s2, (0 ..< 100).compactMap { key in
      (key: key, value: "\(100 * key)")
    })
  }

  func test_compactMapValue() {
    let items = (0 ..< 100).map { ($0, 100 * $0) }
    let s = SparseSet(uniqueKeysWithValues: items)

    var c = 0
    let s2 = s.compactMapValues { value -> String? in
      c += 1
      guard value.isMultiple(of: 200) else { return nil }
      expectTrue(value.isMultiple(of: 100))
      return "\(value)"
    }
    expectEqual(c, 100)
    expectEqualElements(s, items)

    expectEqualElements(s2, (0 ..< 50).map { key in
      (key: 2 * key, value: "\(200 * key)")
    })
  }

  func test_CustomStringConvertible() {
    let a: SparseSet<Int, Int> = [:]
    expectEqual(a.description, "[:]")

    let b: SparseSet<Int, Int> = [0: 1]
    expectEqual(b.description, "[0: 1]")

    let c: SparseSet<Int, Int> = [0: 1, 2: 3, 4: 5]
    expectEqual(c.description, "[0: 1, 2: 3, 4: 5]")
  }

  func test_CustomDebugStringConvertible() {
    let a: SparseSet<Int, Int> = [:]
    expectEqual(a.debugDescription,
                "SparseSet<Int, Int>([:])")

    let b: SparseSet<Int, Int> = [0: 1]
    expectEqual(b.debugDescription,
                "SparseSet<Int, Int>([0: 1])")

    let c: SparseSet<Int, Int> = [0: 1, 2: 3, 4: 5]
    expectEqual(c.debugDescription,
                "SparseSet<Int, Int>([0: 1, 2: 3, 4: 5])")
  }

  func test_Equatable_Hashable() {
    let samples: [[SparseSet<Int, Int>]] = [
      [[:], [:]],
      [[1: 100], [1: 100]],
      [[2: 200], [2: 200]],
      [[3: 300], [3: 300]],
      [[100: 1], [100: 1]],
      [[1: 1], [1: 1]],
      [[100: 100], [100: 100]],
      [[1: 100, 2: 200], [1: 100, 2: 200]],
      [[2: 200, 1: 100], [2: 200, 1: 100]],
      [[1: 100, 2: 200, 3: 300], [1: 100, 2: 200, 3: 300]],
      [[2: 200, 1: 100, 3: 300], [2: 200, 1: 100, 3: 300]],
      [[3: 300, 2: 200, 1: 100], [3: 300, 2: 200, 1: 100]],
      [[3: 300, 1: 100, 2: 200], [3: 300, 1: 100, 2: 200]]
    ]
    checkHashable(equivalenceClasses: samples)
  }

  func test_Encodable() throws {
    let s1: SparseSet<Int, Int> = [:]
    let v1: MinimalEncoder.Value = .array([])
    expectEqual(try MinimalEncoder.encode(s1), v1)

    let s2: SparseSet<Int, Int> = [0: 1]
    let v2: MinimalEncoder.Value = .array([.int(0), .int(1)])
    expectEqual(try MinimalEncoder.encode(s2), v2)

    let s3: SparseSet<Int, Int> = [0: 1, 2: 3]
    let v3: MinimalEncoder.Value =
      .array([.int(0), .int(1), .int(2), .int(3)])
    expectEqual(try MinimalEncoder.encode(s3), v3)

    let s4 = SparseSet(
      uniqueKeys: 0 ..< 100,
      values: (0 ..< 100).map { 100 * $0 })
    let v4: MinimalEncoder.Value =
      .array((0 ..< 100).flatMap { [.int($0), .int(100 * $0)] })
    expectEqual(try MinimalEncoder.encode(s4), v4)
  }

  func test_Decodable() throws {
    typealias SSII = SparseSet<Int, Int>

    let s1: SSII = [:]
    let v1: MinimalEncoder.Value = .array([])
    expectEqual(try MinimalDecoder.decode(v1, as: SSII.self), s1)

    let s2: SSII = [0: 1]
    let v2: MinimalEncoder.Value = .array([.int(0), .int(1)])
    expectEqual(try MinimalDecoder.decode(v2, as: SSII.self), s2)

    let s3: SSII = [0: 1, 2: 3]
    let v3: MinimalEncoder.Value =
      .array([.int(0), .int(1), .int(2), .int(3)])
    expectEqual(try MinimalDecoder.decode(v3, as: SSII.self), s3)

    let s4: SSII = SparseSet(
      uniqueKeys: 0 ..< 100,
      values: (0 ..< 100).map { 100 * $0 })
    let v4: MinimalEncoder.Value =
      .array((0 ..< 100).flatMap { [.int($0), .int(100 * $0)] })
    expectEqual(try MinimalDecoder.decode(v4, as: SSII.self), s4)

    let v5: MinimalEncoder.Value = .array([.int(0), .int(1), .int(2)])
    expectThrows(try MinimalDecoder.decode(v5, as: SSII.self)) { error in
      guard case DecodingError.dataCorrupted(let context) = error else {
        expectFailure("Unexpected error \(error)")
        return
      }
      expectEqual(context.debugDescription,
                  "Unkeyed container reached end before value in key-value pair")

    }

    let v6: MinimalEncoder.Value = .array([.int(0), .int(1), .int(0), .int(2)])
    expectThrows(try MinimalDecoder.decode(v6, as: SSII.self)) { error in
      guard case DecodingError.dataCorrupted(let context) = error else {
        expectFailure("Unexpected error \(error)")
        return
      }
      expectEqual(context.debugDescription, "Duplicate key at offset 2")
    }
  }

  func test_swapAt() {
    withEvery("count", in: 0 ..< 20) { count in
      withEvery("i", in: 0 ..< count) { i in
        withEvery("j", in: 0 ..< count) { j in
          withEvery("isShared", in: [false, true]) { isShared in
            withLifetimeTracking { tracker in
              var (sparseSet, keys, values) = tracker.sparseSet(keys: 0 ..< count)
              keys.swapAt(i, j)
              values.swapAt(i, j)
              withHiddenCopies(if: isShared, of: &sparseSet) { sparseSet in
                sparseSet.swapAt(i, j)
                expectEqualElements(sparseSet.values, values)
                expectEqual(sparseSet[keys[i]], values[i])
                expectEqual(sparseSet[keys[j]], values[j])
              }
            }
          }
        }
      }
    }
  }

  func test_partition() {
    withEvery("seed", in: 0 ..< 10) { seed in
      withEvery("count", in: 0 ..< 30) { count in
        withEvery("isShared", in: [false, true]) { isShared in
          withLifetimeTracking { tracker in
            var rng = RepeatableRandomNumberGenerator(seed: seed)
            var (sparseSet, keys, values) = tracker.sparseSet(
              keys: (0 ..< count).shuffled(using: &rng))
            var items = Array(zip(keys, values))
            let expectedPivot = items.partition { $0.0 < count / 2 }
            withHiddenCopies(if: isShared, of: &sparseSet) { sparseSet in
              let actualPivot = sparseSet.partition { $0.key < count / 2 }
              expectEqual(actualPivot, expectedPivot)
              expectEqualElements(sparseSet, items)
            }
          }
        }
      }
    }
  }

  func test_sort() {
    withEvery("seed", in: 0 ..< 10) { seed in
      withEvery("count", in: 0 ..< 30) { count in
        withEvery("isShared", in: [false, true]) { isShared in
          withLifetimeTracking { tracker in
            var rng = RepeatableRandomNumberGenerator(seed: seed)
            var (sparseSet, keys, values) = tracker.sparseSet(
              keys: (0 ..< count).shuffled(using: &rng))
            var items = Array(zip(keys, values))
            items.sort(by: { $0.0 < $1.0 })
            withHiddenCopies(if: isShared, of: &sparseSet) { sparseSet in
              sparseSet.sort()
              expectEqualElements(sparseSet, items)
            }
          }
        }
      }
    }
  }

  func test_sort_by() {
    withEvery("seed", in: 0 ..< 10) { seed in
      withEvery("count", in: 0 ..< 30) { count in
        withEvery("isShared", in: [false, true]) { isShared in
          withLifetimeTracking { tracker in
            var rng = RepeatableRandomNumberGenerator(seed: seed)
            var (sparseSet, keys, values) = tracker.sparseSet(
              keys: (0 ..< count).shuffled(using: &rng))
            var items = Array(zip(keys, values))
            items.sort(by: { $0.0 > $1.0 })
            withHiddenCopies(if: isShared, of: &sparseSet) { sparseSet in
              sparseSet.sort(by: { $0.key > $1.key })
              expectEqualElements(sparseSet, items)
            }
          }
        }
      }
    }
  }

  func test_shuffle() {
    withEvery("count", in: 0 ..< 30) { count in
      withEvery("isShared", in: [false, true]) { isShared in
        withEvery("seed", in: 0 ..< 10) { seed in
          var sparseSet = SparseSet(
            uniqueKeys: 0 ..< count,
            values: 100 ..< 100 + count)
          var items = (0 ..< count).map { (key: $0, value: 100 + $0) }
          withHiddenCopies(if: isShared, of: &sparseSet) { sparseSet in
            expectEqualElements(sparseSet, items)

            var rng1 = RepeatableRandomNumberGenerator(seed: seed)
            items.shuffle(using: &rng1)

            var rng2 = RepeatableRandomNumberGenerator(seed: seed)
            sparseSet.shuffle(using: &rng2)

            items.sort(by: { $0.key < $1.key })
            sparseSet.sort()
            expectEqualElements(sparseSet, items)
          }
        }
      }
      if count >= 2 {
        // Check that shuffling with the system RNG does permute the elements.
        var sparseSet = SparseSet(
          uniqueKeys: 0 ..< count,
          values: 100 ..< 100 + count)
        let original = sparseSet
        var success = false
        for _ in 0 ..< 1000 {
          sparseSet.shuffle()
          if !sparseSet.elementsEqual(
            original,
            by: { $0.key == $1.key && $0.value == $1.value}
          ) {
            success = true
            break
          }
        }
        expectTrue(success)
      }
    }
  }

  func test_reverse() {
    withEvery("count", in: 0 ..< 30) { count in
      withEvery("isShared", in: [false, true]) { isShared in
        withLifetimeTracking { tracker in
          var (sparseSet, keys, values) = tracker.sparseSet(keys: 0 ..< count)
          var items = Array(zip(keys, values))
          withHiddenCopies(if: isShared, of: &sparseSet) { sparseSet in
            items.reverse()
            sparseSet.reverse()
            expectEqualElements(sparseSet, items)
          }
        }
      }
    }
  }

  func test_removeAll() {
    withEvery("count", in: 0 ..< 30) { count in
      withEvery("isShared", in: [false, true]) { isShared in
        withLifetimeTracking { tracker in
          var (sparseSet, _, _) = tracker.sparseSet(keys: 0 ..< count)
          withHiddenCopies(if: isShared, of: &sparseSet) { sparseSet in
            sparseSet.removeAll()
            expectEqual(sparseSet.universeSize, 0)
            expectEqualElements(sparseSet, [])
          }
        }
      }
    }
  }

  func test_removeAll_keepCapacity() {
    withEvery("count", in: 0 ..< 30) { count in
      withEvery("isShared", in: [false, true]) { isShared in
        withLifetimeTracking { tracker in
          var (sparseSet, _, _) = tracker.sparseSet(keys: 0 ..< count)
          let origUniverseSize = sparseSet.universeSize
          withHiddenCopies(if: isShared, of: &sparseSet) { sparseSet in
            sparseSet.removeAll(keepingCapacity: true)
            expectEqual(sparseSet.universeSize, origUniverseSize)
            expectEqualElements(sparseSet, [])
          }
        }
      }
    }
  }
}
