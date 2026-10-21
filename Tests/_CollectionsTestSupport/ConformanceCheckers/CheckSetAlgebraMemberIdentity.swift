//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Collections open source project
//
// Copyright (c) 2026 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
//
// SPDX-License-Identifier: Apache-2.0 WITH Swift-exception
//
//===----------------------------------------------------------------------===//

/// Test which members `insert(_:)`, `update(with:)` and `remove(_:)` keep and
/// return when the set already holds a member equal to, but distinguishable
/// from, the argument, using `Set`'s behavior as the reference:
///
/// - `insert(_:)` keeps the existing member and returns it.
/// - `update(with:)` stores the new member and returns the old one.
/// - `remove(_:)` returns the member it removed, not its argument.
///
/// Every key from one below a model's smallest member through one above its
/// largest is tried against a uniquely referenced and a shared value built
/// from that model. `members` must return the instances a value holds.
///
/// Which of two equal members `union(_:)`, `intersection(_:)` and `init(_:)`
/// keep is unspecified, so they are not checked.
package func checkSetAlgebraMemberIdentity<S: SetAlgebra>(
  _ type: S.Type,
  models: [Set<Int>],
  members: (S) -> [S.Element],
  file: StaticString = #filePath, line: UInt = #line
) where S.Element == LifetimeTracked<Int> {
  let entry = TestContext.current.push(
    "checkSetAlgebraMemberIdentity", file: file, line: line)
  defer { TestContext.current.pop(entry) }

  func expectMembers(_ value: S, _ expected: [S.Element], _ label: String) {
    let actual = members(value)
    expectEqual(actual.count, expected.count, "\(label): wrong count",
                file: file, line: line)
    let actualByKey = Dictionary(
      actual.map { ($0.payload, $0) }, uniquingKeysWith: { first, _ in first })
    for member in expected {
      expectIdentical(actualByKey[member.payload], member,
                      "\(label): wrong member for \(member)",
                      file: file, line: line)
      expectTrue(value.contains(member), "\(label): does not contain \(member)",
                 file: file, line: line)
    }
  }

  withEvery("model", in: models.indices) { index in
    let model = models[index]
    withLifetimeTracking(file: file, line: line) { tracker in
      let originals = tracker.instances(for: model.sorted())
      expectMembers(S(originals), originals, "init(_:)")

      let keys = (model.min() ?? 0) - 1 ... (model.max() ?? 0) + 1
      withEvery("key", in: keys) { key in
        let old = originals.first { $0.payload == key }
        let others = originals.filter { $0.payload != key }
        let new = tracker.instance(for: key)

        withEvery("isShared", in: [false, true]) { isShared in
          func checkMutation(
            _ label: String,
            _ expected: [S.Element],
            _ mutate: (inout S) -> Void
          ) {
            var value = S(originals)
            let copy = isShared ? value : nil
            mutate(&value)
            expectMembers(value, expected, label)
            if let copy {
              expectMembers(copy, originals, "\(label) changed a shared copy")
            }
          }

          checkMutation("insert(_:)", others + [old ?? new]) { value in
            let result = value.insert(new)
            expectEqual(result.inserted, old == nil,
                        "insert(_:): wrong inserted", file: file, line: line)
            expectIdentical(result.memberAfterInsert, old ?? new,
                            "insert(_:): wrong memberAfterInsert",
                            file: file, line: line)
          }
          checkMutation("update(with:)", others + [new]) { value in
            expectIdentical(value.update(with: new), old,
                            "update(with:): wrong return value",
                            file: file, line: line)
          }
          checkMutation("remove(_:)", others) { value in
            expectIdentical(value.remove(new), old,
                            "remove(_:): wrong return value",
                            file: file, line: line)
            expectFalse(value.contains(new),
                        "remove(_:): still contains \(key)",
                        file: file, line: line)
          }
        }
      }
    }
  }
}
