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
@_spi(Testing) import OrderedCollections

import CollectionsTestSupport

class OrderedDictionaryTests: CollectionTestCase {
  func test_empty() {
    let d = OrderedDictionary<String, Int>()
    expectEqualElements(d, [])
    expectEqual(d.count, 0)
  }

  func test_init_minimumCapacity() {
    let d = OrderedDictionary<String, Int>(minimumCapacity: 1000)
    expectGreaterThanOrEqual(d.keys.__unstable.capacity, 1000)
    expectGreaterThanOrEqual(d.values.elements.capacity, 1000)
    expectEqual(d.keys.__unstable.reservedScale, 0)
  }

  func test_init_minimumCapacity_persistent() {
    let d = OrderedDictionary<String, Int>(minimumCapacity: 1000, persistent: true)
    expectGreaterThanOrEqual(d.keys.__unstable.capacity, 1000)
    expectGreaterThanOrEqual(d.values.elements.capacity, 1000)
    expectNotEqual(d.keys.__unstable.reservedScale, 0)
  }

  func test_uniqueKeysWithValues_Dictionary() {
    let items: Dictionary<String, Int> = [
      "zero": 0,
      "one": 1,
      "two": 2,
      "three": 3,
    ]
    let d = OrderedDictionary(uncheckedUniqueKeysWithValues: items)
    expectEqualElements(d, items)
  }

  func test_uniqueKeysWithValues_labeled_tuples() {
    let items: KeyValuePairs<String, Int> = [
      "zero": 0,
      "one": 1,
      "two": 2,
      "three": 3,
    ]
    let d = OrderedDictionary(uncheckedUniqueKeysWithValues: items)
    expectEqualElements(d, items)
  }

  func test_uniqueKeysWithValues_unlabeled_tuples() {
    let items: [(String, Int)] = [
      ("zero", 0),
      ("one", 1),
      ("two", 2),
      ("three", 3),
    ]
    let d = OrderedDictionary(uncheckedUniqueKeysWithValues: items)
    expectEqualElements(d, items)
  }

  func test_uniqueKeys_values() {
    let d = OrderedDictionary(
    uncheckedUniqueKeys: ["zero", "one", "two", "three"],
      values: [0, 1, 2, 3])
    expectEqualElements(d, [
      (key: "zero", value: 0),
      (key: "one", value: 1),
      (key: "two", value: 2),
      (key: "three", value: 3),
    ])
  }

  func test_uniquing_initializer_labeled_tuples() {
    let items: KeyValuePairs<String, Int> = [
      "a": 1,
      "b": 1,
      "c": 1,
      "a": 2,
      "a": 2,
      "b": 1,
      "d": 3,
    ]
    let d = OrderedDictionary(items, uniquingKeysWith: +)
    expectEqualElements(d, [
      (key: "a", value: 5),
      (key: "b", value: 2),
      (key: "c", value: 1),
      (key: "d", value: 3)
    ])
  }

  func test_uniquing_initializer_unlabeled_tuples() {
    let items: [(String, Int)] = [
      ("a", 1),
      ("b", 1),
      ("c", 1),
      ("a", 2),
      ("a", 2),
      ("b", 1),
      ("d", 3),
    ]
    let d = OrderedDictionary(items, uniquingKeysWith: +)
    expectEqualElements(d, [
      (key: "a", value: 5),
      (key: "b", value: 2),
      (key: "c", value: 1),
      (key: "d", value: 3)
    ])
  }

  func test_grouping_initializer() {
    let items: [String] = [
      "one", "two", "three", "four", "five",
      "six", "seven", "eight", "nine", "ten"
    ]
    let d = OrderedDictionary<Int, [String]>(grouping: items, by: { $0.count })
    expectEqualElements(d, [
      (key: 3, value: ["one", "two", "six", "ten"]),
      (key: 5, value: ["three", "seven", "eight"]),
      (key: 4, value: ["four", "five", "nine"]),
    ])
  }

  func test_uncheckedUniqueKeysWithValues_labeled_tuples() {
    let items: KeyValuePairs<String, Int> = [
      "zero": 0,
      "one": 1,
      "two": 2,
      "three": 3,
    ]
    let d = OrderedDictionary(uncheckedUniqueKeysWithValues: items)
    expectEqualElements(d, items)
  }

  func test_uncheckedUniqueKeysWithValues_unlabeled_tuples() {
    let items: [(String, Int)] = [
      ("zero", 0),
      ("one", 1),
      ("two", 2),
      ("three", 3),
    ]
    let d = OrderedDictionary(uncheckedUniqueKeysWithValues: items)
    expectEqualElements(d, items)
  }

  func test_uncheckedUniqueKeys_values() {
    let d = OrderedDictionary(
    uncheckedUniqueKeys: ["zero", "one", "two", "three"],
      values: [0, 1, 2, 3])
    expectEqualElements(d, [
      (key: "zero", value: 0),
      (key: "one", value: 1),
      (key: "two", value: 2),
      (key: "three", value: 3),
    ])
  }

