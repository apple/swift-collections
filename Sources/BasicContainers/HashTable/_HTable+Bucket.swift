//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Collections open source project
//
// Copyright (c) 2021 - 2026 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
//
//===----------------------------------------------------------------------===//

#if !COLLECTIONS_SINGLE_MODULE
import InternalCollectionsUtilities
#endif

#if compiler(>=6.2)
extension _HTable {
  /// Identifies a particular bucket within a hash table by its offset.
  /// Having a dedicated wrapper type for this prevents passing a bucket number
  /// to a function that expects a word index, or vice versa.
  @usableFromInline
  @frozen
  package struct Bucket {
    @usableFromInline
    internal typealias Word = _HTable.Word

    /// The distance of this bucket from the first bucket in the hash table.
    @_alwaysEmitIntoClient
    package var _offset: UInt

    @inlinable
    @_transparent
    package init(offset: UInt) {
      self._offset = offset
    }

    @inlinable
    @_transparent
    package init(offset: Int) {
      assert(offset >= 0)
      self._offset = UInt(bitPattern: offset)
    }

    @inlinable
    @_transparent
    package init(word: Int, bit: UInt) {
      let word = UInt(bitPattern: word)
      self.init(offset: (word &<< Word.wordShift) | (bit & Word.wordMask))
    }

    @inlinable
    package var offset: Int {
      @_transparent
      get { Int(bitPattern: _offset) }
    }
  }
}

extension _HTable.Bucket: CustomStringConvertible {
  @_transparent
  @usableFromInline
  package var description: String {
    "⌗\(_offset)"
  }
}

extension _HTable.Bucket: Equatable {
  @_transparent
  @usableFromInline
  package static func == (left: Self, right: Self) -> Bool {
    left.offset == right.offset
  }
}

extension _HTable.Bucket: Comparable {
  @_transparent
  @usableFromInline
  package static func < (left: Self, right: Self) -> Bool {
    left.offset < right.offset
  }
}

extension _HTable.Bucket {
  @_alwaysEmitIntoClient
  @_transparent
  package var word: Int {
    Int(truncatingIfNeeded: offset &>> Word.wordShift)
  }
  
  @_alwaysEmitIntoClient
  @_transparent
  package var bit: UInt {
    _offset & Word.wordMask
  }

  @_alwaysEmitIntoClient
  @_transparent
  package var isOnWordBoundary: Bool {
    bit == 0
  }

  @_alwaysEmitIntoClient
  @_transparent
  package mutating func advanceToNextWord() {
    _offset &= ~Word.wordMask
    _offset &+= 1 &<< Word.wordShift
  }
}

extension UnsafeMutableBufferPointer where Element: ~Copyable {
  @_alwaysEmitIntoClient
  package subscript(bucket: _HTable.Bucket) -> Element {
    @_transparent
    unsafeAddress {
      return .init(_ptr(at: bucket.offset))
    }
    @_transparent
    nonmutating unsafeMutableAddress {
      return _ptr(at: bucket.offset)
    }
  }
  
  @_alwaysEmitIntoClient
  @_transparent
  package func _ptr(
    at bucket: _HTable.Bucket
  ) -> UnsafeMutablePointer<Element> {
    _ptr(at: bucket.offset)
  }
  
  @_alwaysEmitIntoClient
  @_transparent
  package func _initializeElement(
    at bucket: _HTable.Bucket,
    to value: consuming Element
  ) {
    initializeElement(at: bucket.offset, to: value)
  }
  
  @_alwaysEmitIntoClient
  @_transparent
  package func _extracting(_ buckets: Range<_HTable.Bucket>) -> Self {
    _extracting(
      uncheckedFrom: buckets.lowerBound.offset,
      to: buckets.upperBound.offset)
  }
}

extension Range where Bound == _HTable.Bucket {
  @_alwaysEmitIntoClient
  package var _offsets: Range<Int> {
    @_transparent
    get {
      .init(uncheckedBounds: (lowerBound.offset, upperBound.offset))
    }
  }
}

#endif
