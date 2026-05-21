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

import Foundation

/// The probability used to promote nodes to higher levels in the skip list.
private let oneOverE: Double = exp(-1.0)

/// Encapsulate which item-level operation is desired.
enum ReplaceAction<Element> {
  /// Make sure the list has a value equivalent to this one,
  /// either by replacement or insertion.
  case add(value: Element, replace: Bool)
  /// Check if the list has any values equivalent to this one.
  case confirm(value: Element)
  /// Ensure that the list no longer has a value equivalent to this one.
  case remove(value: Element)

  /// The value being processed.
  var value: Element {
    switch self {
    case .add(value: let val, replace: _), .confirm(value: let val),
      .remove(value: let val):
      val
    }
  }
}

/// Encapsulate a replaced item result.
enum ReplaceResult<Element> {
  /// The submitted item was directly added.
  case added
  /// There's an equivalent item, possibly replaced by the submitted one.
  case existed(old: Element, replaced: Bool)
  /// The list didn't have any equivalent item.
  case notPresent
  /// This equivalent value was found an deleted.
  case removed(old: Element)
}

// MARK: Skip List Implementation

extension SortedSet {
  /// An internal class that implements the skip-list structure.
  final class SkipList {
    /// Find the location of the desired value in the list,
    /// then apply the given action.
    func exchange(_ action: ReplaceAction<Element>) -> ReplaceResult<Element> {
      let target = action.value
      let priorToTargetNodes = self.lastNodes(before: target)
      switch action {
      case .add(_, let doReplace):
        guard let coreRowPrior = priorToTargetNodes.first else {
          // Create the list.
          assert(rowHeads.isEmpty)
          rowHeads.append((count: 1, head: Node(target)))
          return .added
        }
        guard !coreRowPrior.isPresent else {
          // (Possibly) modify the value's existing node.
          let oldValue: Element
          if let priorNode = coreRowPrior.prior {
            oldValue = priorNode.successors[0].value
            if doReplace {
              priorNode.successors[0].value = target
            }
          } else {
            // Change the head node.
            oldValue = rowHeads[0].head.value
            if doReplace {
              rowHeads[0].head.value = target
            }
          }
          return .existed(old: oldValue, replaced: doReplace)
        }

        // Create a node for the new value, then insert it.
        let targetNode = Node(target)
        for (index, (prior, _)) in priorToTargetNodes.enumerated() {
          if let priorNode = prior {
            // Put the target node between its prior and subsequent nodes,
            // skipping that last part if the prior node was the row's last.
            if priorNode.successors.count > index {
              let subsequentNode = priorNode.successors[index]
              targetNode.successors.append(subsequentNode)
            }
            priorNode.successors[index] = targetNode
          } else {
            // The target node is the row's new head, bumping the old one to
            // second in the row.
            targetNode.successors.append(rowHeads[index].head)
            rowHeads[index].head = targetNode
          }
          rowHeads[index].count += 1

          // Put the probalistic chances of insertion in later rows here instead
          // of the beginning of the next loop. This lets the loop work with
          // the core row.
          guard rowHeads[index].count > 2 else { break }
          guard Double.random(in: 0..<1) < oneOverE else { break }
        }
        return .added
      case .confirm:
        guard let coreRowPrior = priorToTargetNodes.first else {
          return .notPresent
        }
        guard coreRowPrior.isPresent else { return .notPresent }
        guard let priorNode = coreRowPrior.prior else {
          return .existed(old: rowHeads[0].head.value, replaced: false)
        }

        let targetNode = priorNode.successors[0]
        return .existed(old: targetNode.value, replaced: false)
      case .remove:
        var old: Element?
        for (index, (prior, isPresent)) in priorToTargetNodes.enumerated() {
          guard isPresent else { break }

          if let priorNode = prior {
            let targetNode = priorNode.successors[index]
            if targetNode.successors.count > index {
              // Shift the target's successor node up.
              priorNode.successors[index] = targetNode.successors[index]
            } else {
              // This node becomes the row's final node.
              priorNode.successors.remove(at: index)
            }
            old = targetNode.value
            rowHeads[index].count -= 1
          } else {
            // The row's head is the node to be deleted.
            old = rowHeads[index].head.value
            if rowHeads[index].head.successors.count > index {
              // Shift this row's second node up.
              let subsequentNode = rowHeads[index].head.successors[index]
              rowHeads[index].count -= 1
              rowHeads[index].head = subsequentNode
            } else {
              // Removing this row's sole element means deleting the row.
              assert(rowHeads[index].count == 1)
              assert(rowHeads.indices.last == index)
              rowHeads.remove(at: index)
            }
          }
        }
        return old.map { .removed(old: $0) } ?? .notPresent
      }
    }

    /// The data for a single list-data/search-shortcut line.
    typealias HeadData = (count: Int, head: Node)
    /// The actual list data and its search shortcuts
    typealias HeadLevels = [HeadData]

    /// Create an empty skip-list.
    convenience init() {
      self.init(strictlyIncreasing: EmptyCollection())
    }

    /// Creates an independent copy of the given skip list.
    convenience init(cloning other: SkipList) {
      guard let bottomLevel = other.rowHeads.first?.head else {
        self.init()
        return
      }

      self.init(strictlyIncreasing: bottomLevel.nodeList(for: 0).map(\.value))
    }

