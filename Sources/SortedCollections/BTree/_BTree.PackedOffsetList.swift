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
  /// A stack-allocated list of UInt16 values.
  @usableFromInline
  internal struct PackedOffsetList {
    @usableFromInline
    internal var depth: UInt8
    
    @usableFromInline
    internal var offsets: (
      UInt16, UInt16, UInt16, UInt16,
      UInt16, UInt16, UInt16, UInt16,
      UInt16, UInt16, UInt16, UInt16,
      UInt16, UInt16, UInt16, UInt16
    )
    
    @inlinable
    @inline(__always)
    internal init(depth: UInt8 = 0) {
      self.depth = depth
      self.offsets = (
        0, 0, 0, 0,
        0, 0, 0, 0,
        0, 0, 0, 0,
        0, 0, 0, 0
      )
    }
    
    /// Appends a value to the offset list
    @inlinable
    @inline(__always)
    internal mutating func append(_ offset: UInt16) {
      assert(depth < _PACKED_OFFSET_LIST_MAX_SIZE, "Out of bounds access in offset list.")
      self.depth &+= 1
      self[self.depth] = offset
    }
    
    @inlinable
    @inline(__always)
    internal subscript(_ offset: UInt8) -> UInt16 {
      get {
        assert(offset <= depth && depth <= _PACKED_OFFSET_LIST_MAX_SIZE, "Out of bounds access in offset list.")
        switch offset {
        case 0: return self.offsets.0
        case 1: return self.offsets.1
        case 2: return self.offsets.2
        case 3: return self.offsets.3
        case 4: return self.offsets.4
        case 5: return self.offsets.5
        case 6: return self.offsets.6
        case 7: return self.offsets.7
        case 8: return self.offsets.8
        case 9: return self.offsets.9
        case 10: return self.offsets.10
        case 11: return self.offsets.11
        case 12: return self.offsets.12
        case 13: return self.offsets.13
        case 14: return self.offsets.14
        case 15: return self.offsets.15
        default: preconditionFailure("Packed offset list too small.")
        }
      }
      
      _modify {
        assert(offset <= depth && depth <= _PACKED_OFFSET_LIST_MAX_SIZE, "Out of bounds access in offset list.")
        switch offset {
        case 0: yield &self.offsets.0
        case 1: yield &self.offsets.1
        case 2: yield &self.offsets.2
        case 3: yield &self.offsets.3
        case 4: yield &self.offsets.4
        case 5: yield &self.offsets.5
        case 6: yield &self.offsets.6
        case 7: yield &self.offsets.7
        case 8: yield &self.offsets.8
        case 9: yield &self.offsets.9
        case 10: yield &self.offsets.10
        case 11: yield &self.offsets.11
        case 12: yield &self.offsets.12
        case 13: yield &self.offsets.13
        case 14: yield &self.offsets.14
        case 15: yield &self.offsets.15
        default: preconditionFailure("Packed offset list too small.")
        }
      }
    }
  }
}