  func test_ExpressibleByDictionaryLiteral() {
    let d0: OrderedDictionary<String, Int> = [:]
    expectTrue(d0.isEmpty)

    let d1: OrderedDictionary<String, Int> = [
      "one": 1,
      "two": 2,
      "three": 3,
      "four": 4,
    ]
    expectEqualElements(d1.map { $0.key }, ["one", "two", "three", "four"])
    expectEqualElements(d1.map { $0.value }, [1, 2, 3, 4])
  }

  func test_keys() {
    let d: OrderedDictionary = [
      "one": 1,
      "two": 2,
      "three": 3,
      "four": 4,
    ]
    expectEqual(d.keys, ["one", "two", "three", "four"] as OrderedSet)
  }

  func test_counts() {
    withEvery("count", in: 0 ..< 30) { count in
      withLifetimeTracking { tracker in
        let (d, _, _) = tracker.orderedDictionary(keys: 0 ..< count)
        expectEqual(d.isEmpty, count == 0)
        expectEqual(d.count, count)
        expectEqual(d.underestimatedCount, count)
      }
    }
  }

  func test_index_forKey() {
    withEvery("count", in: 0 ..< 30) { count in
      withLifetimeTracking { tracker in
        let (d, keys, _) = tracker.orderedDictionary(keys: 0 ..< count)
        withEvery("offset", in: 0 ..< count) { offset in
          expectEqual(d.index(forKey: keys[offset]), offset)
        }
        expectNil(d.index(forKey: tracker.instance(for: -1)))
        expectNil(d.index(forKey: tracker.instance(for: count)))
      }
    }
  }

  func test_subscript_offset() {
    withEvery("count", in: 0 ..< 30) { count in
      withLifetimeTracking { tracker in
        let (d, keys, values) = tracker.orderedDictionary(keys: 0 ..< count)
        withEvery("offset", in: 0 ..< count) { offset in
          let item = d[offset: offset]
          expectEqual(item.key, keys[offset])
          expectEqual(item.value, values[offset])
        }
      }
    }
  }

  func test_subscript_getter() {
    withEvery("count", in: 0 ..< 30) { count in
      withLifetimeTracking { tracker in
        let (d, keys, values) = tracker.orderedDictionary(keys: 0 ..< count)
        withEvery("offset", in: 0 ..< count) { offset in
          expectEqual(d[keys[offset]], values[offset])
        }
        expectNil(d[tracker.instance(for: -1)])
        expectNil(d[tracker.instance(for: count)])
      }
    }
  }

