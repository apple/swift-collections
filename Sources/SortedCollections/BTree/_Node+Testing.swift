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

extension _Node {
  /// Initialize a node from a list of key-value tuples.
  @_spi(Testing)
  public init<C: Collection>(
    _keyValuePairs keyValuePairs: C,
    children: [_Node<Key, Value>]? = nil,
    capacity: Int
  ) where C.Element == Element {
    precondition(keyValuePairs.count <= capacity, "Too many key-value pairs.")
    self.init(withCapacity: capacity, isLeaf: children == nil)
    
    self.update { handle in
      let sortedKeyValuePairs = keyValuePairs.sorted(by: { $0.key < $1.key })
      
      for (index, pair) in sortedKeyValuePairs.enumerated() {
        let (key, value) = pair
        handle.keys.advanced(by: index).initialize(to: key)
        handle.values?.advanced(by: index).initialize(to: value)
      }
      
      if let children = children {
        for (index, child) in children.enumerated() {
          handle.children!.advanced(by: index).initialize(to: child)
        }
        
        handle.depth = handle[childAt: 0].storage.header.depth + 1
      }
      
      let totalChildElements = children?.reduce(0, { $0 + $1.read({ $0.subtreeCount }) })
      
      handle.elementCount = keyValuePairs.count
      handle.subtreeCount = keyValuePairs.count + (totalChildElements ?? 0)
    }
  }
  
  /// Converts a node to a single array.
  @_spi(Testing)
  public func toArray() -> [Element] {
    self.read { handle in
      if handle.isLeaf {
        return Array((0..<handle.elementCount).map { handle[elementAt: $0] })
      } else {
        var elements = [Element]()
        for i in 0..<handle.elementCount {
          elements.append(contentsOf: handle[childAt: i].toArray())
          elements.append(handle[elementAt: i])
        }
        elements.append(contentsOf: handle[childAt: handle.elementCount].toArray())
        return elements
      }
    }
  }
}
