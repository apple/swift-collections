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
  struct Header {
    var keyLength: UInt32
  }

  typealias KeyPtr = UnsafeMutableBufferPointer<KeyPart>
  typealias ValuePtr = UnsafeMutablePointer<Value>

  func withKeyValue<R>(body: (KeyPtr, ValuePtr) throws -> R) rethrows -> R {
    return try storage.withBodyPointer {
      let keyPtr = UnsafeMutableBufferPointer(
        start: $0.assumingMemoryBound(to: KeyPart.self),
        count: Int(keyLength)
      )
      let valuePtr = UnsafeMutableRawPointer(
        keyPtr.baseAddress?.advanced(by: Int(keyLength)))!
        .assumingMemoryBound(to: Value.self)
      return try body(keyPtr, valuePtr)
    }
  }

  var key: Key {
    withKeyValue { k, _ in Array(k) }
  }

  var value: Value {
    get { withKeyValue { $1.pointee } }
    set { withKeyValue { $1.pointee = newValue } }
  }

  var keyLength: UInt32 {
    get {
      storage.withHeaderPointer { $0.pointee.keyLength }
    }
    set {
      storage.withHeaderPointer { $0.pointee.keyLength = newValue }
    }
  }
}

extension NodeLeaf {
  static func allocate(key: Key, value: Value) -> Self {
    let size = MemoryLayout<Header>.stride + key.count + MemoryLayout<Value>.stride
    let buf = NodeStorage<NodeLeaf>.create(type: .leaf, size: size)
    var leaf = Self(ptr: buf)

    leaf.keyLength = UInt32(key.count)
    leaf.withKeyValue { keyPtr, valuePtr in
      key.withUnsafeBytes {
        UnsafeMutableRawBufferPointer(keyPtr).copyBytes(from: $0)
      }
      valuePtr.pointee = value
    }

    return leaf
  }

  func keyEquals(with key: Key, depth: Int = 0) -> Bool {
    if key.count != keyLength {
      return false
    }

    return withKeyValue { keyPtr, _ in
      for ii in depth..<key.count {
        if key[ii] != keyPtr[ii] {
          return false
        }
      }

      return true
    }
  }

  func longestCommonPrefix(with other: Self, fromIndex: Int) -> Int {
    let maxComp = Int(min(keyLength, other.keyLength) - UInt32(fromIndex))

    return withKeyValue { keyPtr, _ in
      return other.withKeyValue { otherKeyPtr, _ in
        for index in 0..<maxComp {
          if keyPtr[fromIndex + index] != otherKeyPtr[fromIndex + index] {
            return index
          }
        }
        return maxComp
      }
    }
  }
}

extension NodeLeaf: Node {
  var type: NodeType { .leaf }
}
