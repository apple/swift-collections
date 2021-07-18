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

@usableFromInline
internal let _PACKED_OFFSET_LIST_MAX_SIZE = 16

extension _BTree {
  /// A stack-allocated list of some values.
  /// - Warning: This may hold strong references to objects after they
  ///     do not put non-trivial types in this.
  @usableFromInline
  internal struct FixedSizeArray<Value> {
    @usableFromInline
    internal var depth: UInt8
    
    @usableFromInline
    internal var values: (
      Value, Value, Value, Value,
      Value, Value, Value, Value,
      Value, Value, Value, Value,
      Value, Value, Value, Value
    )
    
    @inlinable
    @inline(__always)
    internal init(repeating initialValue: Value, depth: UInt8 = 0) {
      self.depth = depth
      self.values = (
        initialValue, initialValue, initialValue, initialValue,
        initialValue, initialValue, initialValue, initialValue,
        initialValue, initialValue, initialValue, initialValue,
        initialValue, initialValue, initialValue, initialValue
      )
    }
    
    /// Appends a value to the offset list
    @inlinable
    @inline(__always)
    internal mutating func append(_ offset: Value) {
      assert(depth < _PACKED_OFFSET_LIST_MAX_SIZE, "Out of bounds access in offset list.")
      self.depth &+= 1
      self[self.depth] = offset
    }
    
    /// Pops a value from the offset list
    @inlinable
    @inline(__always)
    internal mutating func pop() -> Value {
      assert(depth > 0, "Cannot pop empty list")
      defer { self.depth &-= 1 }
      return self[self.depth]
    }
    
    @inlinable
    @inline(__always)
    internal subscript(_ offset: UInt8) -> Value {
      get {
        assert(offset <= depth && depth <= _PACKED_OFFSET_LIST_MAX_SIZE, "Out of bounds access in offset list.")
        
        switch offset {
        case 0: return self.values.0
        case 1: return self.values.1
        case 2: return self.values.2
        case 3: return self.values.3
        case 4: return self.values.4
        case 5: return self.values.5
        case 6: return self.values.6
        case 7: return self.values.7
        case 8: return self.values.8
        case 9: return self.values.9
        case 10: return self.values.10
        case 11: return self.values.11
        case 12: return self.values.12
        case 13: return self.values.13
        case 14: return self.values.14
        case 15: return self.values.15
        default: preconditionFailure("Packed offset list too small.")
        }
      }
      
      _modify {
        assert(offset <= depth && depth <= _PACKED_OFFSET_LIST_MAX_SIZE, "Out of bounds access in offset list.")
        switch offset {
        case 0: yield &self.values.0
        case 1: yield &self.values.1
        case 2: yield &self.values.2
        case 3: yield &self.values.3
        case 4: yield &self.values.4
        case 5: yield &self.values.5
        case 6: yield &self.values.6
        case 7: yield &self.values.7
        case 8: yield &self.values.8
        case 9: yield &self.values.9
        case 10: yield &self.values.10
        case 11: yield &self.values.11
        case 12: yield &self.values.12
        case 13: yield &self.values.13
        case 14: yield &self.values.14
        case 15: yield &self.values.15
        default: preconditionFailure("Packed offset list too small.")
        }
      }
    }
  }
}
