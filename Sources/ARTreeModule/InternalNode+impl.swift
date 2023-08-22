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

extension InternalNode {
  var partialLength: Int {
    get {
      storage.withHeaderPointer {
        Int($0.pointee.partialLength)
      }
    }
    set {
      assert(newValue <= Const.maxPartialLength)
      storage.withHeaderPointer {
        $0.pointee.partialLength = KeyPart(newValue)
      }
    }
  }

  var partialBytes: PartialBytes {
    get {
      storage.withHeaderPointer {
        $0.pointee.partialBytes
      }
    }
    set {
      storage.withHeaderPointer {
        $0.pointee.partialBytes = newValue
      }
    }
  }

  var count: Int {
    get {
      storage.withHeaderPointer {
        Int($0.pointee.count)
      }
    }
    set {
      storage.withHeaderPointer {
        $0.pointee.count = UInt16(newValue)
      }
    }
  }

  func child(forKey k: KeyPart) -> RawNode? {
    return index(forKey: k).flatMap { child(at: $0) }
  }

  mutating func child(forKey k: KeyPart, ref: inout NodeReference) -> RawNode? {
    if count == 0 {
      return nil
    }

    return index(forKey: k).flatMap { index in
      self.withChildRef(at: index) { ptr in
        ref = NodeReference(ptr)
        return ptr.pointee
      }
    }
  }

  mutating func addChild(forKey k: KeyPart, node: some ArtNode<Spec>) -> UpdateResult<RawNode?> {
    return addChild(forKey: k, node: node.rawNode)
  }

  mutating func copyHeader(from: any InternalNode) {
    self.storage.withHeaderPointer { header in
      header.pointee.count = UInt16(from.count)
      header.pointee.partialLength = UInt8(from.partialLength)
      header.pointee.partialBytes = from.partialBytes
    }
  }

  // Calculates the index at which prefix mismatches.
  func prefixMismatch(withKey key: Key, fromIndex depth: Int) -> Int {
    assert(partialLength <= Const.maxPartialLength, "partial length is always bounded")
    let maxComp = min(partialLength, key.count - depth)

    for index in 0..<maxComp {
      if partialBytes[index] != key[depth + index] {
        return index
      }
    }

    return maxComp
  }

  // TODO: Look everywhere its used, and try to avoid unnecessary RC traffic.
  static func retainChildren(_ children: Children, count: Int) {
    for idx in 0..<count {
      if let c = children[idx] {
        _ = Unmanaged.passRetained(c.buf)
      }
    }
  }
}
