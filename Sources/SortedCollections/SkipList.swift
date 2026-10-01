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

/**
 SkipList
 =======

 This file implements a deterministic Skip List data structure,
 allowing efficient ordered insertion, deletion, and search operations with
 logarithmic time complexity on average.

 The implementation is adapted from "Skip Lists and Probabilistic Analysis of
 Algorithms" by Thomas Papadakis (1993) and designed for generic use with
 orderable elements.
 */

/// A sorted collection supporting fast insertion, deletion, and
/// search operations.
///
/// - Parameter TotalOrdering: Protocol defining the element type and a
///   total ordering for said element type.
struct SkipList<TotalOrdering: Orderable>: Sequence {
  /// Ensures that the underlying storage is uniquely referenced by this list.
  mutating func _ensureUnique() {
    if !isKnownUniquelyReferenced(&_core) {
      _core = Core(cloning: _core)
    }
  }

  /// The actual skip list structure with the stored values.
  var _core: Core

  /// The core implementation of the skip list,
  /// maintaining the structure and its operations.
  final class Core {
    /// Bottom-most sentinel node for skip list traversal.
    var bottom = Node(.maximum)
    /// Number of elements stored in the skip list.
    private(set) var count = 0

    /// Deletes an element from the skip list.
    ///
    /// - Parameter target: The element to delete.
    /// - Returns: The removed element if it existed, or `nil`.
    /// - Postcondition: The list has no elements equivalent to `target`.
    func delete(_ target: Element) -> Element? {
      let extendedTarget = ExtendedElement.normal(value: .init(target))
      let oldBottomValue = self.bottom.value
      self.bottom.value = extendedTarget
      defer { self.bottom.value = oldBottomValue }

      var outgoingValue: Element?
      var precedingValue: ExtendedElement!
      self.count -= 1
      do {
        var pointer = self.head.below
        var aboveValue = self.head.value
        var afterPointer: Node!
        while pointer !== self.bottom {
          let previousPointer: Node!
          let belowPointer: Node
          (previousPointer, pointer) = pointer.linkedNodes(bracketing: target)
          belowPointer = pointer.below
          defer {
            aboveValue = pointer.value
            pointer = belowPointer
          }

          if pointer.value == belowPointer.forward.value {
            if pointer.value != aboveValue {
              afterPointer = pointer.forward

              let belowAfterPointer = afterPointer.below
              let afterBelowAfterPointer = belowAfterPointer.forward
              if afterPointer.value == afterBelowAfterPointer.value
                || belowPointer === self.bottom
              {
                pointer._forward = afterPointer.forward
                pointer.value = afterPointer.value

                // Hope this is right
                outgoingValue = outgoingValue ?? afterPointer.finiteValue
              } else {
                pointer.value = belowAfterPointer.value
                afterPointer._below = afterBelowAfterPointer
              }
            } else {
              let belowPreviousPointer = previousPointer.below
              let oneAfterBelowPreviousPointer = belowPreviousPointer.forward
              if previousPointer.value <= oneAfterBelowPreviousPointer.value {
                if belowPointer === self.bottom {
                  precedingValue = previousPointer.value
                }
                previousPointer._forward = pointer.forward
                previousPointer.value = pointer.value

                // Hope this is right
                outgoingValue = outgoingValue ?? pointer.finiteValue
                pointer = previousPointer
              } else {
                let twoAfterBelowPreviousPointer = oneAfterBelowPreviousPointer
                  .forward
                afterPointer =
                  previousPointer.value == twoAfterBelowPreviousPointer.value
                  ? oneAfterBelowPreviousPointer : twoAfterBelowPreviousPointer
                previousPointer.value = afterPointer.value
                pointer._below = afterPointer.forward
              }
            }
          } else if belowPointer === self.bottom {
            // The target value wasn't in the list to begin with!
            self.count += 1  // undo the now-unnecessary deduction
          }
        }
      }

      do {
        var pointer = self.head.below
        while pointer !== self.bottom {
          defer { pointer = pointer.below }

          pointer = pointer.firstLinkedNode(atLeast: target)
          if extendedTarget == pointer.value {
            outgoingValue = outgoingValue ?? pointer.finiteValue
            pointer.value = precedingValue
          }
        }
      }

      if self.head.below.forward === tail {
        // Pop a now-excessive top head node.
        self.head = self.head.below
      }

      return outgoingValue
    }

