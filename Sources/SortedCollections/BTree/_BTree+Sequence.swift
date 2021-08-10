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

extension _BTree: Sequence {
  @inlinable
  internal func forEach(_ body: (Element) throws -> Void) rethrows {
    func loop(node: Unmanaged<Node.Storage>) throws {
      try node._withUnsafeGuaranteedRef { storage in
        try storage.read { handle in
          for i in 0..<handle.elementCount {
            if !handle.isLeaf {
              try loop(node: .passUnretained(handle[childAt: i].storage))
            }
            
            try body(handle[elementAt: i])
          }
          
          if !handle.isLeaf {
            let lastChild: Unmanaged =
              .passUnretained(handle[childAt: handle.childCount - 1].storage)
            try loop(node: lastChild)
          }
        }
      }
    }
    
    try loop(node: .passUnretained(self.root.storage))
  }
  
  @usableFromInline
  internal struct Iterator: IteratorProtocol {
    @usableFromInline
    internal let tree: _BTree
    
    @usableFromInline
    internal var slots: FixedSizeArray<Slot>
    
    @usableFromInline
    internal var path: FixedSizeArray<Unmanaged<Node.Storage>>
    
    /// Creates an iterator to the element within a tree corresponding to a specific index
    @inlinable
    @inline(__always)
    internal init(forTree tree: _BTree, startingAt index: Index) {
      self.tree = tree
      self.slots = index.childSlots
      self.slots.append(UInt16(index.slot))
      
      self.path = .init(repeating: .passUnretained(tree.root.storage))
      
      if self.tree.isEmpty {
        return
      }
      
      var node: Unmanaged = .passUnretained(tree.root.storage)
      for depth in 0..<index.childSlots.depth {
        let childSlot = index.childSlots[depth]
        self.path.append(node)
        
        node._withUnsafeGuaranteedRef {
          $0.read { handle in
            node = .passUnretained(handle[childAt: Int(childSlot)].storage)
          }
        }
      }
    }
    
    /// Creates an iterator to the first element within a tree.
    @inlinable
    @inline(__always)
    internal init(forTree tree: _BTree) {
      self.tree = tree
      
      self.slots = .init(repeating: 0)
      self.path = .init(repeating: .passUnretained(tree.root.storage))
      
      // Simple case for an empty tree
      if self.tree.isEmpty {
        return
      }
      
      // TODO: maybe convert to unowned(unsafe)
      var nextNode: Unmanaged? = .passUnretained(tree.root.storage)
      while let node = nextNode {
        self.path.append(node)
        self.slots.append(0)
        
        node._withUnsafeGuaranteedRef {
          $0.read { handle in
            if handle.isLeaf {
              nextNode = nil
            } else {
              nextNode = .passUnretained(handle[childAt: 0].storage)
            }
          }
        }
      }
    }
    
    @inlinable
    @inline(__always)
    internal mutating func next() -> Element? {
      // Check slot sentinel value for end of tree.
      if _slowPath(path.isEmpty) {
        return nil
      }
      
      return path.last._withUnsafeGuaranteedRef { storage in
        storage.read({ handle in
          defer {
            // If we're not a leaf, descend to the next child
            if !handle.isLeaf {
              // Go to the right child
              slots.last += 1
              var nextNode: Unmanaged? = .passUnretained(handle[childAt: Int(slots.last)].storage)
              
              while let node = nextNode {
                self.path.append(node)
                self.slots.append(0)
                
                node._withUnsafeGuaranteedRef {
                  $0.read { handle in
                    if handle.isLeaf {
                      nextNode = nil
                    } else {
                      nextNode = .passUnretained(handle[childAt: 0].storage)
                    }
                  }
                }
              }
            } else {
              if slots.last < handle.elementCount - 1 {
                slots.last += 1
              } else {
                _ = path.pop()
                _ = slots.pop()
                
                while !path.isEmpty {
                  let parent = path.last
                  let slot = slots.last
                  
                  let parentElementCount = parent._withUnsafeGuaranteedRef {
                    $0.read({ $0.elementCount })
                  }
                  
                  if slot < parentElementCount {
                    break
                  } else {
                    _ = path.pop()
                    _ = slots.pop()
                  }
                }
              }
            }
          }
          
          return storage.read({ $0[elementAt: Int(slots.last)] })
        })
      }
    }
  }
  
  @inlinable
  internal func makeIterator() -> Iterator {
    return Iterator(forTree: self)
  }
}
