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
  struct ChunkIterator {
    var base: Rope.Iterator

    init(base: Rope.Iterator) {
      self.base = base
    }
  }

  func makeChunkIterator() -> ChunkIterator {
    ChunkIterator(base: rope.makeIterator())
  }
}

@available(macOS 13.3, iOS 16.4, watchOS 9.4, tvOS 16.4, *)
extension _BString.ChunkIterator: IteratorProtocol {
  typealias Element = String

  mutating func next() -> String? {
    base.next()?.string
  }
}

@available(macOS 13.3, iOS 16.4, watchOS 9.4, tvOS 16.4, *)
extension _BString {
  internal struct UTF8Iterator {
    internal let _base: _BString
    internal var _index: _BString.Index
    
    internal init(_base: _BString, from start: _BString.Index) {
      self._base = _base
      self._index = _base.utf8Index(roundingDown: start)
    }
  }
  
  internal func makeUTF8Iterator() -> UTF8Iterator {
    UTF8Iterator(_base: self, from: self.startIndex)
  }

  internal func makeUTF8Iterator(from start: Index) -> UTF8Iterator {
    UTF8Iterator(_base: self, from: start)
  }
}

@available(macOS 13.3, iOS 16.4, watchOS 9.4, tvOS 16.4, *)
extension _BString.UTF8Iterator: IteratorProtocol {
  internal typealias Element = UInt8

  internal mutating func next() -> UInt8? {
    guard _index < _base.endIndex else { return nil }
    // Hand-optimized from `_base.subscript(utf8:)` and `_base.utf8Index(after:)`.
    let ri = _index._rope!
    var ci = _index._chunkIndex
    let chunk = _base.rope[ri]
    let result = chunk.string.utf8[ci]

    chunk.string.utf8.formIndex(after: &ci)
    if ci < chunk.string.endIndex {
      _index = _BString.Index(baseUTF8Offset: _index._utf8BaseOffset, rope: ri, chunk: ci)
    } else {
      _index = _BString.Index(
        baseUTF8Offset: _index._utf8BaseOffset + chunk.utf8Count,
        rope: _base.rope.index(after: ri),
        chunk: String.Index(_utf8Offset: 0))
    }
    return result
  }

  internal mutating func next<R>(
    maximumCount: Int,
    with body: (UnsafeBufferPointer<UInt8>) -> (consumed: Int, result: R)
  ) -> R {
    guard _index < _base.endIndex else {
      let r = body(UnsafeBufferPointer(start: nil, count: 0))
      precondition(r.consumed == 0)
      return r.result
    }
    let ri = _index._rope!
    var ci = _index._utf8ChunkOffset
    var utf8Offset = _index._utf8Offset
    var string = _base.rope[ri].string
    let (haveMore, result) = string.withUTF8 { buffer in
      let slice = buffer[ci...].prefix(maximumCount)
      assert(!slice.isEmpty)
      let (consumed, result) = body(UnsafeBufferPointer(rebasing: slice))
      precondition(consumed >= 0 && consumed <= slice.count)
      utf8Offset += consumed
      ci += consumed
      return (ci < buffer.count, result)
    }
    if haveMore {
      _index = _BString.Index(_utf8Offset: utf8Offset, rope: ri, chunkOffset: ci)
    } else {
      _index = _BString.Index(
        baseUTF8Offset: _index._utf8BaseOffset + string.utf8.count,
        rope: _base.rope.index(after: ri),
        chunk: String.Index(_utf8Offset: 0))
    }
    return result
  }
}

@available(macOS 13.3, iOS 16.4, watchOS 9.4, tvOS 16.4, *)
extension _BString {
  internal struct UTF16Iterator {
    internal let _base: _BString
    internal var _index: _BString.Index
    
    internal init(_base: _BString, from start: _BString.Index) {
      self._base = _base
      self._index = _base.utf16Index(roundingDown: start)
    }
  }
  
  internal func makeUTF16Iterator() -> UTF16Iterator {
    UTF16Iterator(_base: self, from: self.startIndex)
  }

  internal func makeUTF16Iterator(from start: Index) -> UTF16Iterator {
    UTF16Iterator(_base: self, from: start)
  }
}

@available(macOS 13.3, iOS 16.4, watchOS 9.4, tvOS 16.4, *)
extension _BString.UTF16Iterator: IteratorProtocol {
  internal typealias Element = UInt16