  func test_subscript_setter_update() {
    withEvery("count", in: 0 ..< 30) { count in
      withEvery("offset", in: 0 ..< count) { offset in
        withEvery("isShared", in: [false, true]) { isShared in
          withLifetimeTracking { tracker in
            var (d, keys, values) = tracker.orderedDictionary(keys: 0 ..< count)
            let replacement = tracker.instance(for: -1)
            withHiddenCopies(if: isShared, of: &d) { d in
              d[keys[offset]] = replacement
              values[offset] = replacement
              withEvery("i", in: 0 ..< count) { i in
                let (k, v) = d[offset: i]
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
            var (d, keys, values) = tracker.orderedDictionary(keys: 0 ..< count)
            withHiddenCopies(if: isShared, of: &d) { d in
              d[keys[offset]] = nil
              keys.remove(at: offset)
              values.remove(at: offset)
              withEvery("i", in: 0 ..< count - 1) { i in
                let (k, v) = d[offset: i]
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
      withEvery("isShared", in: [false, true]) { isShared in
        withLifetimeTracking { tracker in
          let keys = tracker.instances(for: 0 ..< count)
          let values = tracker.instances(for: (0 ..< count).map { 100 + $0 })
          var d: OrderedDictionary<LifetimeTracked<Int>, LifetimeTracked<Int>> = [:]
          withEvery("offset", in: 0 ..< count) { offset in
            withHiddenCopies(if: isShared, of: &d) { d in
              d[keys[offset]] = values[offset]
              withEvery("i", in: 0 ... offset) { i in
                let (k, v) = d[offset: i]
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
          var (d, keys, values) = tracker.orderedDictionary(keys: 0 ..< count)
          let key = tracker.instance(for: -1)
          withHiddenCopies(if: isShared, of: &d) { d in
            d[key] = nil
          }
          withEvery("i", in: 0 ..< count) { i in
            let (k, v) = d[offset: i]
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
            var (d, keys, values) = tracker.orderedDictionary(keys: 0 ..< count)
            let replacement = tracker.instance(for: -1)
            withHiddenCopies(if: isShared, of: &d) { d in
              mutate(&d[keys[offset]]) { $0 = replacement }
              values[offset] = replacement
              withEvery("i", in: 0 ..< count) { i in
                let (k, v) = d[offset: i]
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
            var (d, keys, values) = tracker.orderedDictionary(keys: 0 ..< count)
            withHiddenCopies(if: isShared, of: &d) { d in
              let key = keys[offset]
              mutate(&d[key]) { v in
                expectEqual(v, values[offset])
                v = nil
              }
              keys.remove(at: offset)
              values.remove(at: offset)
              withEvery("i", in: 0 ..< count - 1) { i in
                let (k, v) = d[offset: i]
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
      withEvery("isShared", in: [false, true]) { isShared in
        withLifetimeTracking { tracker in
          let keys = tracker.instances(for: 0 ..< count)
          let values = tracker.instances(for: (0 ..< count).map { 100 + $0 })
          var d: OrderedDictionary<LifetimeTracked<Int>, LifetimeTracked<Int>> = [:]
          withEvery("offset", in: 0 ..< count) { offset in
            withHiddenCopies(if: isShared, of: &d) { d in
              mutate(&d[keys[offset]]) { v in
                expectNil(v)
                v = values[offset]
              }
              expectEqual(d.count, offset + 1)
              withEvery("i", in: 0 ... offset) { i in
                let (k, v) = d[offset: i]
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
          var (d, keys, values) = tracker.orderedDictionary(keys: 0 ..< count)
          let key = tracker.instance(for: -1)
          withHiddenCopies(if: isShared, of: &d) { d in
            mutate(&d[key]) { v in
              expectNil(v)
              v = nil
            }
          }
          withEvery("i", in: 0 ..< count) { i in
            let (k, v) = d[offset: i]
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
          let (d, keys, values) = tracker.orderedDictionary(keys: 0 ..< count)
          let fallback = tracker.instance(for: -1)
          withEvery("offset", in: 0 ..< count) { offset in
            let key = keys[offset]
            expectEqual(d[key, default: fallback], values[offset])
          }
          expectEqual(
            d[tracker.instance(for: -1), default: fallback],
            fallback)
          expectEqual(
            d[tracker.instance(for: count), default: fallback],
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
            var (d, keys, values) = tracker.orderedDictionary(keys: 0 ..< count)
            let replacement = tracker.instance(for: -1)
            let fallback = tracker.instance(for: -1)
            withHiddenCopies(if: isShared, of: &d) { d in
              let key = keys[offset]
              mutate(&d[key, default: fallback]) { v in
                expectEqual(v, values[offset])
                v = replacement
              }
              values[offset] = replacement
              withEvery("i", in: 0 ..< count) { i in
                let (k, v) = d[offset: i]
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
      withEvery("isShared", in: [false, true]) { isShared in
        withLifetimeTracking { tracker in
          let keys = tracker.instances(for: 0 ..< count)
          let values = tracker.instances(for: (0 ..< count).map { 100 + $0 })
          var d: OrderedDictionary<LifetimeTracked<Int>, LifetimeTracked<Int>> = [:]
          let fallback = tracker.instance(for: -1)
          withEvery("offset", in: 0 ..< count) { offset in
            withHiddenCopies(if: isShared, of: &d) { d in
              let key = keys[offset]
              mutate(&d[key, default: fallback]) { v in
                expectEqual(v, fallback)
                v = values[offset]
              }
              expectEqual(d.count, offset + 1)
              withEvery("i", in: 0 ... offset) { i in
                let (k, v) = d[offset: i]
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
            var (d, keys, values) = tracker.orderedDictionary(keys: 0 ..< count)
            let replacement = tracker.instance(for: -1)
            withHiddenCopies(if: isShared, of: &d) { d in
              let key = keys[offset]
              let old = d.updateValue(replacement, forKey: key)
              expectEqual(old, values[offset])
              values[offset] = replacement
              withEvery("i", in: 0 ..< count) { i in
                let (k, v) = d[offset: i]
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
      withEvery("isShared", in: [false, true]) { isShared in
        withLifetimeTracking { tracker in
          let keys = tracker.instances(for: 0 ..< count)
          let values = tracker.instances(for: (0 ..< count).map { 100 + $0 })
          var d: OrderedDictionary<LifetimeTracked<Int>, LifetimeTracked<Int>> = [:]
          withEvery("offset", in: 0 ..< count) { offset in
            withHiddenCopies(if: isShared, of: &d) { d in
              let key = keys[offset]
              let old = d.updateValue(values[offset], forKey: key)
              expectNil(old)
              expectEqual(d.count, offset + 1)
              withEvery("i", in: 0 ... offset) { i in
                let (k, v) = d[offset: i]
                expectEqual(k, keys[i])
                expectEqual(v, values[i])
              }
            }
          }
        }
      }
    }
  }

  func test_updateValue_forKey_insertingAt_update() {
    withEvery("count", in: 0 ..< 30) { count in
      withEvery("offset", in: 0 ..< count) { offset in
        withEvery("isShared", in: [false, true]) { isShared in
          withLifetimeTracking { tracker in
            var (d, keys, values) = tracker.orderedDictionary(keys: 0 ..< count)
            let replacement = tracker.instance(for: -1)
            withHiddenCopies(if: isShared, of: &d) { d in
              let key = keys[offset]
              let (old, index) =
                d.updateValue(replacement, forKey: key, insertingAt: 0)
              expectEqual(old, values[offset])
              expectEqual(index, offset)
              values[offset] = replacement
              withEvery("i", in: 0 ..< count) { i in
                let (k, v) = d[offset: i]
                expectEqual(k, keys[i])
                expectEqual(v, values[i])
              }
            }
          }
        }
      }
    }
  }

  func test_updateValue_forKey_insertingAt_insert() {
    withEvery("count", in: 0 ..< 30) { count in
      withEvery("isShared", in: [false, true]) { isShared in
        withLifetimeTracking { tracker in
          let keys = tracker.instances(for: 0 ..< count)
          let values = tracker.instances(for: (0 ..< count).map { 100 + $0 })
          var d: OrderedDictionary<LifetimeTracked<Int>, LifetimeTracked<Int>> = [:]
          withEvery("offset", in: 0 ..< count) { offset in
            withHiddenCopies(if: isShared, of: &d) { d in
              let key = keys[count - 1 - offset]
              let value = values[count - 1 - offset]
              let (old, index) =
                d.updateValue(value, forKey: key, insertingAt: 0)
              expectNil(old)
              expectEqual(index, 0)
              expectEqual(d.count, offset + 1)
              withEvery("i", in: 0 ... offset) { i in
                let (k, v) = d[offset: i]
                expectEqual(k, keys[count - 1 - offset + i])
                expectEqual(v, values[count - 1 - offset + i])
              }
            }
          }
        }
      }
    }
  }

  func test_updateValue_forKey_default_closure_update() {
    withEvery("count", in: 0 ..< 30) { count in
      withEvery("offset", in: 0 ..< count) { offset in
        withEvery("isShared", in: [false, true]) { isShared in
          withLifetimeTracking { tracker in
            var (d, keys, values) = tracker.orderedDictionary(keys: 0 ..< count)
            let replacement = tracker.instance(for: -1)
            let fallback = tracker.instance(for: -2)
            withHiddenCopies(if: isShared, of: &d) { d in
              let key = keys[offset]
              d.updateValue(forKey: key, default: fallback) { value in
                expectEqual(value, values[offset])
                value = replacement
              }
              values[offset] = replacement
              withEvery("i", in: 0 ..< count) { i in
                let (k, v) = d[offset: i]
                expectEqual(k, keys[i])
                expectEqual(v, values[i])
              }
            }
          }
        }
      }
    }
  }

  func test_updateValue_forKey_default_closure_insert() {
    withEvery("count", in: 0 ..< 30) { count in
      withEvery("isShared", in: [false, true]) { isShared in
        withLifetimeTracking { tracker in
          let keys = tracker.instances(for: 0 ..< count)
          let values = tracker.instances(for: (0 ..< count).map { 100 + $0 })
          var d: OrderedDictionary<LifetimeTracked<Int>, LifetimeTracked<Int>> = [:]
          let fallback = tracker.instance(for: -2)
          withEvery("offset", in: 0 ..< count) { offset in
            withHiddenCopies(if: isShared, of: &d) { d in
              let key = keys[offset]
              d.updateValue(forKey: key, default: fallback) { value in
                expectEqual(value, fallback)
                value = values[offset]
              }
              expectEqual(d.count, offset + 1)
              withEvery("i", in: 0 ... offset) { i in
                let (k, v) = d[offset: i]
                expectEqual(k, keys[i])
                expectEqual(v, values[i])
              }
            }
          }
        }
      }
    }
  }

  func test_updateValue_forKey_insertingDefault_at_closure_update() {
    withEvery("count", in: 0 ..< 30) { count in
      withEvery("offset", in: 0 ..< count) { offset in
        withEvery("isShared", in: [false, true]) { isShared in
          withLifetimeTracking { tracker in
            var (d, keys, values) = tracker.orderedDictionary(keys: 0 ..< count)
            let replacement = tracker.instance(for: -1)
            let fallback = tracker.instance(for: -2)
            withHiddenCopies(if: isShared, of: &d) { d in
              let key = keys[offset]
              let value = values[offset]
              d.updateValue(forKey: key, insertingDefault: fallback, at: 0) { v in
                expectEqual(v, value)
                v = replacement
              }
              values[offset] = replacement
              withEvery("i", in: 0 ..< count) { i in
                let (k, v) = d[offset: i]
                expectEqual(k, keys[i])
                expectEqual(v, values[i])
              }
            }
          }
        }
      }
    }
  }

  func test_updateValue_forKey_insertingDefault_at_closure_insert() {
    withEvery("count", in: 0 ..< 30) { count in
      withEvery("isShared", in: [false, true]) { isShared in
        withLifetimeTracking { tracker in
          let keys = tracker.instances(for: 0 ..< count)
          let values = tracker.instances(for: (0 ..< count).map { 100 + $0 })
          var d: OrderedDictionary<LifetimeTracked<Int>, LifetimeTracked<Int>> = [:]
          let fallback = tracker.instance(for: -2)
          withEvery("offset", in: 0 ..< count) { offset in
            withHiddenCopies(if: isShared, of: &d) { d in
              let key = keys[count - 1 - offset]
              let value = values[count - 1 - offset]
              d.updateValue(forKey: key, insertingDefault: fallback, at: 0) { v in
                expectEqual(v, fallback)
                v = value
              }
              expectEqual(d.count, offset + 1)
              withEvery("i", in: 0 ... offset) { i in
                let (k, v) = d[offset: i]
                expectEqual(k, keys[count - 1 - offset + i])
                expectEqual(v, values[count - 1 - offset + i])
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
            var (d, keys, values) = tracker.orderedDictionary(keys: 0 ..< count)
            withHiddenCopies(if: isShared, of: &d) { d in
              let key = keys.remove(at: offset)
              let expected = values.remove(at: offset)
              let actual = d.removeValue(forKey: key)
              expectEqual(actual, expected)

              expectEqual(d.count, values.count)
              withEvery("i", in: 0 ..< values.count) { i in
                let (k, v) = d[offset: i]
                expectEqual(k, keys[i])
                expectEqual(v, values[i])
              }
              expectNil(d.removeValue(forKey: key))
            }
          }
        }
      }
    }
  }

  func test_merge_labeled_tuple() {
    var d: OrderedDictionary = [
      "one": 1,
      "two": 1,
      "three": 1,
    ]

    let items: KeyValuePairs = [
      "one": 1,
      "one": 1,
      "three": 1,
      "four": 1,
      "one": 1,
    ]

    d.merge(items, uniquingKeysWith: +)

    expectEqualElements(d, [
      "one": 4,
      "two": 1,
      "three": 2,
      "four": 1,
    ] as KeyValuePairs)
  }

  func test_merge_unlabeled_tuple() {
    var d: OrderedDictionary = [
      "one": 1,
      "two": 1,
      "three": 1,
    ]

    let items: [(String, Int)] = [
      ("one", 1),
      ("one", 1),
      ("three", 1),
      ("four", 1),
      ("one", 1),
    ]

    d.merge(items, uniquingKeysWith: +)

    expectEqualElements(d, [
      "one": 4,
      "two": 1,
      "three": 2,
      "four": 1,
    ] as KeyValuePairs)
  }

  func test_merging_labeled_tuple() {
    let d: OrderedDictionary = [
      "one": 1,
      "two": 1,
      "three": 1,
    ]

    let items: KeyValuePairs = [
      "one": 1,
      "one": 1,
      "three": 1,
      "four": 1,
      "one": 1,
    ]

    let d2 = d.merging(items, uniquingKeysWith: +)

    expectEqualElements(d, [
      "one": 1,
      "two": 1,
      "three": 1,
    ] as KeyValuePairs)

    expectEqualElements(d2, [
      "one": 4,
      "two": 1,
      "three": 2,
      "four": 1,
    ] as KeyValuePairs)
  }

  func test_merging_unlabeled_tuple() {
    let d: OrderedDictionary = [
      "one": 1,
      "two": 1,
      "three": 1,
    ]

    let items: [(String, Int)] = [
      ("one", 1),
      ("one", 1),
      ("three", 1),
      ("four", 1),
      ("one", 1),
    ]

    let d2 = d.merging(items, uniquingKeysWith: +)

    expectEqualElements(d, [
      "one": 1,
      "two": 1,
      "three": 1,
    ] as KeyValuePairs)

    expectEqualElements(d2, [
      "one": 4,
      "two": 1,
      "three": 2,
      "four": 1,
    ] as KeyValuePairs)
  }

  func test_filter() {
    let items = (0 ..< 100).map { ($0, 100 * $0) }
    let d = OrderedDictionary(uniqueKeysWithValues: items)

    var c = 0
    let d2 = d.filter { item in
      c += 1
      expectEqual(item.value, 100 * item.key)
      return item.key.isMultiple(of: 2)
    }
    expectEqual(c, 100)
    expectEqualElements(d, items)

    expectEqualElements(d2, (0 ..< 50).compactMap { key in
      return (key: 2 * key, value: 200 * key)
    })
  }

  func test_mapValues() {
    let items = (0 ..< 100).map { ($0, 100 * $0) }
    let d = OrderedDictionary(uniqueKeysWithValues: items)

    var c = 0
    let d2 = d.mapValues { value -> String in
      c += 1
      expectTrue(value.isMultiple(of: 100))
      return "\(value)"
    }
    expectEqual(c, 100)
    expectEqualElements(d, items)

    expectEqualElements(d2, (0 ..< 100).compactMap { key in
      (key: key, value: "\(100 * key)")
    })
  }

  func test_compactMapValue() {
    let items = (0 ..< 100).map { ($0, 100 * $0) }
    let d = OrderedDictionary(uniqueKeysWithValues: items)

    var c = 0
    let d2 = d.compactMapValues { value -> String? in
      c += 1
      guard value.isMultiple(of: 200) else { return nil }
      expectTrue(value.isMultiple(of: 100))
      return "\(value)"
    }
    expectEqual(c, 100)
    expectEqualElements(d, items)

    expectEqualElements(d2, (0 ..< 50).map { key in
      (key: 2 * key, value: "\(200 * key)")
    })
  }

  func test_CustomStringConvertible() {
    let a: OrderedDictionary<Int, Int> = [:]
    expectEqual(a.description, "[:]")

    let b: OrderedDictionary<Int, Int> = [0: 1]
    expectEqual(b.description, "[0: 1]")

    let c: OrderedDictionary<Int, Int> = [0: 1, 2: 3, 4: 5]
    expectEqual(c.description, "[0: 1, 2: 3, 4: 5]")
  }

  func test_CustomDebugStringConvertible() {
    let a: OrderedDictionary<Int, Int> = [:]
    expectEqual(a.debugDescription,
                "OrderedDictionary<Int, Int>([:])")

    let b: OrderedDictionary<Int, Int> = [0: 1]
    expectEqual(b.debugDescription,
                "OrderedDictionary<Int, Int>([0: 1])")

    let c: OrderedDictionary<Int, Int> = [0: 1, 2: 3, 4: 5]
    expectEqual(c.debugDescription,
                "OrderedDictionary<Int, Int>([0: 1, 2: 3, 4: 5])")
  }

  func test_customReflectable() {
    do {
      let d: OrderedDictionary<Int, Int> = [1: 2, 3: 4, 5: 6]
      let mirror = Mirror(reflecting: d)
      expectEqual(mirror.displayStyle, .dictionary)
      expectNil(mirror.superclassMirror)
      expectTrue(mirror.children.compactMap { $0.label }.isEmpty) // No label
      expectEqualElements(
        mirror.children.compactMap { $0.value as? (key: Int, value: Int) },
        d.map { $0 })
    }
  }

  func test_Equatable_Hashable() {
    let samples: [[OrderedDictionary<Int, Int>]] = [
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
    let d1: OrderedDictionary<Int, Int> = [:]
    let v1: MinimalEncoder.Value = .array([])
    expectEqual(try MinimalEncoder.encode(d1), v1)

    let d2: OrderedDictionary<Int, Int> = [0: 1]
    let v2: MinimalEncoder.Value = .array([.int(0), .int(1)])
    expectEqual(try MinimalEncoder.encode(d2), v2)

    let d3: OrderedDictionary<Int, Int> = [0: 1, 2: 3]
    let v3: MinimalEncoder.Value =
      .array([.int(0), .int(1), .int(2), .int(3)])
    expectEqual(try MinimalEncoder.encode(d3), v3)

    let d4 = OrderedDictionary(
      uniqueKeys: 0 ..< 100,
      values: (0 ..< 100).map { 100 * $0 })
    let v4: MinimalEncoder.Value =
      .array((0 ..< 100).flatMap { [.int($0), .int(100 * $0)] })
    expectEqual(try MinimalEncoder.encode(d4), v4)
  }

  func test_Decodable() throws {
    typealias OD = OrderedDictionary<Int, Int>
    let d1: OD = [:]
    let v1: MinimalEncoder.Value = .array([])
    expectEqual(try MinimalDecoder.decode(v1, as: OD.self), d1)

    let d2: OD = [0: 1]
    let v2: MinimalEncoder.Value = .array([.int(0), .int(1)])
    expectEqual(try MinimalDecoder.decode(v2, as: OD.self), d2)

    let d3: OD = [0: 1, 2: 3]
    let v3: MinimalEncoder.Value =
      .array([.int(0), .int(1), .int(2), .int(3)])
    expectEqual(try MinimalDecoder.decode(v3, as: OD.self), d3)

    let d4 = OrderedDictionary(
      uniqueKeys: 0 ..< 100,
      values: (0 ..< 100).map { 100 * $0 })
    let v4: MinimalEncoder.Value =
      .array((0 ..< 100).flatMap { [.int($0), .int(100 * $0)] })
    expectEqual(try MinimalDecoder.decode(v4, as: OD.self), d4)

    let v5: MinimalEncoder.Value = .array([.int(0), .int(1), .int(2)])
    expectThrows(try MinimalDecoder.decode(v5, as: OD.self)) { error in
      guard case DecodingError.dataCorrupted(let context) = error else {
        expectFailure("Unexpected error \(error)")
        return
      }
      expectEqual(context.debugDescription,
                  "Unkeyed container reached end before value in key-value pair")

    }

    let v6: MinimalEncoder.Value = .array([.int(0), .int(1), .int(0), .int(2)])
    expectThrows(try MinimalDecoder.decode(v6, as: OD.self)) { error in
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
              var (d, keys, values) = tracker.orderedDictionary(keys: 0 ..< count)
              keys.swapAt(i, j)
              values.swapAt(i, j)
              withHiddenCopies(if: isShared, of: &d) { d in
                d.swapAt(i, j)
                expectEqualElements(d.values, values)
                expectEqual(d[keys[i]], values[i])
                expectEqual(d[keys[j]], values[j])
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
            var (d, keys, values) = tracker.orderedDictionary(
              keys: (0 ..< count).shuffled(using: &rng))
            var items = Array(zip(keys, values))
            let expectedPivot = items.partition { $0.0.payload < count / 2 }
            withHiddenCopies(if: isShared, of: &d) { d in
              let actualPivot = d.partition { $0.key.payload < count / 2 }
              expectEqual(actualPivot, expectedPivot)
              expectEqualElements(d, items)
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
            var (d, keys, values) = tracker.orderedDictionary(
              keys: (0 ..< count).shuffled(using: &rng))
            var items = Array(zip(keys, values))
            items.sort(by: { $0.0 < $1.0 })
            withHiddenCopies(if: isShared, of: &d) { d in
              d.sort()
              expectEqualElements(d, items)
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
            var (d, keys, values) = tracker.orderedDictionary(
              keys: (0 ..< count).shuffled(using: &rng))
            var items = Array(zip(keys, values))
            items.sort(by: { $0.0 > $1.0 })
            withHiddenCopies(if: isShared, of: &d) { d in
              d.sort(by: { $0.key > $1.key })
              expectEqualElements(d, items)
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
          var d = OrderedDictionary(
            uniqueKeys: 0 ..< count,
            values: 100 ..< 100 + count)
          var items = (0 ..< count).map { (key: $0, value: 100 + $0) }
          withHiddenCopies(if: isShared, of: &d) { d in
            expectEqualElements(d, items)

            var rng1 = RepeatableRandomNumberGenerator(seed: seed)
            items.shuffle(using: &rng1)

            var rng2 = RepeatableRandomNumberGenerator(seed: seed)
            d.shuffle(using: &rng2)

            items.sort(by: { $0.key < $1.key })
            d.sort()
            expectEqualElements(d, items)
          }
        }
      }
      if count >= 2 {
        // Check that shuffling with the system RNG does permute the elements.
        var d = OrderedDictionary(
          uniqueKeys: 0 ..< count,
          values: 100 ..< 100 + count)
        let original = d
        var success = false
        for _ in 0 ..< 1000 {
          d.shuffle()
          if !d.elementsEqual(
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
          var (d, keys, values) = tracker.orderedDictionary(keys: 0 ..< count)
          var items = Array(zip(keys, values))
          withHiddenCopies(if: isShared, of: &d) { d in
            items.reverse()
            d.reverse()
            expectEqualElements(d, items)
          }
        }
      }
    }
  }

  func test_removeAll() {
    withEvery("count", in: 0 ..< 30) { count in
      withEvery("isShared", in: [false, true]) { isShared in
        withLifetimeTracking { tracker in
          var (d, _, _) = tracker.orderedDictionary(keys: 0 ..< count)
          withHiddenCopies(if: isShared, of: &d) { d in
            d.removeAll()
            expectEqual(d.keys.__unstable.scale, 0)
            expectEqualElements(d, [])
          }
        }
      }
    }
  }

  func test_removeAll_keepCapacity() {
    withEvery("count", in: 0 ..< 30) { count in
      withEvery("isShared", in: [false, true]) { isShared in
        withLifetimeTracking { tracker in
          var (d, _, _) = tracker.orderedDictionary(keys: 0 ..< count)
          let origScale = d.keys.__unstable.scale
          withHiddenCopies(if: isShared, of: &d) { d in
            d.removeAll(keepingCapacity: true)
            expectEqual(d.keys.__unstable.scale, origScale)
            expectEqualElements(d, [])
          }
        }
      }
    }
  }

  func test_remove_at() {
    withEvery("count", in: 0 ..< 30) { count in
      withEvery("offset", in: 0 ..< count) { offset in
        withEvery("isShared", in: [false, true]) { isShared in
          withLifetimeTracking { tracker in
            var (d, keys, values) = tracker.orderedDictionary(keys: 0 ..< count)
            withHiddenCopies(if: isShared, of: &d) { d in
              let actual = d.remove(at: offset)
              let expectedKey = keys.remove(at: offset)
              let expectedValue = values.remove(at: offset)
              expectEqual(actual.key, expectedKey)
              expectEqual(actual.value, expectedValue)
              expectEqualElements(
                d,
                zip(keys, values).map { (key: $0.0, value: $0.1) })
            }
          }
        }
      }
    }
  }

  func test_removeSubrange() {
    withEvery("count", in: 0 ..< 30) { count in
      withEveryRange("range", in: 0 ..< count) { range in
        withEvery("isShared", in: [false, true]) { isShared in
          withLifetimeTracking { tracker in
            var (d, keys, values) = tracker.orderedDictionary(keys: 0 ..< count)
            withHiddenCopies(if: isShared, of: &d) { d in
              d.removeSubrange(range)
              keys.removeSubrange(range)
              values.removeSubrange(range)
              expectEqualElements(
                d,
                zip(keys, values).map { (key: $0.0, value: $0.1) })
            }
          }
        }
      }
    }
  }

  func test_removeSubrange_rangeExpression() {
    let d = OrderedDictionary(uniqueKeys: 0 ..< 30, values: 100 ..< 130)
    let item = (0 ..< 30).map { (key: $0, value: 100 + $0) }

    var d1 = d
    d1.removeSubrange(...10)
    expectEqualElements(d1, item[11...])

    var d2 = d
    d2.removeSubrange(..<10)
    expectEqualElements(d2, item[10...])

    var d3 = d
    d3.removeSubrange(10...)
    expectEqualElements(d3, item[0 ..< 10])
  }

  func test_removeLast() {
    withEvery("isShared", in: [false, true]) { isShared in
      withLifetimeTracking { tracker in
        var (d, keys, values) = tracker.orderedDictionary(keys: 0 ..< 30)
        withEvery("i", in: 0 ..< d.count) { i in
          withHiddenCopies(if: isShared, of: &d) { d in
            let actual = d.removeLast()
            let expectedKey = keys.removeLast()
            let expectedValue = values.removeLast()
            expectEqual(actual.key, expectedKey)
            expectEqual(actual.value, expectedValue)
            expectEqualElements(
              d,
              zip(keys, values).map { (key: $0.0, value: $0.1) })
          }
        }
      }
    }
  }

  func test_removeFirst() {
    withEvery("isShared", in: [false, true]) { isShared in
      withLifetimeTracking { tracker in
        var (d, keys, values) = tracker.orderedDictionary(keys: 0 ..< 30)
        withEvery("i", in: 0 ..< d.count) { i in
          withHiddenCopies(if: isShared, of: &d) { d in
            let actual = d.removeFirst()
            let expectedKey = keys.removeFirst()
            let expectedValue = values.removeFirst()
            expectEqual(actual.key, expectedKey)
            expectEqual(actual.value, expectedValue)
            expectEqualElements(
              d,
              zip(keys, values).map { (key: $0.0, value: $0.1) })
          }
        }
      }
    }
  }

  func test_removeLast_n() {
    withEvery("count", in: 0 ..< 30) { count in
      withEvery("suffix", in: 0 ..< count) { suffix in
        withEvery("isShared", in: [false, true]) { isShared in
          withLifetimeTracking { tracker in
            var (d, keys, values) = tracker.orderedDictionary(keys: 0 ..< count)
            withHiddenCopies(if: isShared, of: &d) { d in
              d.removeLast(suffix)
              keys.removeLast(suffix)
              values.removeLast(suffix)
              expectEqualElements(
                d,
                zip(keys, values).map { (key: $0.0, value: $0.1) })
            }
          }
        }
      }
    }
  }

  func test_removeFirst_n() {
    withEvery("count", in: 0 ..< 30) { count in
      withEvery("prefix", in: 0 ..< count) { prefix in
        withEvery("isShared", in: [false, true]) { isShared in
          withLifetimeTracking { tracker in
            var (d, keys, values) = tracker.orderedDictionary(keys: 0 ..< count)
            withHiddenCopies(if: isShared, of: &d) { d in
              d.removeFirst(prefix)
              keys.removeFirst(prefix)
              values.removeFirst(prefix)
              expectEqualElements(
                d,
                zip(keys, values).map { (key: $0.0, value: $0.1) })
            }
          }
        }
      }
    }
  }

  func test_removeAll_where() {
    withEvery("count", in: 0 ..< 30) { count in
      withEvery("n", in: [2, 3, 4]) { n in
        withEvery("isShared", in: [false, true]) { isShared in
          withLifetimeTracking { tracker in
            var (d, keys, values) = tracker.orderedDictionary(keys: 0 ..< count)
            var items = zip(keys, values).map { (key: $0.0, value: $0.1) }
            withHiddenCopies(if: isShared, of: &d) { d in
              d.removeAll(where: { !$0.key.payload.isMultiple(of: n) })
              items.removeAll(where: { !$0.key.payload.isMultiple(of: n) })
              expectEqualElements(d, items)
            }
          }
        }
      }
    }
  }

  func test_Sequence() {
    withEvery("count", in: 0 ..< 30) { count in
      withLifetimeTracking { tracker in
        let (d, keys, values) = tracker.orderedDictionary(keys: 0 ..< count)
        let items = zip(keys, values).map { (key: $0.0, value: $0.1) }
        checkSequence(
          { d },
          expectedContents: items,
          by: { $0.key == $1.0 && $0.value == $1.1 })
      }
    }
  }

}

