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
    internal var _chunk: String.UnicodeScalarView.Iterator

    internal init(_base: Rope.Iterator) {
      self._rope = _base
      let str = self._rope.next()?.string ?? ""
      self._chunk = str.unicodeScalars.makeIterator()
    }
  }

  internal func makeUnicodeScalarIterator() -> UnicodeScalarIterator {
    UnicodeScalarIterator(_base: self.rope.makeIterator())
  }
}

extension _BString.UnicodeScalarIterator: IteratorProtocol {
  internal typealias Element = Unicode.Scalar

  internal mutating func next() -> Unicode.Scalar? {
    if let scalar = _chunk.next() {
      return scalar
    }
    guard let chunk = _rope.next() else { return nil }
    _chunk = chunk.string.unicodeScalars.makeIterator()
    return _chunk.next()!
  }
}

extension _BString {
  internal struct CharacterIterator {
    internal var _base: _Rope<Chunk>.Iterator
    internal var _str: Substring

    internal init(_base: _Rope<Chunk>.Iterator) {
      self._base = _base
      if let chunk = self._base.next() {
        assert(chunk.firstBreak == chunk.string.startIndex)
        self._str = chunk.wholeCharacters
      } else {
        self._str = ""
      }
    }
  }

  internal func makeCharacterIterator() -> CharacterIterator {
    CharacterIterator(_base: rope.makeIterator())
  }
}

extension _BString.CharacterIterator: IteratorProtocol {
  internal typealias Element = Character

  internal mutating func next() -> Character? {
    guard !_str.isEmpty else { return nil }

    let j = _str.index(after: _str.startIndex)
    var result = String(_str[..<j])
    if j < _str.endIndex {
      _str = _str[j...]
      return Character(result)
    }
    while let next = _base.next() {
      let firstBreak = next.firstBreak
      result.append(contentsOf: next.string[..<firstBreak])
      if firstBreak < next.string.endIndex {
        _str = next.string[firstBreak...]
        return Character(result)
      }
    }
    _str = ""
    return Character(result)
  }
}
