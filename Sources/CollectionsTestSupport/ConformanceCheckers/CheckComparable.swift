//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2021 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
// See https://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//
//===----------------------------------------------------------------------===//

// Loosely adapted from https://github.com/apple/swift/tree/main/stdlib/private/StdlibUnittest

public enum ExpectedComparisonResult: Hashable {
  case lt, eq, gt

  public func flip() -> ExpectedComparisonResult {
    switch self {
    case .lt:
      return .gt
    case .eq:
      return .eq
    case .gt:
      return .lt
    }
  }

  public static func comparing<C: Comparable>(_ left: C, _ right: C) -> Self {
    left < right ? .lt
      : left > right ? .gt
      : .eq
  }
}

extension ExpectedComparisonResult: CustomStringConvertible {
  public var description: String {
    switch self {
    case .lt:
      return "<"
    case .eq:
      return "=="
    case .gt:
      return ">"
    }
  }
}

public func checkComparable<Instance: Comparable>(
  sortedEquivalenceClasses: [[Instance]],
  file: StaticString = #file, line: UInt = #line
) {
  let instances = sortedEquivalenceClasses.flatMap { $0 }
  // oracle[i] is the index of the equivalence class that contains instances[i].
  let oracle = sortedEquivalenceClasses.indices.flatMap { i in repeatElement(i, count: sortedEquivalenceClasses[i].count) }
  checkComparable(
    instances,
    oracle: {
      if oracle[$0] < oracle[$1] { return .lt }
      if oracle[$0] > oracle[$1] { return .gt }
      return .eq
    },
    file: file, line: line)
}

/// Test that the elements of `instances` satisfy the semantic
/// requirements of `Comparable`, using `oracle` to generate comparison
/// expectations from pairs of positions in `instances`.
public func checkComparable<Instances: Collection>(
  _ instances: Instances,
  oracle: (Instances.Index, Instances.Index) -> ExpectedComparisonResult,
  file: StaticString = #file, line: UInt = #line
) where Instances.Element: Comparable {
  checkEquatable(instances,
                 oracle: { oracle($0, $1) == .eq },
                 file: file, line: line)
  _checkComparable(instances, oracle: oracle, file: file, line: line)
}

public func checkComparable<T : Comparable>(
  expected: ExpectedComparisonResult, _ lhs: T, _ rhs: T,
  file: StaticString = #file, line: UInt = #line
) {
  checkComparable(
    [lhs, rhs],
    oracle: { [[ .eq, expected], [ expected.flip(), .eq]][$0][$1] },
    file: file, line: line)
}

/// Same as `checkComparable(_:oracle:file:line:)` but doesn't check
/// `Equatable` conformance. Useful for preventing duplicate testing.
public func _checkComparable<Instances: Collection>(
  _ instances: Instances,
  oracle: (Instances.Index, Instances.Index) -> ExpectedComparisonResult,
  file: StaticString = #file, line: UInt = #line
) where Instances.Element: Comparable {
  let entry = TestContext.current.push("checkComparable", file: file, line: line)
  defer { TestContext.current.pop(entry) }
  for i in instances.indices {
    let x = instances[i]

    expectFalse(
      x < x,
      "found 'x < x' at index \(i): \(String(reflecting: x))")

    expectFalse(
      x > x,
      "found 'x > x' at index \(i): \(String(reflecting: x))")

    expectTrue(x <= x,
               "found 'x <= x' to be false at index \(i): \(String(reflecting: x))")

    expectTrue(x >= x,
               "found 'x >= x' to be false at index \(i): \(String(reflecting: x))")

    for j in instances.indices where i != j {
      let y = instances[j]

      let expected = oracle(i, j)

      expectEqual(
        expected.flip(), oracle(j, i),
        """
          bad oracle: missing antisymmetry:
          lhs (at index \(i)): \(String(reflecting: x))
          rhs (at index \(j)): \(String(reflecting: y))
          """)

      expectEqual(
        expected == .lt, x < y,
        """
          x < y doesn't match oracle
          lhs (at index \(i)): \(String(reflecting: x))
          rhs (at index \(j)): \(String(reflecting: y))
          """)

      expectEqual(
        expected != .gt, x <= y,
        """
          x <= y doesn't match oracle
          lhs (at index \(i)): \(String(reflecting: x))
          rhs (at index \(j)): \(String(reflecting: y))
          """)

      expectEqual(
        expected != .lt, x >= y,
        """
          x >= y doesn't match oracle
          lhs (at index \(i)): \(String(reflecting: x))
          rhs (at index \(j)): \(String(reflecting: y))
          """)

      expectEqual(
        expected == .gt, x > y,
        """
          x > y doesn't match oracle
          lhs (at index \(i)): \(String(reflecting: x))
          rhs (at index \(j)): \(String(reflecting: y))
          """)

      for k in instances.indices {
        let expected2 = oracle(j, k)
        if expected == expected2 {
          expectEqual(
            expected, oracle(i, k),
            """
              bad oracle: transitivity violation
              x (at index \(i)): \(String(reflecting: x))
              y (at index \(j)): \(String(reflecting: y))
              z (at index \(k)): \(String(reflecting: instances[k]))
              """)
        }
      }
    }
  }
}
