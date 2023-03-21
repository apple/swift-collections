//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Collections open source project
//
// Copyright (c) 2023 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
//
//===----------------------------------------------------------------------===//

extension Rope: Sequence {
  public func makeIterator() -> Iterator {
    Iterator(self, from: self.startIndex)
  }
  
  public func makeIterator(from start: Index) -> Iterator {
    Iterator(self, from: start)
  }
  
  public struct Iterator: IteratorProtocol {
    let rope: Rope
    private(set) var index: Index

    init(_ rope: Rope, from start: Index) {
      rope.validate(start)
      self.rope = rope
      self.index = start
      self.rope.grease(&index)
    }
    
    public mutating func next() -> Element? {
      guard let leaf = index._leaf else { return nil }
      let item = leaf.read { $0.children[index._path[0]].value }
      rope.formIndex(after: &index)
      return item
    }
  }
}
