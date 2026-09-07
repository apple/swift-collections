//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Collections open source project
//
// Copyright (c) 2022 - 2026 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
//
// SPDX-License-Identifier: Apache-2.0 WITH Swift-exception
//
//===----------------------------------------------------------------------===//

// `SetAPIChecker` verifies that a set-like type has the right *shape* -- it is
// a protocol with no assertions, so conforming to it makes the compiler check
// that the API surface exists. This file checks the other half: that the
// operations behave the way the documentation says they do.
//
// The checker is constrained on `SetAPIChecker` rather than on `SetAlgebra`
// because `OrderedSet` deliberately does not conform to `SetAlgebra` -- only
// its `UnorderedView` does. Constraining on the stdlib protocol would exclude
// the type that needs this most.

/// Test that `instances` satisfy the semantic requirements of the set
/// operations declared in `SetAPIChecker`, using `models` as the
/// specification.
///
/// `models[i]` must contain exactly the elements of `instances[i]`. Every law
/// is checked against the model first, and the model itself is checked for
/// consistency before any of the instances are judged -- see
/// `_checkSetAlgebraModels(_:)`.
package func checkSetAlgebra<S: SetAPIChecker & Sequence>(
  _ instances: [S],
  models: [Set<S.Element>],
  file: StaticString = #filePath, line: UInt = #line
) where S.Element: Hashable {
  let entry = TestContext.current.push("checkSetAlgebra", file: file, line: line)
  defer { TestContext.current.pop(entry) }

  precondition(instances.count == models.count,
               "checkSetAlgebra: instance and model counts disagree")

  guard _checkSetAlgebraModels(models, file: file, line: line) else {
    // The specification is inconsistent. Judging the type against it would
    // report defects in the wrong artefact, so stop here.
    return
  }

  for i in instances.indices {
    _checkSetAlgebraUnaryLaws(instances[i], models[i], i, file: file, line: line)
  }

  for i in instances.indices {
    for j in instances.indices {
      _checkSetAlgebraBinaryLaws(
        instances[i], models[i], i,
        instances[j], models[j], j,
        file: file, line: line)
    }
  }
}

// MARK: - Validating the specification

/// Check that the supplied models are a usable specification, *before* any
/// instance is judged against them.
///
/// A `Set<Element>` model is only as sound as `Element`'s `Hashable`
/// conformance. If that conformance is broken the model is silently wrong, and
/// a broken model and a broken implementation can agree with each other --
/// producing a suite that passes while both artefacts are wrong. That failure
/// is quiet in exactly the way a wrong implementation is not, so it is worth
/// ruling out separately.
///
/// Returns `false` if the models cannot be trusted, in which case the caller
/// should not go on to test the type.
package func _checkSetAlgebraModels<Element: Hashable>(
  _ models: [Set<Element>],
  file: StaticString = #filePath, line: UInt = #line
) -> Bool {
  let entry = TestContext.current.push("checkSetAlgebraModels", file: file, line: line)
  defer { TestContext.current.pop(entry) }

  var ok = true

  // The model's carrier must have a sound `Hashable` conformance, or every
  // law below is being checked against a set that does not behave like one.
  let allElements = Array(models.joined())
  if !allElements.isEmpty {
    _checkHashable(
      allElements,
      equalityOracle: { allElements[$0] == allElements[$1] },
      file: file, line: line)
  }

  for i in models.indices {
    let model = models[i]
    // Round-tripping through Array and back must preserve the model exactly.
    // A `Hashable` conformance that disagrees with `==` shows up here.
    let roundTripped = Set(Array(model))
    if roundTripped != model || roundTripped.count != model.count {
      ok = false
      expectEqual(
        roundTripped.count, model.count,
        """
        bad model: model \(i) does not survive a round trip through Array
        This usually means Element's Hashable conformance disagrees with ==.
        """,
        file: file, line: line)
    }
  }

  return ok
}

// MARK: - Laws over a single instance

