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
    internal var _rope: Rope.Iterator
    internal var _chunk: String.UTF8View.Iterator

    internal init(_base: Rope.Iterator) {
      self._rope = _base
      let str = self._rope.next()?.string ?? ""
      self._chunk = str.utf8.makeIterator()
    }
  }

  internal func makeUTF8Iterator() -> UTF8Iterator {
    UTF8Iterator(_base: self.rope.makeIterator())
  }
}

@available(macOS 13.3, iOS 16.4, watchOS 9.4, tvOS 16.4, *)
extension _BString.UTF8Iterator: IteratorProtocol {
  internal typealias Element = UInt8

  internal mutating func next() -> UInt8? {
    if let codeUnit = _chunk.next() {
      return codeUnit
    }
    guard let chunk = _rope.next() else { return nil }
    _chunk = chunk.string.utf8.makeIterator()
    return _chunk.next()!
  }
}

@available(macOS 13.3, iOS 16.4, watchOS 9.4, tvOS 16.4, *)
extension _BString {
  internal struct UTF16Iterator {
    internal var _rope: Rope.Iterator
    internal var _chunk: String.UTF16View.Iterator

    internal init(_base: Rope.Iterator) {
      self._rope = _base
      let str = self._rope.next()?.string ?? ""
      self._chunk = str.utf16.makeIterator()
    }
  }

  internal func makeUTF16Iterator() -> UTF16Iterator {
    UTF16Iterator(_base: self.rope.makeIterator())
  }
}

@available(macOS 13.3, iOS 16.4, watchOS 9.4, tvOS 16.4, *)
extension _BString.UTF16Iterator: IteratorProtocol {
  internal typealias Element = UInt16

  internal mutating func next() -> UInt16? {
    if let codeUnit = _chunk.next() {
      return codeUnit
    }
    guard let chunk = _rope.next() else { return nil }
    _chunk = chunk.string.utf16.makeIterator()
    return _chunk.next()!
  }
}

@available(macOS 13.3, iOS 16.4, watchOS 9.4, tvOS 16.4, *)
extension _BString {
  internal struct UnicodeScalarIterator {
    internal var _rope: Rope.Iterator
    // FIXME: Change to using String.UnicodeScalarView.Iterator once makeIterator(from:) is a thing
    internal var _chunk: String.UnicodeScalarView
    internal var _index: String.Index

    internal init(_base: Rope.Iterator, _ chunk: Chunk, _ index: String.Index) {
      self._rope = _base
      self._chunk = chunk.string.unicodeScalars
      self._index = index
    }
  }

  internal func makeUnicodeScalarIterator() -> UnicodeScalarIterator {
    makeUnicodeScalarIterator(from: startIndex)
  }

  internal func makeUnicodeScalarIterator(from index: Index) -> UnicodeScalarIterator {
    let i = resolve(index, preferEnd: index == endIndex)
    let ropeIndex = i._rope!
    let chunkIndex = i._chunkIndex
    var base = self.rope.makeIterator(from: ropeIndex)
    _ = base.next()
    return UnicodeScalarIterator(_base: base, rope[ropeIndex], chunkIndex)
  }
}

@available(macOS 13.3, iOS 16.4, watchOS 9.4, tvOS 16.4, *)
extension _BString.UnicodeScalarIterator: IteratorProtocol {
  internal typealias Element = Unicode.Scalar

  internal mutating func next() -> Unicode.Scalar? {
    if _index == _chunk.endIndex {
      guard let chunk = _rope.next() else { return nil }
      _chunk = chunk.string.unicodeScalars
      _index = _chunk.startIndex
      assert(_index < _chunk.endIndex)
    }
    let scalar = _chunk[_index]
    _index = _chunk.index(after: _index)
    return scalar
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
    assert(_base.rope.isEmpty)
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
    _BString.Index(_utf8Offset: utf8Offset)
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

  func isBelow(_ index: _BString.Index) -> Bool {
    assert(index._rope != nil)
    let ropeIndex = index._rope!
    let chunkIndex = index._chunkIndex
    if _ropeIndex < ropeIndex { return true }
    guard _ropeIndex == ropeIndex else { return false }
    return self._chunkIndex < chunkIndex
  }
}

#endif
