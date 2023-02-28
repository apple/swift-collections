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

#if swift(>=5.8)

@available(macOS 13.3, iOS 16.4, watchOS 9.4, tvOS 16.4, *)
extension _BString {
  internal func hashCharacters(into hasher: inout Hasher) {
    // FIXME: Implement properly normalized comparisons & hashing.
    // This is somewhat tricky as we shouldn't just normalize individual pieces of the string
    // split up on random Character boundaries -- Unicode does not promise that
    // norm(a + c) == norm(a) + norm(b) in this case.
    // To do this properly, we'll probably need to expose new stdlib entry points. :-/
    var it = self.makeCharacterIterator()
    while let character = it.next() {
      let s = String(character)
      s._withNFCCodeUnits { hasher.combine($0) }
    }
    hasher.combine(0xFF as UInt8)
  }
  
  internal func hashCharacters(into hasher: inout Hasher, from range: Range<Index>) {
    var it = self.makeCharacterIterator(from: range.lowerBound)
    let endOffset = range.upperBound._utf8Offset
    while let character = it.next() {
      var s = String(character)
      if it.utf8Offset > endOffset {
        let i = s.unicodeScalars._index(roundingDown: s._utf8Index(at: it.utf8Offset - endOffset))
        s.removeSubrange(i...)
      }
      s._withNFCCodeUnits { hasher.combine($0) }
      if it.utf8Offset >= endOffset {
        break
      }
    }
    hasher.combine(0xFF as UInt8)
  }
  
  /// Feed the UTF-8 encoding of `self` into hasher, with a terminating byte.
  internal func hashUTF8(into hasher: inout Hasher) {
    for chunk in self.rope {
      var string = chunk.string
      string.withUTF8 {
        hasher.combine(bytes: .init($0))
      }
    }
    hasher.combine(0xFF as UInt8)
  }

  /// Feed the UTF-8 encoding of `self[start..<end]` into hasher, with a terminating byte.
  internal func hashUTF8(into hasher: inout Hasher, from start: Index, to end: Index) {
    assert(start <= end)
    guard start < end else {
      hasher.combine(0xFF as UInt8)
      return
    }
    let start = resolve(start, preferEnd: false)
    let end = resolve(start, preferEnd: true)

    var ri = start._rope!
    let endRopeIndex = end._rope!

    if ri == endRopeIndex {
      var str = self.rope[ri].string
      str.withUTF8 {
        let slice = UnsafeRawBufferPointer($0)[start._utf8ChunkOffset ..< end._utf8ChunkOffset]
        hasher.combine(bytes: UnsafeRawBufferPointer(rebasing: slice))
      }
      hasher.combine(0xFF as UInt8)
      return
    }

    var str = self.rope[ri].string
    str.withUTF8 {
      let slice = UnsafeRawBufferPointer($0).prefix(start._utf8ChunkOffset)
      hasher.combine(bytes: UnsafeRawBufferPointer(rebasing: slice))
    }

    rope.formIndex(after: &ri)
    while ri < endRopeIndex {
      var string = rope[ri].string
      string.withUTF8 {
        hasher.combine(bytes: .init($0))
      }
    }

    str = self.rope[ri].string
    str.withUTF8 {
      let slice = UnsafeRawBufferPointer($0)[..<end._utf8ChunkOffset]
      hasher.combine(bytes: UnsafeRawBufferPointer(rebasing: slice))
    }

    hasher.combine(0xFF as UInt8)
  }
}

#endif
