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
extension _BString: Sequence {
  public typealias Element = Character

  @available(*, deprecated, renamed: "Iterator")
  internal typealias CharacterIterator = Iterator

  public func makeIterator() -> Iterator {
    Iterator(self)
  }

  internal func makeCharacterIterator() -> Iterator {
    Iterator(self)
  }

  internal func makeCharacterIterator(from index: Index) -> Iterator {
    Iterator(self, from: index)
  }
}

@available(macOS 13.3, iOS 16.4, watchOS 9.4, tvOS 16.4, *)
extension _BString {
  public struct Iterator {
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
      self._utf8BaseOffset = start.utf8Offset

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
}

@available(macOS 13.3, iOS 16.4, watchOS 9.4, tvOS 16.4, *)
extension _BString.Iterator: IteratorProtocol {
  public typealias Element = Character

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

  public mutating func next() -> Character? {
    guard !isAtEnd else { return nil }
    let item = self.current
    if !stepForward() {
      _chunkIndex = _next
    }
    return item
  }
}

@available(macOS 13.3, iOS 16.4, watchOS 9.4, tvOS 16.4, *)
extension _BString.Iterator {
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
    self.utf8Offset > index.utf8Offset
  }

  func isBelow(_ index: _BString.Index) -> Bool {
    self.utf8Offset < index.utf8Offset
  }
}


#endif
