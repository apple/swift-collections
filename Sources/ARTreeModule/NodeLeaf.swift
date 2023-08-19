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

struct NodeLeaf {
  var storage: Storage
}

extension NodeLeaf {
  static var type: NodeType { .leaf }

  init(ptr: RawNodeBuffer) {
    self.init(storage: Storage(raw: ptr))
  }
}

extension NodeLeaf {
  static func allocate<Value>(key: Key, value: Value, of: Value.Type) -> Self {
    let size = MemoryLayout<UInt32>.stride + key.count + MemoryLayout<Value>.stride
    let buf = NodeStorage<NodeLeaf>.create(type: .leaf, size: size)
    var leaf = Self(ptr: buf)

    leaf.keyLength = key.count
    leaf.withKeyValue { keyPtr, valuePtr in
      key.withUnsafeBytes {
        UnsafeMutableRawBufferPointer(keyPtr).copyBytes(from: $0)
      }
      valuePtr.pointee = value
    }

    return leaf
  }
}

extension NodeLeaf {
  typealias KeyPtr = UnsafeMutableBufferPointer<KeyPart>

  func withKey<R>(body: (KeyPtr) throws -> R) rethrows -> R {
    return try storage.withUnsafePointer {
      let keyPtr = UnsafeMutableBufferPointer(
        start: $0
          .advanced(by: MemoryLayout<UInt32>.stride)
          .assumingMemoryBound(to: KeyPart.self),
        count: Int(keyLength))
      return try body(keyPtr)
    }
  }

  func withValue<R, Value>(of: Value.Type,
                           body: (UnsafeMutablePointer<Value>) throws -> R) rethrows -> R {
    return try storage.withUnsafePointer {
      return try body(
        $0.advanced(by: MemoryLayout<UInt32>.stride)
          .advanced(by: keyLength)
          .assumingMemoryBound(to: Value.self))
    }
  }

  func withKeyValue<R, Value>(
    body: (KeyPtr, UnsafeMutablePointer<Value>) throws -> R) rethrows -> R {
    return try storage.withUnsafePointer {
      let base = $0.advanced(by: MemoryLayout<UInt32>.stride)
      let keyPtr = UnsafeMutableBufferPointer(
        start: base.assumingMemoryBound(to: KeyPart.self),
        count: Int(keyLength)
      )
      let valuePtr = UnsafeMutableRawPointer(
        keyPtr.baseAddress?.advanced(by: Int(keyLength)))!
        .assumingMemoryBound(to: Value.self)
      return try body(keyPtr, valuePtr)
    }
  }

  var key: Key {
    get { withKey { k in Array(k) } }
  }

  var keyLength: Int {
    get {
      storage.withUnsafePointer {
        Int($0.assumingMemoryBound(to: UInt32.self).pointee)
      }
    }
    set {
      storage.withUnsafePointer {
        $0.assumingMemoryBound(to: UInt32.self).pointee = UInt32(newValue)
      }
    }
  }

  func value<Value>() -> Value {
    return withValue(of: Value.self) { $0.pointee }
  }
}

extension NodeLeaf {
  func keyEquals(with key: Key, depth: Int = 0) -> Bool {
    if key.count != keyLength {
      return false
    }

    return withKey { keyPtr in
      for ii in depth..<key.count {
        if key[ii] != keyPtr[ii] {
          return false
        }
      }

      return true
    }
  }

  func longestCommonPrefix(with other: Self, fromIndex: Int) -> Int {
    let maxComp = Int(min(keyLength, other.keyLength) - fromIndex)

    return withKey { keyPtr in
      return other.withKey { otherKeyPtr in
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

extension NodeLeaf: ManagedNode {
  static func deinitialize(_ storage: NodeStorage<Self>) {
  }
}
