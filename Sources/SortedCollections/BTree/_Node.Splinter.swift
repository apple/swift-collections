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
  /// Represents the result of a overfilled node's split.
  @usableFromInline
  internal struct Splinter {
    @inlinable
    @inline(__always)
    internal init(element: Element, rightChild: _Node<Key, Value>) {
      self.element = element
      self.rightChild = rightChild
    }
    
    /// The former median element which should be propagated upward.
    @usableFromInline
    internal let element: Element
    
    /// The right product of the node split.
    @usableFromInline
    internal var rightChild: _Node<Key, Value>
    
    /// Converts the splinter object to a node.
    /// - Parameters:
    ///   - node: The node generating the splinter. Becomes the returned
    ///     node's left child.
    ///   - capacity: The desired capacity of the new node.
    /// - Returns: A new node of `capacity` with a single element.
    @inlinable
    @inline(__always)
    internal __consuming func toNode(
      leftChild: _Node<Key, Value>,
      capacity: Int
    ) -> _Node {
      return _Node(
        leftChild: leftChild,
        separator: element,
        rightChild: rightChild,
        capacity: capacity
      )
    }
  }
}