    /// Removes all elements from the skip list, resetting its structure.
    ///
    /// - Postcondition: `count == 0`.
    func deleteAll() {
      self.bottom.value = .maximum
      self.head._forward = self.tail
      self.head._below = self.bottom
    }

    /// Represents an entry in the skip list,
    /// supporting normal, maximum, and super-maximum sentinels.
    enum ExtendedElement {
      /// Returns the finite element value if present, otherwise `nil`.
      var finiteValue: SkipList.Element? {
        switch self {
        case .normal(value: let result):
          result.sample
        case .maximum, .superMaximum:
          nil
        }
      }

      /// A conventional value.
      case normal(value: Value)
      /// A value greater than any conventional value.
      case maximum
      /// A value greater than all others.
      case superMaximum
    }

    /// Head node of the highest level in the skip list.
    var head: Node
    /// Creates an empty skip list.
    ///
    /// - Postcondition: `count == 0`.
    init() {
      self.head = Node(.maximum, forward: self.tail, below: self.bottom)
    }
    /// Creates a skip list copying the values of the given one.
    convenience init(cloning other: Core) {
      self.init()

      // Iterate to the bottom layer.
      var pointer = other.head
      while pointer !== other.bottom {
        pointer = pointer.below
      }

      // Iterate across the bottom layer.
      if pointer.value == .maximum {
        pointer = pointer.forward
      }
      while case .normal(let storedValue) = pointer.value {
        _ = self.insert(storedValue.sample)
        pointer = pointer.forward
      }
    }

    /// Inserts an element into the skip list.
    ///
    /// - Parameter newValue: The element to insert.
    /// - Returns: The previous element if it already existed, or `nil`.
    /// - Postcondition: The list has one element equivalent to `newValue`.
    func insert(_ newValue: Element) -> Element? {
      let extendedNewValue = ExtendedElement.normal(value: .init(newValue))
      let oldBottomValue = self.bottom.value
      self.bottom.value = extendedNewValue
      defer { self.bottom.value = oldBottomValue }

      var old: Element?
      self.count += 1
      do {
        var pointer = self.head
        while pointer !== self.bottom {
          defer { pointer = pointer.below }

          pointer = pointer.firstLinkedNode(atLeast: newValue)

          let belowPointer = pointer.below
          let oneAfterBelowPointer = belowPointer.forward
          let twoAfterBelowPointer = oneAfterBelowPointer.forward
          if pointer.value > twoAfterBelowPointer.value {
            // Add a node for `value`.
            // However, between that new node and its successor node in
            // this layer, their projections in the immediately lower layer
            // already have 3 nodes between them.
            // Avoid violations by promoting one of those 3 nodes to
            // this layer.
            var newValueNode = Node(
              pointer.value,
              forward: pointer.forward,
              below: twoAfterBelowPointer
            )
            pointer._forward = newValueNode
            pointer.value = oneAfterBelowPointer.value
          } else if pointer.below === self.bottom {
            // `pointer` must be at a node whose value already equals `value`.
            assert(pointer.value == extendedNewValue)
            guard case .normal(let normalValue) = extendedNewValue else {
              preconditionFailure("This should not be reachable")
            }

            old = normalValue.sample
            self.count -= 1  // undo the now-unnecessary earlier `count += 1`
          }
        }
      }
      if self.head.forward !== self.tail {
        let higherHead = Node(.maximum, forward: self.tail, below: self.head)
        self.head = higherHead
      }

      return old
    }