private func _checkSetAlgebraUnaryLaws<S: SetAPIChecker & Sequence>(
  _ x: S, _ model: Set<S.Element>, _ i: Int,
  file: StaticString, line: UInt
) where S.Element: Hashable {
  let entry = TestContext.current.push("instance \(i)", file: file, line: line)
  defer { TestContext.current.pop(entry) }

  // The instance must actually hold what the model says it holds. Everything
  // below is meaningless if this fails.
  expectEqual(Set(x), model, "instance \(i) does not contain its model's elements",
              file: file, line: line)
  expectEqual(x.count, model.count, "count disagrees with the model",
              file: file, line: line)
  expectEqual(x.isEmpty, model.isEmpty, "isEmpty disagrees with the model",
              file: file, line: line)

  // `count` and `isEmpty` must agree with each other, separately from the
  // model. A type that caches a count can get exactly one of them wrong.
  expectEqual(x.isEmpty, x.count == 0, "isEmpty disagrees with count == 0",
              file: file, line: line)

  let empty = S()
  expectTrue(empty.isEmpty, "S() is not empty", file: file, line: line)
  expectEqual(empty.count, 0, "S() has a nonzero count", file: file, line: line)

  // Reflexive cases of the containment predicates.
  expectTrue(x.isSubset(of: x), "x is not a subset of itself", file: file, line: line)
  expectTrue(x.isSuperset(of: x), "x is not a superset of itself", file: file, line: line)
  expectFalse(x.isStrictSubset(of: x), "x is a strict subset of itself",
              file: file, line: line)
  expectFalse(x.isStrictSuperset(of: x), "x is a strict superset of itself",
              file: file, line: line)
  expectEqual(x.isDisjoint(with: x), x.isEmpty,
              "x is disjoint with itself but is not empty", file: file, line: line)

  // Every set is a superset of the empty set, and only the empty set is a
  // subset of it.
  expectTrue(x.isSuperset(of: empty), "x is not a superset of the empty set",
             file: file, line: line)
  expectEqual(x.isSubset(of: empty), x.isEmpty,
              "x is a subset of the empty set but is not empty",
              file: file, line: line)
  expectTrue(x.isDisjoint(with: empty), "x is not disjoint with the empty set",
             file: file, line: line)

  // `filter` must agree with the model, at both extremes and in between.
  expectEqual(Set(x.filter { _ in true }), model, "filter { true } lost elements",
              file: file, line: line)
  expectTrue(x.filter { _ in false }.isEmpty, "filter { false } kept elements",
             file: file, line: line)
  let half = x.filter { model.contains($0) && $0.hashValue % 2 == 0 }
  expectEqual(Set(half), model.filter { $0.hashValue % 2 == 0 },
              "filter disagrees with the model", file: file, line: line)
}

// MARK: - Laws over a pair of instances

