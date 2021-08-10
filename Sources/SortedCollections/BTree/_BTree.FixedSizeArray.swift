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

extension _BTree {
  
  /// A stack-allocated deque of some values.
  ///
  /// The supports efficient removals from and insertions to the beginning and end.
  /// 
  /// - Warning: This may hold strong references to objects after they
  ///     do not put non-trivial types in this.
  @usableFromInline
  internal struct FixedSizeArray<Value> {
    @inlinable
    @inline(__always)
    internal static var maxSize: Int8 { 16 }
    
    @usableFromInline
    internal var start: Int8
    
    @usableFromInline
    internal var depth: Int8
    
    @usableFromInline
    internal var values: (
      Value, Value, Value, Value,
      Value, Value, Value, Value,
      Value, Value, Value, Value,
      Value, Value, Value, Value
    )
    
    @inlinable
    @inline(__always)
    internal init(repeating initialValue: Value, depth: Int8 = 0) {
      self.start = 0
      self.depth = depth
      self.values = (
        initialValue, initialValue, initialValue, initialValue,
        initialValue, initialValue, initialValue, initialValue,
        initialValue, initialValue, initialValue, initialValue,
        initialValue, initialValue, initialValue, initialValue
      )
    }
    
    /// Calculates the real underlying offset for a depth
    @inlinable
    @inline(__always)
    internal func _underlyingOffset(for position: Int8) -> Int8 {
      return (self.start &+ position) % FixedSizeArray.maxSize
    }
    
    /// Shifts a real offset by some amount
    @inlinable
    @inline(__always)
    internal func _shiftOffset(_ position: inout Int8, by offset: Int8) {
      position = (position + FixedSizeArray.maxSize + offset) % FixedSizeArray.maxSize
    }
    
    /// Appends a value to the offset list
    @inlinable
    @inline(__always)
    internal mutating func append(_ value: __owned Value) {
      assert(depth < FixedSizeArray.maxSize,
             "Out of bounds access in fixed sized array.")
      defer { self.depth &+= 1 }
      self[self.depth] = value
    }
    
    /// Prepends a value to the offset list
    @inlinable
    @inline(__always)
    internal mutating func prepend(_ value: __owned Value) {
      assert(depth < FixedSizeArray.maxSize,
             "Out of bounds access in fixed sized array.")
      defer { self.depth &+= 1 }
      self._shiftOffset(&self.start, by: -1)
      self[self.start] = value
    }
    
    /// Pops a value from the end of offset list
    @inlinable
    @inline(__always)
    internal mutating func pop() -> Value {
      assert(depth > 0, "Cannot pop empty fixed sized array")
      self.depth &-= 1
      return self[self.depth]
    }
    
    /// Removes a value from the front of offset list
    @inlinable
    @inline(__always)
    internal mutating func shift() -> Value {
      assert(depth > 0, "Cannot shift empty fixed sized array")
      defer {
        self.depth &-= 1
        self._shiftOffset(&self.start, by: 1)
      }
      return self[0]
    }
    
    /// If the fixed size array is empty
    @inlinable
    @inline(__always)
    internal var isEmpty: Bool { depth == 0 }
    
    /// Refers to the last value in the list
    @inlinable
    @inline(__always)
    internal var last: Value {
      get {
        assert(depth > 0, "Out of bounds access in fixed sized array")
        return self[depth - 1]
      }
      
      _modify {
        yield &self[depth - 1]
      }
    }
    
    @inlinable
    @inline(__always)
    internal subscript(_ position: Int8) -> Value {
      get {
        assert(position <= depth && depth <= FixedSizeArray.maxSize,
               "Out of bounds access in fixed sized array.")
        
        let offset = _underlyingOffset(for: position)
        
        return withUnsafePointer(to: self.values) { values in
          values.withMemoryRebound(to: Value.self, capacity: Int(FixedSizeArray.maxSize)) { buffer in
            buffer.advanced(by: Int(offset)).pointee
          }
        }
      }
      
      set {
        assert(position <= depth && depth <= FixedSizeArray.maxSize,
               "Out of bounds access in fixed sized array.")
        
        let offset = _underlyingOffset(for: position)
        
        return withUnsafeMutablePointer(to: &self.values) { values in
          values.withMemoryRebound(to: Value.self, capacity: Int(FixedSizeArray.maxSize)) { buffer in
            let ptr = buffer.advanced(by: Int(offset))
            ptr.deinitialize(count: 1)
            ptr.initialize(to: newValue)
          }
        }
      }
    }
  }
}