  internal mutating func next() -> UInt16? {
    guard _index < _base.endIndex else { return nil }
    let ri = _index._rope!
    var ci = _index._chunkIndex
    let chunk = _base.rope[ri]
    let result = chunk.string.utf16[ci]

    chunk.string.utf16.formIndex(after: &ci)
    if ci < chunk.string.endIndex {
      _index = _BString.Index(baseUTF8Offset: _index._utf8BaseOffset, rope: ri, chunk: ci)
    } else {
      _index = _BString.Index(
        baseUTF8Offset: _index._utf8BaseOffset + chunk.utf8Count,
        rope: _base.rope.index(after: ri),
        chunk: String.Index(_utf8Offset: 0))
    }
    return result
  }
}

@available(macOS 13.3, iOS 16.4, watchOS 9.4, tvOS 16.4, *)
extension _BString {
  internal struct UnicodeScalarIterator {
    internal let _base: _BString
    internal var _index: _BString.Index

    internal init(_base: _BString, from start: _BString.Index) {
      self._base = _base
      self._index = _base.unicodeScalarIndex(roundingDown: start)
    }
  }

  internal func makeUnicodeScalarIterator() -> UnicodeScalarIterator {
    UnicodeScalarIterator(_base: self, from: startIndex)
  }

  internal func makeUnicodeScalarIterator(from start: Index) -> UnicodeScalarIterator {
    UnicodeScalarIterator(_base: self, from: start)
  }
}

@available(macOS 13.3, iOS 16.4, watchOS 9.4, tvOS 16.4, *)
extension _BString.UnicodeScalarIterator: IteratorProtocol {
  internal typealias Element = Unicode.Scalar

  internal mutating func next() -> Unicode.Scalar? {
    guard _index < _base.endIndex else { return nil }
    let ri = _index._rope!
    var ci = _index._chunkIndex
    let chunk = _base.rope[ri]
    let result = chunk.string.unicodeScalars[ci]

    chunk.string.unicodeScalars.formIndex(after: &ci)
    if ci < chunk.string.endIndex {
      _index = _BString.Index(baseUTF8Offset: _index._utf8BaseOffset, rope: ri, chunk: ci)
    } else {
      _index = _BString.Index(
        baseUTF8Offset: _index._utf8BaseOffset + chunk.utf8Count,
        rope: _base.rope.index(after: ri),
        chunk: String.Index(_utf8Offset: 0))
    }
    return result
  }
}

@available(macOS 13.3, iOS 16.4, watchOS 9.4, tvOS 16.4, *)
extension _BString {
  internal struct CharacterIterator {
    internal let _base: _BString
    internal var _utf8BaseOffset: Int
    internal var _ropeIndex: Rope.Index
    internal var _chunkIndex: String.Index
    internal var _next: String.Index

    internal init(_ string: _BString) {
      self._base = string
      self._ropeIndex = string.rope.startIndex
      string.rope.ensureLeaf(in: &_ropeIndex)

      self._utf8BaseOffset = 0
      guard _ropeIndex < string.rope.endIndex else {
        _chunkIndex = "".startIndex
        _next = "".endIndex
        return
      }
      let chunk = _base.rope[_ropeIndex]
      assert(chunk.firstBreak == chunk.string.startIndex)
      self._chunkIndex = chunk.firstBreak
      self._next = chunk.string[_chunkIndex...].index(after: _chunkIndex)
    }

    internal init(
      _ string: _BString,
      from start: Index
    ) {
      self._base = string
      self._utf8BaseOffset = start._utf8Offset

      if start == string.endIndex {
        self._ropeIndex = string.rope.endIndex
        self._chunkIndex = "".startIndex
        self._next = "".endIndex
        return
      }
      let i = string.resolve(start, preferEnd: false)
      self._ropeIndex = i._rope!
      self._utf8BaseOffset = i._utf8BaseOffset
      self._chunkIndex = i._chunkIndex
      self._next = _base.rope[_ropeIndex].wholeCharacters.index(after: _chunkIndex)
    }
  }

  internal func makeCharacterIterator() -> CharacterIterator {
    CharacterIterator(self)
  }

  internal func makeCharacterIterator(from index: Index) -> CharacterIterator {
    CharacterIterator(self, from: index)
  }
}

@available(macOS 13.3, iOS 16.4, watchOS 9.4, tvOS 16.4, *)
extension _BString.CharacterIterator: IteratorProtocol {
  internal typealias Element = Character

  internal var isAtEnd: Bool {
    _chunkIndex == _next
  }

  internal var isAtStart: Bool {
    _ropeIndex == _base.rope.startIndex && _chunkIndex._utf8Offset == 0
  }