    /// Creates a skip list with all the given values.
    ///
    /// - Precondition: the elements in `values` must already be in a strictly
    ///   increasing order according to the sorting critiera.
    /// - Parameter values: The elements to be inserted.
    init(strictlyIncreasing values: some Sequence<Element>) {
      // Create the bottom-level list.
      if let bottomLevel = Self.nodeList(from: values) {
        rowHeads.append(bottomLevel)
      } else {
        return
      }

      // Add new node levels by copying part of the previous level.
      while rowHeads.last!.count > 2 {
        var nextLevel = [Node]()
        let lastLevel = rowHeads.last!
        let lastLevelIndex = rowHeads.indices.last!
        for node in lastLevel.head.nodeList(for: lastLevelIndex)
        where Double.random(in: 0..<1) < oneOverE {
          nextLevel.append(node)
        }
        guard let firstNextNode = nextLevel.first,
          nextLevel.count < lastLevel.count
        else {
          // No point in levels that keep no nodes or all nodes.
          break
        }

        let nextHeadData = (count: nextLevel.count, head: firstNextNode)
        rowHeads.append(nextHeadData)
        for (leader, trailer) in zip(
          nextLevel.dropLast(),
          nextLevel.dropFirst()
        ) {
          leader.successors.append(trailer)
        }
      }
    }

    /// Find the node for each level that's immediately before the node for
    /// the given value,
    /// and whether that value is present in that level.
    ///
    /// If the value isn't in a level,
    /// the returned node is where it would be inserted.
    /// If the value would be the first node in a given row,
    /// `nil` is returned as the prior node.
    func lastNodes(before needle: Element) -> [(prior: Node?, isPresent: Bool)]
    {
      var result = [(prior: Node?, isPresent: Bool)]()
      var lastSearchedNode: Node? = nil
      var lastSearchedPresence: Bool? = nil
      result.reserveCapacity(rowHeads.count)

      // Search from the sparsest layer to the densest for
      // the first node that can't be ranked lower than the target.
      // Use that node as the starting point in the immediately lower layer.
      for levelIndex in rowHeads.indices.reversed() {
        (lastSearchedNode, lastSearchedPresence) =
          (lastSearchedNode ?? rowHeads[levelIndex].head)
          .lastNode(before: needle, at: levelIndex)
        result.append((lastSearchedNode, lastSearchedPresence ?? false))
      }

      // The results were appended for the sparsest row to the densest,
      // but `rowHeads` stores densest to sparsest.
      return result.reversed()
    }

    /// A single node in the skip list.
    final class Node {
      var value: Element
      /// Forward pointers to nodes at various levels.
      /// Level 0 is the full ordered list.
      var successors: [Node]

      @inlinable
      static func eq(_ lhs: Element, _ rhs: Element) -> Bool {
        return TotalOrdering.areEquivalent(lhs, rhs)
      }

      @inlinable
      static func gt(_ lhs: Element, _ rhs: Element) -> Bool {
        return TotalOrdering.areDecreasing(lhs, rhs)
      }

      init(_ value: Element) {
        self.value = value
        self.successors = Array()
      }

      /// Search for the node in the given row that has the highest rank before
      /// the target value's rank,
      /// and if its following node has the target rank.
      ///
      /// If every node in the row is at or after the target value,
      /// `prior` will be `nil`.
      /// If every node in the row is before the target value,
      /// `isPresent` will be `nil`.
      func lastNode(before needle: Element, at level: Int) -> (
        prior: Node?, isPresent: Bool?
      ) {
        guard Self.lt(self.value, needle) else {
          // Already at or past target
          return (prior: nil, isPresent: Self.eq(self.value, needle))
        }

        // Check for a change from before target to at or after target
        let nodes = Array(self.nodeList(for: level))
        for nodePair in zip(nodes.dropLast(), nodes.dropFirst()) {
          guard Self.lt(nodePair.1.value, needle) else {
            // At or past the needle value
            return (
              prior: nodePair.0, isPresent: Self.eq(nodePair.1.value, needle)
            )
          }
        }

        // All nodes in this row are before the target value.
        return (prior: nodes.last, isPresent: nil)
      }

      @inlinable
      static func lt(_ lhs: Element, _ rhs: Element) -> Bool {
        return TotalOrdering.areIncreasing(lhs, rhs)
      }

      /// Returns a sequence of this node's neighbors at the given level.
      func nodeList(for level: Int) -> NodeLevelSequence {
        return .init(current: successors[level], level: level)
      }
    }
    /// A node's linked list, but only at a specific successor level.
    struct NodeLevelSequence: Sequence, IteratorProtocol {
      var current: Node?
      let level: Int

      mutating func next() -> Node? {
        defer {
          current = current?.successors[level]
        }

        return current
      }
    }

    /// Generate a level-0 linked node-list from the given sequence.
    static func nodeList(from values: some Sequence<Element>) -> HeadData? {
      var iterator = values.makeIterator()
      guard let firstValue = iterator.next() else { return nil }

      var node = Node(firstValue)
      var result = (count: 1, head: node)
      while let value = iterator.next() {
        let nextNode = Node(value)
        result.count += 1
        node.successors.append(nextNode)
        node = nextNode
      }
      return result
    }

    /// The values expressed as a binary-search linked-lists
    var rowHeads = HeadLevels()
  }
}
