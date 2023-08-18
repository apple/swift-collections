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

struct NodeLeaf<Value> {
  typealias Storage = NodeStorage<Self>
  var storage: Storage
}

extension NodeLeaf {
  init(ptr: RawNodeBuffer) {
      self.init(storage: Storage(ptr))
  }
}

extension NodeLeaf {
  var key: Key { Array(keyPtr) }
  var value: Value { valuePtr.pointee }

  var keyLength: UInt32 {
    get { header.pointee.keyLength }
    set { header.pointee.keyLength = newValue }
  }

  private struct Header {
    var type: NodeType
    var keyLength: UInt32
  }

  private var header: UnsafeMutablePointer<Header> {
    let pointer = storage.getPointer()
    return pointer.assumingMemoryBound(to: Header.self)
  }

  var keyPtr: UnsafeMutableBufferPointer<KeyPart> {
    let pointer = storage.getPointer()
    return UnsafeMutableBufferPointer(
      start: (pointer + MemoryLayout<Header>.stride)
        .assumingMemoryBound(to: KeyPart.self),
      count: Int(keyLength))
  }

  var valuePtr: UnsafeMutablePointer<Value> {
    let ptr = UnsafeMutableRawPointer(self.keyPtr.baseAddress?.advanced(by: Int(keyLength)))!
    return ptr.assumingMemoryBound(to: Value.self)
  }
}

extension NodeLeaf {
  static func allocate(key: Key, value: Value) -> Self {
    let size = MemoryLayout<Header>.stride + key.count + MemoryLayout<Value>.stride
    let buf = NodeStorage<NodeLeaf>.create(type: .leaf, size: size)
    var leaf = Self(ptr: buf)

    leaf.keyLength = UInt32(key.count)
    key.withUnsafeBytes {
      UnsafeMutableRawBufferPointer(leaf.keyPtr).copyBytes(from: $0)
    }
    leaf.valuePtr.pointee = value

    return leaf
  }

  func keyEquals(with key: Key, depth: Int = 0) -> Bool {
    if key.count != keyLength {
      return false
    }

    for ii in depth..<key.count {
      if key[ii] != keyPtr[ii] {
        return false
      }
    }

    return true
  }

  func longestCommonPrefix(with other: Self, fromIndex: Int) -> Int {
    let maxComp = Int(min(keyLength, other.keyLength) - UInt32(fromIndex))
    for index in 0..<maxComp {
      if keyPtr[fromIndex + index] != other.keyPtr[fromIndex + index] {
        return index
      }
    }
    return maxComp
  }
}

extension NodeLeaf: Node {
  var type: NodeType { .leaf }
}