  internal var current: Element {
    assert(!isAtEnd)
    let chunk = _base.rope[_ropeIndex]
    var str = String(chunk.string[_chunkIndex ..< _next])
    if _next < chunk.string.endIndex { return Character(str) }

    var i = _base.rope.index(after: _ropeIndex)
    while i < _base.rope.endIndex {
      let chunk = _base.rope[i]
      let b = chunk.firstBreak
      str += chunk.string[..<b]
      if b < chunk.string.endIndex { break }
      _base.rope.formIndex(after: &i)
    }
    return Character(str)
  }

  mutating func stepForward() -> Bool {
    guard !isAtEnd else { return false }
    let chunk = _base.rope[_ropeIndex]
    if _next < chunk.string.endIndex {
      _chunkIndex = _next
      _next = chunk.wholeCharacters.index(after: _next)
      return true
    }
    var baseOffset = _utf8BaseOffset + chunk.utf8Count
    var i = _base.rope.index(after: _ropeIndex)
    while i < _base.rope.endIndex {
      let chunk = _base.rope[i]
      let b = chunk.firstBreak
      if b < chunk.string.endIndex {
        _ropeIndex = i
        _utf8BaseOffset = baseOffset
        _chunkIndex = b
        _next = chunk.string[b...].index(after: b)
        return true
      }
      baseOffset += chunk.utf8Count
      _base.rope.formIndex(after: &i)
    }
    return false
  }

  mutating func stepBackward() -> Bool {
    if !isAtEnd {
      let chunk = _base.rope[_ropeIndex]
      let i = chunk.firstBreak
      if _chunkIndex > i {
        _next = _chunkIndex
        _chunkIndex = chunk.string[i...].index(before: _chunkIndex)
        return true
      }
    }
    var i = _ropeIndex
    var baseOffset = _utf8BaseOffset
    while i > _base.rope.startIndex {
      _base.rope.formIndex(before: &i)
      let chunk = _base.rope[i]
      baseOffset -= chunk.utf8Count
      if chunk.hasBreaks {
        _ropeIndex = i
        _utf8BaseOffset = baseOffset
        _next = chunk.string.endIndex
        _chunkIndex = chunk.lastBreak
        return true
      }
    }
    return false
  }

  internal mutating func next() -> Character? {
    guard !isAtEnd else { return nil }
    let item = self.current
    if !stepForward() {
      _chunkIndex = _next
    }
    return item
  }
}

@available(macOS 13.3, iOS 16.4, watchOS 9.4, tvOS 16.4, *)
extension _BString.CharacterIterator {
  // The UTF-8 offset of the current position, from the start of the string.
  var utf8Offset: Int {
    _utf8BaseOffset + _chunkIndex._utf8Offset
  }

  var index: _BString.Index {
    _BString.Index(baseUTF8Offset: _utf8BaseOffset, rope: _ropeIndex, chunk: _chunkIndex)
  }

  internal var nextIndex: _BString.Index {
    assert(!isAtEnd)
    let chunk = _base.rope[_ropeIndex]
    if _next < chunk.string.endIndex {
      return _BString.Index(baseUTF8Offset: _utf8BaseOffset, rope: _ropeIndex, chunk: _next)
    }
    var i = _base.rope.index(after: _ropeIndex)
    var base = _utf8BaseOffset
    while i < _base.rope.endIndex {
      let chunk = _base.rope[i]
      let b = chunk.firstBreak
      if b < chunk.string.endIndex {
        return _BString.Index(baseUTF8Offset: base, rope: i, chunk: b)
      }
      base += chunk.utf8Count
      _base.rope.formIndex(after: &i)
    }
    return _base.endIndex
  }

  /// The UTF-8 offset range of the current character, measured from the start of the string.
  var utf8Range: Range<Int> {
    assert(!isAtEnd)
    let start = utf8Offset
    var end = _utf8BaseOffset
    var chunk = _base.rope[_ropeIndex]
    if _next < chunk.string.endIndex {
      end += _next._utf8Offset
      return Range(uncheckedBounds: (start, end))
    }
    end += chunk.utf8Count
    var i = _base.rope.index(after: _ropeIndex)
    while i < _base.rope.endIndex {
      chunk = _base.rope[i]
      let b = chunk.firstBreak
      if b < chunk.string.endIndex {
        end += b._utf8Offset
        break
      }
      end += chunk.utf8Count
      _base.rope.formIndex(after: &i)
    }
    return Range(uncheckedBounds: (start, end))
  }

  func isAbove(_ index: _BString.Index) -> Bool {
    self.utf8Offset > index._utf8Offset
  }

  func isBelow(_ index: _BString.Index) -> Bool {
    self.utf8Offset < index._utf8Offset
  }
}

#endif
