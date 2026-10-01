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

extension _BTree: Sequence {
  @inlinable
  package func forEach(_ body: (Element) throws -> Void) rethrows {
    func loop(node: Unmanaged<Node.Storage>) throws {
      unsafe try node._withUnsafeGuaranteedRef { storage in
        unsafe try storage.read { handle in
          for i in unsafe 0 ..< handle.elementCount {
            if !handle.isLeaf {
              unsafe try loop(node: .passUnretained(handle[childAt: i].storage))
            }
            
            unsafe try body(handle[elementAt: i])
          }
          
          if !handle.isLeaf {
            let lastChild: Unmanaged =
              unsafe .passUnretained(handle[childAt: handle.childCount - 1].storage)
            unsafe try loop(node: lastChild)
          }
        }
      }
    }
    
    unsafe try loop(node: .passUnretained(self.root.storage))
  }
  
  @usableFromInline
  @safe
  package struct Iterator: IteratorProtocol {
    @usableFromInline
    internal let tree: _BTree
    
    @usableFromInline
    internal var slots: [Slot]
    
    @usableFromInline
    @unsafe
    internal var path: [Unmanaged<Node.Storage>]
    
    /// Creates an iterator to the element within a tree corresponding to a specific index
    @inlinable
    @inline(__always)
    package init(forTree tree: _BTree, startingAt index: Index) {
      self.tree = tree
      
      if _slowPath(self.tree.isEmpty || index.slot == -1) {
        self.slots = []
        unsafe self.path = []
        return
      }
      
      self.slots = []
      for d in 0..<index.childSlots.depth {
        slots.append(index.childSlots[d])
      }
      self.slots.append(UInt16(index.slot))
      
      unsafe self.path = []

      var node: Unmanaged = unsafe .passUnretained(tree.root.storage)
      unsafe self.path.append(node)
      for depth in 0..<index.childSlots.depth {
        let childSlot = index.childSlots[depth]
        
        unsafe node._withUnsafeGuaranteedRef {
          unsafe $0.read { handle in
            unsafe node = .passUnretained(handle[childAt: Int(childSlot)].storage)
            unsafe self.path.append(node)
          }
        }
      }
    }
    
    /// Creates an iterator to the first element within a tree.
    @inlinable
    @inline(__always)
    package init(forTree tree: _BTree) {
      self.tree = tree
      
      self.slots = []
      unsafe self.path = []

      // Simple case for an empty tree
      if self.tree.isEmpty {
        return
      }
      
      var nextNode: Unmanaged? = unsafe .passUnretained(tree.root.storage)
      while let node = unsafe nextNode {
        unsafe self.path.append(node)
        self.slots.append(0)
        
        unsafe node._withUnsafeGuaranteedRef {
          unsafe $0.read { handle in
            if handle.isLeaf {
              unsafe nextNode = nil
            } else {
              unsafe nextNode = .passUnretained(handle[childAt: 0].storage)
            }
          }
        }
      }
    }
    
    @inlinable
    @inline(__always)
    package mutating func _advanceState(withLeaf handle: Node.UnsafeHandle) {
      // If we're not a leaf, descend to the next child
      if !handle.isLeaf {
        // Go to the right child
        self.slots[self.slots.count - 1] += 1
        var nextNode: Unmanaged? = unsafe .passUnretained(
          handle[childAt: Int(self.slots[self.slots.count - 1])].storage)

        while let node = unsafe nextNode {
          unsafe self.path.append(node)
          self.slots.append(0)
          
          unsafe node._withUnsafeGuaranteedRef {
            unsafe $0.read { handle in
              if handle.isLeaf {
                unsafe nextNode = nil
              } else {
                unsafe nextNode = .passUnretained(handle[childAt: 0].storage)
              }
            }
          }
        }
      } else {
        if unsafe _fastPath(self.slots[self.slots.count - 1] < handle.elementCount - 1) {
          self.slots[self.slots.count - 1] += 1
        } else {
          unsafe _ = path.removeLast()
          _ = slots.removeLast()
          
          while unsafe !path.isEmpty {
            let parent = unsafe path[path.count - 1]
            let slot = slots[slots.count - 1]
            
            let parentElementCount = unsafe parent._withUnsafeGuaranteedRef {
              unsafe $0.read({ unsafe $0.elementCount })
            }
            
            if slot < parentElementCount {
              break
            } else {
              unsafe _ = path.removeLast()
              _ = slots.removeLast()
            }
          }
        }
      }
    }
    
    @inlinable
    @inline(never)
    package mutating func next() -> Element? {
      // Check slot sentinel value for end of tree.
      if unsafe _slowPath(path.isEmpty) {
        return nil
      }
      
      let element = unsafe path[path.count - 1]._withUnsafeGuaranteedRef {
        unsafe $0.read {
          unsafe $0[elementAt: Int(slots[slots.count - 1])]
        }
      }
      
      unsafe path[path.count - 1]._withUnsafeGuaranteedRef {
        unsafe $0.read({ handle in
          unsafe self._advanceState(withLeaf: handle)
        })
      }
      
      return element
    }
  }
  
  @inlinable
  package func makeIterator() -> Iterator {
    return Iterator(forTree: self)
  }
}

#endif
