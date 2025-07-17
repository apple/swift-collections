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

 /// A stack-allocated deque of some values.
///
/// The supports efficient removals from and insertions to the beginning and end.
///
/// - Warning: This may hold strong references to objects after they
///     do not put non-trivial types in this.
@usableFromInline
internal struct _FixedSizeArray<Element> {
  @inlinable
  @inline(__always)
  internal static var maxSize: Int8 { 16 }
  
  @usableFromInline
  internal var depth: Int8
  
  @usableFromInline
  internal var values: (
    Element, Element, Element, Element,
    Element, Element, Element, Element,
    Element, Element, Element, Element,
    Element, Element, Element, Element
  )
  
  @inlinable
  @inline(__always)
  internal init(repeating initialValue: Element, depth: Int8 = 0) {
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
  internal mutating func append(_ value: __owned Element) {
    assert(depth < _FixedSizeArray.maxSize,
           "Out of bounds access in fixed sized array.")
    defer { self.depth &+= 1 }
    self[self.depth] = value
  }
  
  /// Pops a value from the end of offset list
  @inlinable
  @inline(__always)
  internal mutating func pop() -> Element {
    assert(depth > 0, "Cannot pop empty fixed sized array")
    self.depth &-= 1
    return self[self.depth]
  }
  
  /// If the fixed size array is empty
  @inlinable
  @inline(__always)
  internal var isEmpty: Bool { depth == 0 }
  
  /// Refers to the last value in the list
  @inlinable
  @inline(__always)
  internal var last: Element {
    get {
      assert(depth > 0, "Out of bounds access in fixed sized array")
      return self[depth &- 1]
    }
    
    _modify {
      assert(depth > 0, "Out of bounds access in fixed sized array")
      yield &self[depth &- 1]
    }
  }
  
  @inlinable
  @inline(__always)
  internal subscript(_ position: Int8) -> Element {
    get {
      assert(position <= depth && depth <= _FixedSizeArray.maxSize,
             "Out of bounds access in fixed sized array.")
      
      return withUnsafeBytes(of: self.values) { values in
        let p = values.baseAddress!.assumingMemoryBound(to: Element.self)
        return p.advanced(by: Int(position)).pointee
      }
    }
    
    _modify {
      assert(position <= depth && depth <= _FixedSizeArray.maxSize,
             "Out of bounds access in fixed sized array.")
      
      let ptr: UnsafeMutablePointer<Element> =
        withUnsafeMutableBytes(of: &self.values) { values in
        let p = values.baseAddress!.assumingMemoryBound(to: Element.self)
        return p.advanced(by: Int(position))
      }
      
      var value = ptr.move()
      defer { ptr.initialize(to: value) }
      yield &value
    }
  }
}

#if !$Embedded
#if DEBUG
extension _FixedSizeArray: CustomDebugStringConvertible {
  @inlinable
  internal var debugDescription: String {
    var result = "["
    
    for i in 0..<depth {
      if i != 0 {
        result += ", "
      }
      debugPrint(self[i], terminator: "", to: &result)
    }
    
    result += "]"
    return result
  }
}
#endif
#endif
