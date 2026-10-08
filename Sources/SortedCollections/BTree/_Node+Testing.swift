//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Collections open source project
//
// Copyright (c) 2021 - 2026 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
//
// SPDX-License-Identifier: Apache-2.0 WITH Swift-exception
//
//===----------------------------------------------------------------------===//

#if UnstableSortedCollections

extension _Node {
  /// Initialize a node from a list of key-value tuples.
  package init<C: Collection>(
    _keyValuePairs keyValuePairs: C,
    children: [_Node<Key, Value>]? = nil,
    capacity: Int
  ) where C.Element == Element {
    precondition(keyValuePairs.count <= capacity, "Too many key-value pairs")
    self.init(withCapacity: capacity, isLeaf: children == nil)

    unsafe self.update { handle in
      let sortedKeyValuePairs = keyValuePairs.sorted(by: { $0.key < $1.key })

      for (index, pair) in sortedKeyValuePairs.enumerated() {
        let (key, value) = pair
        unsafe handle.keys.advanced(by: index).initialize(to: key)
        unsafe handle.values?.advanced(by: index).initialize(to: value)
      }

      if let children = children {
        for (index, child) in children.enumerated() {
          unsafe handle.children!.advanced(by: index).initialize(to: child)
        }

        unsafe handle.depth = handle[childAt: 0].storage.header.depth + 1
      }

      let totalChildElements = children?.reduce(0, { $0 + $1._subtreeCount })

      unsafe handle.elementCount = keyValuePairs.count
      unsafe handle.subtreeCount = keyValuePairs.count + (totalChildElements ?? 0)
    }
  }

  /// Converts a node to a single array.
  package func toArray() -> [Element] {
    unsafe self.read { handle in
      if handle.isLeaf {
        return (unsafe 0 ..< handle.elementCount).map { unsafe handle[elementAt: $0] }
      } else {
        var elements = [Element]()
        for i in unsafe 0..<handle.elementCount {
          elements.append(contentsOf: unsafe handle[childAt: i].toArray())
          elements.append(unsafe handle[elementAt: i])
        }
        elements.append(contentsOf: unsafe handle[childAt: handle.elementCount].toArray())
        return elements
      }
    }
  }
}

#endif
