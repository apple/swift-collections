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
  @usableFromInline
  internal struct Iterator: IteratorProtocol {
    @usableFromInline
    internal let tree: _BTree
    
    @usableFromInline
    internal var offsets: UnsafePath.Offsets
    
    @usableFromInline
    internal var parents: FixedSizeArray<Unmanaged<Node.Storage>>
    
    @usableFromInline
    internal var currentNode: Unmanaged<Node.Storage>
    
    @usableFromInline
    internal var slot: Int
    
    @inlinable
    @inline(__always)
    internal init(tree: _BTree) {
      self.tree = tree
      
      self.offsets = .init(repeating: 0)
      self.parents = .init(repeating: .passUnretained(tree.root.storage))
      
      // TODO: maybe convert to unowned(unsafe)
      var node = tree.root
      while !node.read({ $0.isLeaf }) {
        self.parents.append(Unmanaged.passUnretained(node.storage))
        self.offsets.append(0)
        
        node = node.read({ $0[childAt: 0] })
      }
      

      self.currentNode = .passUnretained(node.storage)
      self.slot = 0
    }
    
    @inlinable
    @inline(__always)
    internal mutating func next() -> Element? {
      if _slowPath(self.slot == -1) {
        return nil
      }
      
      return self.currentNode._withUnsafeGuaranteedRef { storage in
        storage.read({ handle in
          defer {
            // If we're not a leaf, descend to the next child
            if !handle.isLeaf {
              self.parents.append(self.currentNode)
              self.offsets.append(UInt16(self.slot + 1))
              var node = handle[childAt: self.slot + 1]
              
              while !node.read({ $0.isLeaf }) {
                self.offsets.append(0)
                self.parents.append(.passUnretained(node.storage))
                node = node.read({ $0[childAt: 0] })
              }
              
              self.currentNode = .passUnretained(node.storage)
              self.slot = 0
            } else {
              if self.slot < handle.elementCount - 1 {
                self.slot += 1
              } else {
                while true {
                  // If we are at a leaf, then ascend to the
                  let parent = self.parents.pop()
                  let offset = self.offsets.pop()
                  
                  let parentElements = parent._withUnsafeGuaranteedRef { $0.read({ $0.elementCount }) }
                  
                  if offset < parentElements {
                    self.currentNode = parent
                    self.slot = Int(offset)
                    break
                  } else if self.parents.depth == 0 {
                    self.slot = -1
                    break
                  }
                }
              }
            }
          }
          
          return storage.read({ $0[elementAt: self.slot] })
        })
      }
    }
  }
  
  @inlinable
  internal func makeIterator() -> Iterator {
    return Iterator(tree: self)
  }
}
