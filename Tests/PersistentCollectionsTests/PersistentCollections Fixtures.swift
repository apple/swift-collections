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

import _CollectionsTestSupport
import PersistentCollections

/// A list of example trees to use while testing persistent hash maps.
///
/// Each example has a name and a list of path specifications or collisions.
///
/// A path spec is an ASCII `String` representing the hash of a key/value pair,
/// a.k.a a path in the prefix tree. Each character in the string identifies
/// a bucket index of a tree node, starting from the root.
/// (Encoded in radix 32, with digits 0-9 followed by letters. In order to
/// prepare for a potential reduction in the maximum node size, it is best to
/// keep the digits in the range 0-F.) The prefix tree's depth is limited by the
/// size of hash values.
///
/// For example, the string "5A" corresponds to a key/value pair
/// that is in bucket 10 of a second-level node that is found at bucket 5
/// of the root node.
///
/// Hash collisions are modeled by strings of the form `<path>*<count>` where
/// `<path>` is a path specification, and `<count>` is the number of times that
/// path needs to be repeated. (To implement the collisions, the path is
/// extended with an infinite number of zeroes.)
///
/// To generate input data from these fixtures, the items are sorted into
/// the same order as we expect a preorder walk would visit them in the
/// resulting tree. The resulting ordering is then used to insert key/value
/// pairs into the map, with sequentially increasing keys.
let _fixtures: KeyValuePairs<String, [String]> = [
  "empty": [],
  "single-item": [
    "A"
  ],
  "single-node": [
    "0",
    "1",
    "2",
    "3",
    "4",
    "A",
    "B",
    "C",
    "D",
  ],
  "few-collisions": [
    "42*5"
  ],
  "many-collisions": [
    "42*40"
  ],
  "few-different-collisions": [
    "1*3",
    "21*3",
    "22*3",
    "3*3",
  ],
  "everything-on-the-2nd-level": [
    "00", "01", "02", "03", "04",
    "10", "11", "12", "13", "14",
    "20", "21", "22", "23", "24",
    "30", "31", "32", "33", "34",
  ],
  "two-levels-mixed": [
    "00", "01",
    "2",
    "30", "33",
    "4",
    "5",
    "60", "61", "66",
    "71", "75", "77",
    "8",
    "94", "98", "9A",
    "A3", "A4",
  ],
  "vee": [
    "11110",
    "11115",
    "11119",
    "1111B",
    "66664",
    "66667",
  ],
  "fork": [
    "31110",
    "31115",
    "31119",
    "3111B",
    "36664",
    "36667",
  ],
  "chain": [
    "0",
    "10",
    "110",
    "1110",
    "11110",
    "11111",
  ],
  "nested": [
    "50",
    "51",
    "520",
    "521",
    "5220",
    "5221",
    "52220",
    "52221",
    "522220",
    "522221",
    "5222220",
    "5222221",
    "52222220",
    "52222221",
    "522222220",
    "522222221",
    "5222222220",
    "5222222221",
    "5222222222",
    "5222222223",
    "522222223",
    "522222224",
    "52222223",
    "52222224",
    "5222223",
    "5222224",
    "522223",
    "522224",
    "52223",
    "52224",
    "5223",
    "5224",
    "53",
    "54",
  ],
  "deep": [
    "0",

    // Deeply nested children with only the leaf containing items
    "1234560",
    "1234561",
    "1234562",
    "1234563",

    "22",
    "25",
  ],
]

struct Fixture<Key: Hashable, Value> {
  typealias Element = (key: Key, value: Value)

  let title: String
  let items: [Element]

  init(title: String, items: [Element]) {
    self.title = title
    self.items = items
  }
}

func withEachFixture(
  body: (Fixture<RawCollider, Int>) -> Void
) {
  for (name, fixture) in _fixtures {
    let entry = TestContext.current.push("fixture: \(name)")
    defer { TestContext.current.pop(entry) }

    let maxDepth = 15 // Larger than the actual maximum tree depth
    var paths: [String] = []
    var seen: Set<String> = []
    for item in fixture {
      let path: String
      if let i = item.unicodeScalars.firstIndex(of: "*") {
        // We need to extend the path of collisions with zeroes to
        // make sure they sort correctly.
        let p = String(item.unicodeScalars.prefix(upTo: i))
        guard let count = Int(item.suffix(from: i).dropFirst(), radix: 10)
        else { fatalError("Invalid item: '\(item)'") }
        path = p.appending(String(repeating: "0", count: maxDepth - p.unicodeScalars.count))
        paths.append(contentsOf: repeatElement(path, count: count))
      } else {
        path = item
        paths.append(path)
      }

      let normalized = path
        .uppercased()
        .appending(String(repeating: "0", count: maxDepth - path.unicodeScalars.count))
      if !seen.insert(normalized).inserted {
        fatalError("Unexpected duplicate path: '\(path)'")
      }
    }

    // Sort paths into the order that we expect items will appear in the
    // dictionary.
    paths.sort { a, b in
      var a = a.unicodeScalars[...]
      var b = b.unicodeScalars[...]
      // Ignore common prefix
      while !a.isEmpty && !b.isEmpty && a.first == b.first {
        a = a.dropFirst()
        b = b.dropFirst()
      }
      switch (a.isEmpty, b.isEmpty) {
      case (true, true): return false // a == b
      case (true, false): return true // a < b, like 44 < 443
      case (false, true): return false // a > b like 443 > 44
      case (false, false): break
      }
      if a.count == 1 && b.count > 1 {
        return true // a < b, like 45 < 423
      }
      if b.count == 1 && a.count > 1 {
        return false // a > b, like 423 > 45
      }
      return a.first! < b.first!
    }

    var items: [(key: RawCollider, value: Int)] = []
    items.reserveCapacity(paths.count)
    var id = 0
    for path in paths {
      let hash = Hash(path)!
      let key = RawCollider(id, hash)
      let value = 100 + id
      items.append((key, value))
      id += 1
    }

    print(name)
    body(Fixture(title: name, items: items))
  }
}


extension LifetimeTracker {
  func persistentDictionary(
    for fixture: [(key: RawCollider, value: Int)]
  ) -> (
    map: PersistentDictionary<LifetimeTracked<RawCollider>, LifetimeTracked<Int>>,
    ref: [(key: LifetimeTracked<RawCollider>, value: LifetimeTracked<Int>)]
  ) {
    let ref = fixture.map { (key, value) in
      (key: self.instance(for: key), value: self.instance(for: value))
    }
    return (PersistentDictionary(uniqueKeysWithValues: ref), ref)
  }
}
