//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Collections open source project
//
// Copyright (c) 2023 - 2024 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
//
//===----------------------------------------------------------------------===//

#if compiler(>=6.2)

@available(SwiftStdlib 6.2, *)
extension BigString: Sequence {
  public typealias Element = Character

  public func makeIterator() -> Iterator {
    Iterator(self)
  }
}

@available(SwiftStdlib 6.2, *)
extension BigString {
  public struct Iterator {
    internal let _base: BigString
    internal var _utf8BaseOffset: Int
    internal var _ropeIndex: _Rope.Index
    internal var _chunkIndex: _Chunk.Index
    internal var _next: _Chunk.Index

    internal init(_ string: BigString) {
      self._base = string
      self._ropeIndex = string._rope.startIndex
      string._rope.grease(&_ropeIndex)

      self._utf8BaseOffset = 0
      guard _ropeIndex < string._rope.endIndex else {
        _chunkIndex = _Chunk.Index(utf8Offset: 0)
        _next = _Chunk.Index(utf8Offset: 0)
        return
      }
      let chunk = _base._rope[_ropeIndex]
      assert(chunk.firstBreak == chunk.startIndex)
      self._chunkIndex = chunk.firstBreak
      self._next = chunk.characterIndex(after: _chunkIndex, in: _chunkIndex..<chunk.endIndex)
    }

    internal init(
      _ string: BigString,
      from start: Index
    ) {
      self._base = string
      self._utf8BaseOffset = start.utf8Offset

      if start == string.endIndex {
        self._ropeIndex = string._rope.endIndex
        self._chunkIndex = _Chunk.Index(utf8Offset: 0)
        self._next = _Chunk.Index(utf8Offset: 0)
        return
      }
      let i = string.resolve(start, preferEnd: false)
      self._ropeIndex = i._rope!
      self._utf8BaseOffset = i._utf8BaseOffset
      self._chunkIndex = i._chunkIndex
      self._next = _base._rope[_ropeIndex].characterIndex(after: _chunkIndex)
    }
  }
}

@available(SwiftStdlib 6.2, *)
extension BigString.Iterator: IteratorProtocol {
  public typealias Element = Character

  internal var isAtEnd: Bool {
    _chunkIndex == _next
  }

  internal var isAtStart: Bool {
    _ropeIndex == _base._rope.startIndex && _chunkIndex.utf8Offset == 0
  }

  internal var current: Element {
    assert(!isAtEnd)
    let chunk = _base._rope[_ropeIndex]
    var str = String(copying: chunk.utf8Span(from: _chunkIndex, to: _next))
    if _next < chunk.endIndex { return Character(str) }

    var i = _base._rope.index(after: _ropeIndex)
    while i < _base._rope.endIndex {
      let chunk = _base._rope[i]
      str.append(copying: chunk.prefix)
      if chunk.firstBreak < chunk.endIndex { break }
      _base._rope.formIndex(after: &i)
    }
    return Character(str)
  }

  mutating func stepForward() -> Bool {
    guard !isAtEnd else { return false }
    let chunk = _base._rope[_ropeIndex]
    if _next < chunk.endIndex {
      _chunkIndex = _next
      _next = chunk.characterIndex(after: _next)
      return true
    }
    var baseOffset = _utf8BaseOffset + chunk.utf8Count
    var i = _base._rope.index(after: _ropeIndex)
    while i < _base._rope.endIndex {
      let chunk = _base._rope[i]
      let b = chunk.firstBreak
      if b < chunk.endIndex {
        _ropeIndex = i
        _utf8BaseOffset = baseOffset
        _chunkIndex = b
        _next = chunk.characterIndex(after: b, in: b..<chunk.endIndex)
        return true
      }
      baseOffset += chunk.utf8Count
      _base._rope.formIndex(after: &i)
    }
    return false
  }

  mutating func stepBackward() -> Bool {
    if !isAtEnd {
      let chunk = _base._rope[_ropeIndex]
      let i = chunk.firstBreak
      if _chunkIndex > chunk.firstBreak {
        _next = _chunkIndex
        _chunkIndex = chunk.characterIndex(before: _chunkIndex, in: i..<chunk.endIndex)
        return true
      }
    }
    var i = _ropeIndex
    var baseOffset = _utf8BaseOffset
    while i > _base._rope.startIndex {
      _base._rope.formIndex(before: &i)
      let chunk = _base._rope[i]
      baseOffset -= chunk.utf8Count
      if chunk.hasBreaks {
        _ropeIndex = i
        _utf8BaseOffset = baseOffset
        _next = chunk.endIndex
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

@available(SwiftStdlib 6.2, *)
extension BigString.Iterator {
  // The UTF-8 offset of the current position, from the start of the string.
  var utf8Offset: Int {
    _utf8BaseOffset + _chunkIndex.utf8Offset
  }

  var index: BigString.Index {
    BigString.Index(
      baseUTF8Offset: _utf8BaseOffset,
      _rope: _ropeIndex,
      chunk: _chunkIndex
    )
  }

  internal var nextIndex: BigString.Index {
    assert(!isAtEnd)
    let chunk = _base._rope[_ropeIndex]
    if _next < chunk.endIndex {
      return BigString.Index(
        baseUTF8Offset: _utf8BaseOffset,
        _rope: _ropeIndex,
        chunk: _next
      )
    }
    var i = _base._rope.index(after: _ropeIndex)
    var base = _utf8BaseOffset
    while i < _base._rope.endIndex {
      let chunk = _base._rope[i]
      let b = chunk.firstBreak
      if b < chunk.endIndex {
        return BigString.Index(baseUTF8Offset: base, _rope: i, chunk: b)
      }
      base += chunk.utf8Count
      _base._rope.formIndex(after: &i)
    }
    return _base.endIndex
  }

  /// The UTF-8 offset range of the current character, measured from the start of the string.
  var utf8Range: Range<Int> {
    assert(!isAtEnd)
    let start = utf8Offset
    var end = _utf8BaseOffset
    var chunk = _base._rope[_ropeIndex]
    if _next < chunk.endIndex {
      end += _next.utf8Offset
      return Range(uncheckedBounds: (start, end))
    }
    end += chunk.utf8Count
    var i = _base._rope.index(after: _ropeIndex)
    while i < _base._rope.endIndex {
      chunk = _base._rope[i]
      let b = chunk.firstBreak
      if b < chunk.endIndex {
        end += b.utf8Offset
        break
      }
      end += chunk.utf8Count
      _base._rope.formIndex(after: &i)
    }
    return Range(uncheckedBounds: (start, end))
  }

  func isAbove(_ index: BigString.Index) -> Bool {
    self.utf8Offset > index.utf8Offset
  }

  func isBelow(_ index: BigString.Index) -> Bool {
    self.utf8Offset < index.utf8Offset
  }
}

#endif // compiler(>=6.2)