    /// Represents a node within a skip list level,
    /// linking forward and downward.
    final class Node {
      /// The node below this node at the next lower skip list level.
      var _below: Node?
      /// The node forward from this node at the same skip list level.
      var _forward: Node?
      /// The value associated with this node.
      var value: ExtendedElement

      /// Returns the node at the same column as this one in the
      /// layer immediately below this node's layer,
      /// wrapping around to `self` if not present.
      var below: Node {
        self._below ?? self
      }

      /// Returns the element value if not a maximum, otherwise `nil`.
      var finiteValue: Element? { value.finiteValue }

      /// Returns the first linked node whose value is at least the target.
      ///
      /// - Parameter target: The element whose lower bound is sought.
      /// - Returns: The first node with value >= target.
      func firstLinkedNode(atLeast target: Element) -> Node {
        return linkedNodes(bracketing: target).atOrAfter
      }

      /// Returns the node after this node in this layer,
      /// wrapping around to `self` if not present.
      var forward: Node {
        self._forward ?? self
      }

      /// Creates a new node with the given value,
      /// with pointers for the possible given neighbor nodes.
      ///
      /// - Parameters:
      ///   - value: The value stored in the node.
      ///   - forward: The node for the next higher value in this node's layer.
      ///   - below: This node's equivalent node in the next lower layer.
      init(_ value: ExtendedElement, forward: Node? = nil, below: Node? = nil) {
        self._below = below
        self._forward = forward
        self.value = value
      }

      /// Finds nodes bracketing the target value.
      ///
      /// - Parameter target: The value to bracket.
      /// - Returns: A pair of nodes,
      ///   where the second is the first node in this node's layer with
      ///   a value at least as much as `target`,
      ///   and the first is the node possible directly right before the second.
      func linkedNodes(bracketing target: Element) -> (
        before: Node?, atOrAfter: Node
      ) {
        let extendedTarget = ExtendedElement.normal(value: .init(target))
        var previous: Node?
        var present = self
        while extendedTarget > present.value {
          previous = present
          present = present.forward
        }
        return (previous, present)
      }
    }

    /// Finds the element in this list that is equivalent to the given value,
    /// optionally allowing the given value replace the currently stored one.
    ///
    /// - Parameters:
    ///   - target: The value to search for.
    ///   - doCanonize: Whether to replace the stored value with `target`.
    ///     If not given, no changes will occur.
    /// - Returns: The equivalent node stored in this skip list,
    ///   before any possible replacement.
    ///   If there was no matching node,
    ///   `nil` is returned instead.
    func representative(of target: Element, doCanonize: Bool = false)
      -> Element?
    {
      var result = self.head
      while result !== self.bottom {
        defer { result = result.below }

        result = result.firstLinkedNode(atLeast: target)
        guard result.below === self.bottom else { continue }
        guard case .normal(value: let innerValue) = result.value,
          TotalOrdering.areEquivalent(innerValue.sample, target)
        else {
          break
        }

        defer {
          if doCanonize {
            innerValue.sample = target
          }
        }
        return innerValue.sample
      }

      return nil
    }

    /// The tail-end sentinel node of this skip list structure.
    var tail = Node(.superMaximum)

    /// Wraps a sample element, allowing reference-based storage and mutation.
    final class Value {
      /// The sample element value.
      var sample: Element

      /// Creates a value wrapper around the given value.
      init(_ sample: Element) {
        self.sample = sample
      }
    }
  }

  /// The number of elements contained in the skip list.
  var count: Int { _core.count }

  /// Removes the specified element from the skip list.
  ///
  /// - Parameter target: The element to remove.
  /// - Returns: The removed element if it was present, or `nil` if not found.
  /// - Postcondition: This list will not have any elements equivalent to
  ///   `target`.
  mutating func delete(_ target: Element) -> Element? {
    self._ensureUnique()
    return self._core.delete(target)
  }
  /// Removes all elements from the skip list, leaving it empty.
  ///
  /// - Postcondition: `count == 0`.
  mutating func deleteAll() {
    self._ensureUnique()
    self._core.deleteAll()
  }

