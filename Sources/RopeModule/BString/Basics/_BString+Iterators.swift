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

extension _BString.ChunkIterator: IteratorProtocol {
  typealias Element = String

  mutating func next() -> String? {
    base.next()?.string
  }
}

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

extension _BString {
  internal struct CharacterIterator {
    internal var _base: _Rope<Chunk>.Iterator
    internal var _index: String.Index
    internal var _next: String.Index

    internal init(_base: _Rope<Chunk>.Iterator) {
      self._base = _base
      guard !_base.isAtEnd else {
        _index = "".startIndex
        _next = "".endIndex
        return
      }
      let chunk = _base.current
      assert(chunk.firstBreak == chunk.string.startIndex)
      self._index = chunk.firstBreak
      self._next = chunk.string[_index...].index(after: _index)
    }

    internal init(_base: _Rope<Chunk>.Iterator, _ i: String.Index) {
      self._base = _base
      self._index = i
      assert(i >= _base.current.firstBreak)
      guard !_base.isAtEnd, i < _base.current.string.endIndex else {
        self._next = i
        return
      }
      self._next = _base.current.wholeCharacters.index(after: i)
    }
  }

  internal func makeCharacterIterator() -> CharacterIterator {
    CharacterIterator(_base: rope.makeIterator())
  }

  internal func makeCharacterIterator(from index: Index) -> CharacterIterator {
    if index == endIndex {
      return CharacterIterator(_base: rope.makeIterator(from: rope.endIndex))
    }
    let (path, _) = self.path(to: index, preferEnd: false)
    let base = rope.makeIterator(from: path.rope)
    return CharacterIterator(_base: base, path.chunk)
  }
}

extension _BString.CharacterIterator: IteratorProtocol {
  internal typealias Element = Character

  internal var isAtEnd: Bool {
    _index == _next
  }

  internal var isAtStart: Bool {
    _base.isAtStart && _index._utf8Offset == 0
  }

  internal var current: Element {
    assert(!isAtEnd)
    var r = _base.withCurrent { chunk -> (str: String, done: Bool) in
      assert(_index >= chunk.firstBreak)
      return (String(chunk.string[_index ..< _next]), _next < chunk.string.endIndex)
    }
    guard !r.done else { return Character(r.str) }
    var it = self._base
    while it.stepForward(), !r.done {
      it.withCurrent { chunk in
        let i = chunk.firstBreak
        r.str += chunk.string[..<i]
        r.done = i < chunk.string.endIndex
      }
    }
    return Character(r.str)
  }

  mutating func stepForward() -> Bool {
    guard !isAtEnd else { return false }
    let chunk = _base.current
    if _next < chunk.string.endIndex {
      _index = _next
      _next = chunk.wholeCharacters.index(after: _next)
      return true
    }
    while _base.stepForward() {
      let chunk = _base.current
      let i = chunk.firstBreak
      if i < chunk.string.endIndex {
        _index = i
        _next = chunk.string[i...].index(after: i)
        return true
      }
    }
    return false
  }

  mutating func stepBackward() -> Bool {
    if !isAtEnd {
      let chunk = _base.current
      let i = chunk.firstBreak
      if _index > i {
        _next = _index
        _index = chunk.string[i...].index(before: _index)
        return true
      }
    }
    while _base.stepBackward() {
      let chunk = _base.current
      if chunk.hasBreaks {
        _next = chunk.string.endIndex
        _index = chunk.lastBreak
        return true
      }
    }
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

extension _BString.CharacterIterator {
  var index: _BString.Index {
    let utf8Base = _base.rope.offset(of: _base.index, in: _BString.UTF8Metric())
    return _BString.Index(_utf8Offset: utf8Base + _index._utf8Offset)
  }
}