private func _checkSetAlgebraBinaryLaws<S: SetAPIChecker & Sequence>(
  _ x: S, _ xm: Set<S.Element>, _ i: Int,
  _ y: S, _ ym: Set<S.Element>, _ j: Int,
  file: StaticString, line: UInt
) where S.Element: Hashable {
  let entry = TestContext.current.push("instances \(i), \(j)", file: file, line: line)
  defer { TestContext.current.pop(entry) }

  func expectContents(
    _ actual: S, _ expected: Set<S.Element>, _ label: String
  ) {
    expectEqual(Set(actual), expected, "\(label): wrong elements",
                file: file, line: line)
    // Checked separately from the contents: a type that maintains a stored
    // count can return the right elements alongside a stale count.
    expectEqual(actual.count, expected.count, "\(label): wrong count",
                file: file, line: line)
  }

  // The four operations, against the model.
  expectContents(x.union(y), xm.union(ym), "union")
  expectContents(x.intersection(y), xm.intersection(ym), "intersection")
  expectContents(x.subtracting(y), xm.subtracting(ym), "subtracting")
  expectContents(x.symmetricDifference(y), xm.symmetricDifference(ym),
                 "symmetricDifference")

  // The same operations against a plain Sequence rather than another `Self`.
  // These are separate overloads and can diverge from the `Self` ones.
  expectContents(x.union(Array(ym)), xm.union(ym), "union(Sequence)")
  expectContents(x.intersection(Array(ym)), xm.intersection(ym),
                 "intersection(Sequence)")
  expectContents(x.subtracting(Array(ym)), xm.subtracting(ym),
                 "subtracting(Sequence)")
  expectContents(x.symmetricDifference(Array(ym)), xm.symmetricDifference(ym),
                 "symmetricDifference(Sequence)")

  // A duplicated sequence must not change the result.
  expectContents(x.union(Array(ym) + Array(ym)), xm.union(ym),
                 "union(Sequence with duplicates)")

  // Algebraic laws that hold regardless of the model.
  expectContents(x.union(y), Set(y.union(x)), "union is commutative")
  expectContents(x.intersection(y), Set(y.intersection(x)),
                 "intersection is commutative")
  expectContents(x.symmetricDifference(y), Set(y.symmetricDifference(x)),
                 "symmetricDifference is commutative")

  // Absorption. These catch operations that are individually plausible but
  // inconsistent with each other.
  expectContents(x.union(x.intersection(y)), xm, "union absorbs intersection")
  expectContents(x.intersection(x.union(y)), xm, "intersection absorbs union")

  // symmetricDifference is definable from the other three; a type that
  // implements it separately can drift from them.
  expectContents(
    x.symmetricDifference(y),
    xm.union(ym).subtracting(xm.intersection(ym)),
    "symmetricDifference == union minus intersection")

  // Subtraction leaves nothing behind that `y` contained.
  expectTrue(x.subtracting(y).isDisjoint(with: y),
             "x.subtracting(y) is not disjoint with y", file: file, line: line)

  // The predicates, against the model.
  expectEqual(x.isSubset(of: y), xm.isSubset(of: ym), "isSubset",
              file: file, line: line)
  expectEqual(x.isSuperset(of: y), xm.isSuperset(of: ym), "isSuperset",
              file: file, line: line)
  expectEqual(x.isStrictSubset(of: y), xm.isStrictSubset(of: ym),
              "isStrictSubset", file: file, line: line)
  expectEqual(x.isStrictSuperset(of: y), xm.isStrictSuperset(of: ym),
              "isStrictSuperset", file: file, line: line)
  expectEqual(x.isDisjoint(with: y), xm.isDisjoint(with: ym), "isDisjoint",
              file: file, line: line)

  // And against each other. A type can implement each predicate plausibly and
  // still have them disagree.
  expectEqual(x.isSubset(of: y), y.isSuperset(of: x),
              "isSubset and isSuperset disagree", file: file, line: line)
  expectEqual(x.isStrictSubset(of: y), y.isStrictSuperset(of: x),
              "isStrictSubset and isStrictSuperset disagree",
              file: file, line: line)
  expectEqual(x.isStrictSubset(of: y),
              x.isSubset(of: y) && !y.isSubset(of: x),
              "isStrictSubset is not isSubset minus equality",
              file: file, line: line)
  expectEqual(x.isDisjoint(with: y), x.intersection(y).isEmpty,
              "isDisjoint disagrees with an empty intersection",
              file: file, line: line)
  expectEqual(x.isSubset(of: y), x.subtracting(y).isEmpty,
              "isSubset disagrees with an empty difference",
              file: file, line: line)

  // The mutating twins must agree with the non-mutating originals -- including
  // when the value is shared, which is where copy-on-write bugs live.
  withEvery("isShared", in: [false, true]) { isShared in
    func checkMutation(
      _ label: String,
      _ mutate: (inout S) -> Void,
      _ expected: Set<S.Element>
    ) {
      var copy = x
      withHiddenCopies(if: isShared, of: &copy) { copy in
        mutate(&copy)
        expectEqual(Set(copy), expected, "\(label): wrong elements",
                    file: file, line: line)
        expectEqual(copy.count, expected.count, "\(label): wrong count",
                    file: file, line: line)
      }
      // The original must be untouched.
      expectEqual(Set(x), xm, "\(label): mutated the original",
                  file: file, line: line)
    }

    checkMutation("formUnion", { $0.formUnion(y) }, xm.union(ym))
    checkMutation("formIntersection", { $0.formIntersection(y) },
                  xm.intersection(ym))
    checkMutation("subtract", { $0.subtract(y) }, xm.subtracting(ym))
    checkMutation("formSymmetricDifference",
                  { $0.formSymmetricDifference(y) },
                  xm.symmetricDifference(ym))

    // The Sequence-taking overloads of the same four.
    checkMutation("formUnion(Sequence)", { $0.formUnion(Array(ym)) },
                  xm.union(ym))
    checkMutation("formIntersection(Sequence)",
                  { $0.formIntersection(Array(ym)) }, xm.intersection(ym))
    checkMutation("subtract(Sequence)", { $0.subtract(Array(ym)) },
                  xm.subtracting(ym))
    checkMutation("formSymmetricDifference(Sequence)",
                  { $0.formSymmetricDifference(Array(ym)) },
                  xm.symmetricDifference(ym))
  }
}