  /// The type of the stored values.
  typealias Element = TotalOrdering.Element

  /// Returns the canonical stored instance equivalent to the given element, if present.
  ///
  /// - Parameter target: The value to search for.
  /// - Returns: The stored equivalent element, or `nil` if not found.
  func getRepresentative(for target: Element) -> Element? {
    return self._core.representative(of: target)
  }

  init() {
    self._core = .init()
  }

  /// Inserts the given element into the skip list.
  ///
  /// - Parameter newValue: The value to insert.
  /// - Returns: The existing stored element blocking change,
  ///   or `nil` if `newValue` was newly added.
  mutating func insert(_ newValue: Element) -> Element? {
    self._ensureUnique()
    return self._core.insert(newValue)
  }

  struct Iterator: IteratorProtocol {
    /// The current node in the skip list iteration.
    var current: Core.Node

    mutating func next() -> Element? {
      defer {
        current = current.forward
      }
      return current.finiteValue
    }
  }

  func makeIterator() -> Iterator {
    // Iterate to the bottom layer.
    var pointer = self._core.head
    while pointer !== self._core.bottom {
      pointer = pointer.below
    }

    // Iterate from the bottom layer.
    if pointer.value == .maximum {
      pointer = pointer.forward
    }
    return .init(current: pointer)
  }

  /// Canonicalizes the stored value equivalent to the given element, if present, replacing it with `target`.
  ///
  /// - Parameter target: The element whose equivalent is to be updated.
  /// - Returns: The previous stored element if found, or `nil` if not present.
  mutating func setRepresentative(for target: Element) -> Element? {
    self._ensureUnique()
    return self._core.representative(of: target, doCanonize: true)
  }

  var underestimatedCount: Int { self.count }
}

extension SkipList.Core.ExtendedElement: Comparable {
  static func < (lhs: Self, rhs: Self) -> Bool {
    return Self.compare(lhs, rhs) < 0
  }
  static func == (lhs: Self, rhs: Self) -> Bool {
    return Self.compare(lhs, rhs) == 0
  }

  static func > (lhs: Self, rhs: Self) -> Bool {
    return Self.compare(lhs, rhs) > 0
  }
  static func <= (lhs: Self, rhs: Self) -> Bool {
    return Self.compare(lhs, rhs) <= 0
  }
  static func >= (lhs: Self, rhs: Self) -> Bool {
    return Self.compare(lhs, rhs) >= 0
  }

  /// Compares two extended elements according to skip list ordering rules.
  ///
  /// - Parameter lhs: The first (*i.e.* left) operand.
  /// - Parameter rhs: The second (*i.e.* right) operand.
  /// - Returns an integer giving the ordering relation between `lhs` and `rhs`,
  ///   given as equivalent to the relationship between the returned value
  ///   (on the left side) and `0` (on the right side).
  static func compare(_ lhs: Self, _ rhs: Self) -> Int {
    return switch (lhs, rhs) {
    case (.normal(let l), .normal(let r))
    where TotalOrdering.areEquivalent(l.sample, r.sample):
      fallthrough
    case (.maximum, .maximum), (.superMaximum, .superMaximum):
      0
    case (.normal(let l), .normal(let r))
    where TotalOrdering.areIncreasing(l.sample, r.sample):
      fallthrough
    case (.normal, .maximum), (.normal, .superMaximum),
      (.maximum, .superMaximum):
      -1
    case (_, .normal), (.superMaximum, .maximum):
      +1
    }
  }
}

extension SkipList.Core.ExtendedElement: CustomDebugStringConvertible {
  /// A shorthand to calculate the containing type's name.
  private static var typeName: String { .init(reflecting: Self.self) }

  var debugDescription: String {
    switch self {
    case .normal(let value):
      Self.typeName + ".normal(\(String(reflecting: value.sample)))"
    case .maximum:
      Self.typeName + ".maximum"
    case .superMaximum:
      Self.typeName + ".superMaximum"
    }
  }
}
