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
    let (path, chunk) = self.path(to: index, preferEnd: false)
    var base = self.rope.makeIterator(from: path.rope)
    _ = base.next()
    return UnicodeScalarIterator(_base: base, chunk, path.chunk)
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
    internal var _i: Rope.Index

    internal var _utf8BaseOffset: Int
    internal var _index: String.Index
    internal var _next: String.Index

    internal init(_ string: _BString) {
      self._base = string
      self._i = string.rope.startIndex
      self._utf8BaseOffset = 0
      guard _i < string.rope.endIndex else {
        _index = "".startIndex
        _next = "".endIndex
        return
      }
      let chunk = _base.rope[_i]
      assert(chunk.firstBreak == chunk.string.startIndex)
      self._index = chunk.firstBreak
      self._next = chunk.string[_index...].index(after: _index)
    }

    internal init(
      _ string: _BString,
      from start: Index
    ) {
      self._base = string
      self._utf8BaseOffset = start._utf8Offset

      if start == string.endIndex {
        self._i = string.rope.endIndex
        self._index = "".startIndex
        self._next = "".endIndex
        return
      }
      let path = string.path(to: start, preferEnd: false).path
      self._i = path.rope
      self._utf8BaseOffset -= path.chunk._utf8Offset
      self._index = path.chunk
      self._next = _base.rope[_i].wholeCharacters.index(after: path.chunk)
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
    _index == _next
  }

  internal var isAtStart: Bool {
    _i == _base.rope.startIndex && _index._utf8Offset == 0
  }

  internal var current: Element {
    assert(!isAtEnd)
    let chunk = _base.rope[_i]
    var str = String(chunk.string[_index ..< _next])
    if _next < chunk.string.endIndex { return Character(str) }

    var i = _base.rope.index(after: _i)
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
    let chunk = _base.rope[_i]
    if _next < chunk.string.endIndex {
      _index = _next
      _next = chunk.wholeCharacters.index(after: _next)
      return true
    }
    var baseOffset = _utf8BaseOffset + chunk.utf8Count
    var i = _base.rope.index(after: _i)
    while i < _base.rope.endIndex {
      let chunk = _base.rope[i]
      let b = chunk.firstBreak
      if b < chunk.string.endIndex {
        _i = i
        _utf8BaseOffset = baseOffset
        _index = b
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
      let chunk = _base.rope[_i]
      let i = chunk.firstBreak
      if _index > i {
        _next = _index
        _index = chunk.string[i...].index(before: _index)
        return true
      }
    }
    var i = _i
    var baseOffset = _utf8BaseOffset
    while i > _base.rope.startIndex {
      _base.rope.formIndex(before: &i)
      let chunk = _base.rope[i]
      baseOffset -= chunk.utf8Count
      if chunk.hasBreaks {
        _i = i
        _utf8BaseOffset = baseOffset
        _next = chunk.string.endIndex
        _index = chunk.lastBreak
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
      _index = _next
    }
    return item
  }
}

@available(macOS 13.3, iOS 16.4, watchOS 9.4, tvOS 16.4, *)
extension _BString.CharacterIterator {
  // The UTF-8 offset of the current position, from the start of the string.
  var utf8Offset: Int {
    _utf8BaseOffset + _index._utf8Offset
  }

  var index: _BString.Index {
    _BString.Index(_utf8Offset: utf8Offset)
  }

  /// The UTF-8 offset range of the current character, measured from the start of the string.
  var utf8Range: Range<Int> {
    assert(!isAtEnd)
    let start = utf8Offset
    var end = _utf8BaseOffset
    var chunk = _base.rope[_i]
    if _next < chunk.string.endIndex {
      end += _next._utf8Offset
      return Range(uncheckedBounds: (start, end))
    }
    end += chunk.utf8Count
    var i = _base.rope.index(after: _i)
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

  func isBelow(_ path: _BString.Path) -> Bool {
    if _i < path.rope { return true }
    guard _i == path.rope else { return false }
    return self._index < path.chunk
  }
}

#endif
