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
  /// The estimated maximum number of UTF-8 code units that `_BString` is guaranteed to be able
  /// to hold without encountering an overflow in its operations. This corresponds to the capacity
  /// of the deepest tree where every node is the minimum possible size.
  static var minimumCapacity: Int {
    let c = Rope.minimumCapacity
    let (r, overflow) = Chunk.minUTF8Count.multipliedReportingOverflow(by: c)
    guard !overflow else { return Int.max }
    return r
  }

  /// The maximum number of UTF-8 code units that `_BString` may be able to store in the best
  /// possible case, when every node in the underlying tree is fully filled with data.
  static var maximumCapacity: Int {
    let c = Rope.maximumCapacity
    let (r, overflow) = Chunk.maxUTF8Count.multipliedReportingOverflow(by: c)
    guard !overflow else { return Int.max }
    return r
  }
}

@available(macOS 13.3, iOS 16.4, watchOS 9.4, tvOS 16.4, *)
extension _BString {
  var characterCount: Int { rope.summary.characters }
  var unicodeScalarCount: Int { rope.summary.unicodeScalars }
  var utf16Count: Int { rope.summary.utf16 }
  var utf8Count: Int { rope.summary.utf8 }
}

@available(macOS 13.3, iOS 16.4, watchOS 9.4, tvOS 16.4, *)
extension _BString {
  func distance(
    from start: Index,
    to end: Index,
    in metric: some _StringMetric
  ) -> Int {
    precondition(start <= endIndex && end <= endIndex, "Invalid index")
    guard start != end else { return 0 }
    assert(!isEmpty)
    let a = resolve(Swift.min(start, end), preferEnd: false)
    let b = resolve(Swift.max(start, end), preferEnd: true)
    var d = 0

    let ropeIndexA = a._rope!
    let ropeIndexB = b._rope!
    let chunkIndexA = a._chunkIndex
    let chunkIndexB = b._chunkIndex

    if ropeIndexA == ropeIndexB {
      d = metric.distance(from: chunkIndexA, to: chunkIndexB, in: rope[ropeIndexA])
    } else {
      let chunkA = rope[ropeIndexA]
      let chunkB = rope[ropeIndexB]
      d += rope.distance(from: ropeIndexA, to: ropeIndexB, in: metric)
      d -= metric.distance(from: chunkA.string.startIndex, to: chunkIndexA, in: chunkA)
      d += metric.distance(from: chunkB.string.startIndex, to: chunkIndexB, in: chunkB)
    }
    return start <= end ? d : -d
  }
  
  func characterDistance(from start: Index, to end: Index) -> Int {
    distance(from: start, to: end, in: CharacterMetric())
  }
  
  func unicodeScalarDistance(from start: Index, to end: Index) -> Int {
    distance(from: start, to: end, in: UnicodeScalarMetric())
  }
  
  func utf16Distance(from start: Index, to end: Index) -> Int {
    distance(from: start, to: end, in: UTF16Metric())
  }
  
  func utf8Distance(from start: Index, to end: Index) -> Int {
    end._utf8Offset - start._utf8Offset
  }
}

@available(macOS 13.3, iOS 16.4, watchOS 9.4, tvOS 16.4, *)
extension _BString {
  // FIXME: See if we need direct implementations for these.

  func characterOffset(of index: Index) -> Int {
    characterDistance(from: startIndex, to: index)
  }
  
  func unicodeScalarOffset(of index: Index) -> Int {
    unicodeScalarDistance(from: startIndex, to: index)
  }
  
  func utf16Offset(of index: Index) -> Int {
    utf16Distance(from: startIndex, to: index)
  }

  func utf8Offset(of index: Index) -> Int {
    utf8Distance(from: startIndex, to: index)
  }
}

@available(macOS 13.3, iOS 16.4, watchOS 9.4, tvOS 16.4, *)
extension _BString {
  // FIXME: See if we need direct implementations for these.

  func characterIndex(at offset: Int) -> Index {
    characterIndex(startIndex, offsetBy: offset)
  }

  func unicodeScalarIndex(at offset: Int) -> Index {
    unicodeScalarIndex(startIndex, offsetBy: offset)
  }

  func utf16Index(at offset: Int) -> Index {
    utf16Index(startIndex, offsetBy: offset)
  }

  func utf8Index(at offset: Int) -> Index {
    utf8Index(startIndex, offsetBy: offset)
  }
}

@available(macOS 13.3, iOS 16.4, watchOS 9.4, tvOS 16.4, *)
extension _BString {
  func index(
    _ i: Index,
    offsetBy distance: Int,
    in metric: some _StringMetric
  ) -> Index {
    precondition(i <= endIndex, "Index out of bounds")
    if isEmpty {
      precondition(distance == 0, "Index out of bounds")
      return startIndex
    }
    if i == endIndex, distance == 0 { return i }
    let i = resolve(i, preferEnd: i == endIndex || distance < 0)
    var ri = i._rope!
    var ci = i._chunkIndex
    var d = distance
    var chunk = rope[ri]
    let r = metric.formIndex(&ci, offsetBy: &d, in: chunk)
    if r.found {
      return Index(baseUTF8Offset: i._utf8BaseOffset, rope: ri, chunk: ci)
    }

    if r.forward {
      assert(distance >= 0)
      assert(ci == chunk.string.endIndex)
      d += metric.nonnegativeSize(of: chunk.summary)
      let start = ri
      rope.formIndex(&ri, offsetBy: &d, in: metric, preferEnd: false)
      if ri == rope.endIndex {
        return endIndex
      }
      chunk = rope[ri]
      ci = metric.index(at: d, in: chunk)
      let base = i._utf8BaseOffset + rope.distance(from: start, to: ri, in: UTF8Metric())
      return Index(baseUTF8Offset: base, rope: ri, chunk: ci)
    }

    assert(distance <= 0)
    assert(ci == chunk.string.startIndex)
    let start = ri
    rope.formIndex(&ri, offsetBy: &d, in: metric, preferEnd: false)
    chunk = rope[ri]
    ci = metric.index(at: d, in: chunk)
    let base = i._utf8BaseOffset + rope.distance(from: start, to: ri, in: UTF8Metric())
    return Index(baseUTF8Offset: base, rope: ri, chunk: ci)
  }
  
  func characterIndex(_ i: Index, offsetBy distance: Int) -> Index {
    index(i, offsetBy: distance, in: CharacterMetric())._knownCharacterAligned()
  }
  
  func unicodeScalarIndex(_ i: Index, offsetBy distance: Int) -> Index {
    index(i, offsetBy: distance, in: UnicodeScalarMetric())._knownScalarAligned()
  }
  
  func utf16Index(_ i: Index, offsetBy distance: Int) -> Index {
    index(i, offsetBy: distance, in: UTF16Metric())
  }
  
  func utf8Index(_ i: Index, offsetBy distance: Int) -> Index {
    index(i, offsetBy: distance, in: UTF8Metric())
  }
}

@available(macOS 13.3, iOS 16.4, watchOS 9.4, tvOS 16.4, *)
extension _BString {
  func index(
    _ i: Index,
    offsetBy distance: Int,
    limitedBy limit: Index,
    in metric: some _StringMetric
  ) -> Index? {
    // FIXME: Do we need a direct implementation?
    if distance >= 0 {
      if limit >= i {
        let d = self.distance(from: i, to: limit, in: metric)
        if d < distance { return nil }
      }
    } else {
      if limit <= i {
        let d = self.distance(from: i, to: limit, in: metric)
        if d > distance { return nil }
      }
    }
    return self.index(i, offsetBy: distance, in: metric)
  }

  func characterIndex(_ i: Index, offsetBy distance: Int, limitedBy limit: Index) -> Index? {
    guard let j = index(i, offsetBy: distance, limitedBy: limit, in: CharacterMetric()) else {
      return nil
    }
    return j._knownCharacterAligned()
  }

  func unicodeScalarIndex(_ i: Index, offsetBy distance: Int, limitedBy limit: Index) -> Index? {
    guard let j = index(i, offsetBy: distance, limitedBy: limit, in: UnicodeScalarMetric()) else {
      return nil
    }
    return j._knownScalarAligned()
  }

  func utf16Index(_ i: Index, offsetBy distance: Int, limitedBy limit: Index) -> Index? {
    index(i, offsetBy: distance, limitedBy: limit, in: UTF16Metric())
  }

  func utf8Index(_ i: Index, offsetBy distance: Int, limitedBy limit: Index) -> Index? {
    index(i, offsetBy: distance, limitedBy: limit, in: UTF8Metric())
  }
}

@available(macOS 13.3, iOS 16.4, watchOS 9.4, tvOS 16.4, *)
extension _BString {
  func characterIndex(after i: Index) -> Index {
    index(i, offsetBy: 1, in: CharacterMetric())._knownCharacterAligned()
  }
  
  func unicodeScalarIndex(after i: Index) -> Index {
    index(i, offsetBy: 1, in: UnicodeScalarMetric())._knownScalarAligned()
  }
  
  func utf16Index(after i: Index) -> Index {
    index(i, offsetBy: 1, in: UTF16Metric())
  }
  
  func utf8Index(after i: Index) -> Index {
    precondition(i < endIndex, "Can't advance above end index")
    let i = resolve(i, preferEnd: false)
    let ri = i._rope!
    var ci = i._chunkIndex
    let chunk = rope[ri]
    chunk.string.utf8.formIndex(after: &ci)
    if ci == chunk.string.endIndex {
      return Index(
        baseUTF8Offset: i._utf8BaseOffset + chunk.utf8Count,
        rope: rope.index(after: ri),
        chunk: String.Index(_utf8Offset: 0))
    }
    return Index(_utf8Offset: i._utf8Offset + 1, rope: ri, chunkOffset: ci._utf8Offset)
  }
}

@available(macOS 13.3, iOS 16.4, watchOS 9.4, tvOS 16.4, *)
extension _BString {
  func characterIndex(before i: Index) -> Index {
    index(i, offsetBy: -1, in: CharacterMetric())._knownCharacterAligned()
  }
  
  func unicodeScalarIndex(before i: Index) -> Index {
    index(i, offsetBy: -1, in: UnicodeScalarMetric())._knownScalarAligned()
  }
  
  func utf16Index(before i: Index) -> Index {
    index(i, offsetBy: -1, in: UTF16Metric())
  }
  
  func utf8Index(before i: Index) -> Index {
    precondition(i > startIndex, "Can't advance below start index")
    let i = resolve(i, preferEnd: true)
    var ri = i._rope!
    let ci = i._chunkIndex
    if ci._utf8Offset > 0 {
      return Index(
        _utf8Offset: i._utf8Offset &- 1,
        rope: ri,
        chunkOffset: ci._utf8Offset &- 1)
    }
    rope.formIndex(before: &ri)
    let chunk = rope[ri]
    return Index(
      baseUTF8Offset: i._utf8BaseOffset - chunk.utf8Count,
      rope: ri,
      chunk: String.Index(_utf8Offset: chunk.utf8Count - 1))
  }
}

@available(macOS 13.3, iOS 16.4, watchOS 9.4, tvOS 16.4, *)
extension _BString {
  func characterIndex(roundingDown i: Index) -> Index {
    let offset = i._utf8Offset
    precondition(offset >= 0 && offset <= utf8Count, "Index out of bounds")
    guard offset > 0 else { return resolve(i, preferEnd: false)._knownCharacterAligned() }
    guard offset < utf8Count else { return resolve(i, preferEnd: true)._knownCharacterAligned() }

    let i = resolve(i, preferEnd: false)
    guard !i._isKnownCharacterAligned else { return resolve(i, preferEnd: false) }

    var ri = i._rope!
    let ci = i._chunkIndex
    var chunk = rope[ri]
    if chunk.hasBreaks {
      let first = chunk.firstBreak
      let last = chunk.lastBreak
      if ci == first || ci == last { return i }
      if ci > last {
        return Index(
          baseUTF8Offset: i._utf8BaseOffset, rope: ri, chunk: last
        )._knownCharacterAligned()
      }
      if ci > first {
        let j = chunk.wholeCharacters._index(roundingDown: ci)
        return Index(baseUTF8Offset: i._utf8BaseOffset, rope: ri, chunk: j)._knownCharacterAligned()
      }
    }

    var baseOffset = i._utf8BaseOffset
    while ri > self.rope.startIndex {
      self.rope.formIndex(before: &ri)
      chunk = self.rope[ri]
      baseOffset -= chunk.utf8Count
      if chunk.hasBreaks { break }
    }
    return Index(
      baseUTF8Offset: baseOffset, rope: ri, chunk: chunk.lastBreak
    )._knownCharacterAligned()
  }

  func unicodeScalarIndex(roundingDown i: Index) -> Index {
    precondition(i <= endIndex, "Index out of bounds")
    guard i > startIndex else { return resolve(i, preferEnd: false)._knownCharacterAligned() }
    guard i < endIndex else { return resolve(i, preferEnd: true)._knownCharacterAligned() }

    let start = self.resolve(i, preferEnd: false)
    guard !i._isKnownScalarAligned else { return resolve(i, preferEnd: false) }
    let ri = start._rope!
    let chunk = self.rope[ri]
    let ci = chunk.string.unicodeScalars._index(roundingDown: start._chunkIndex)
    return Index(baseUTF8Offset: start._utf8BaseOffset, rope: ri, chunk: ci)._knownScalarAligned()
  }

  func utf8Index(roundingDown i: Index) -> Index {
    precondition(i <= endIndex, "Index out of bounds")
    guard i < endIndex else { return endIndex }
    var r = i
    if i._isUTF16TrailingSurrogate {
      r._clearUTF16TrailingSurrogate()
    }
    return resolve(r, preferEnd: false)
  }

  func utf16Index(roundingDown i: Index) -> Index {
    if i._isUTF16TrailingSurrogate {
      precondition(i < endIndex, "Index out of bounds")
      // (We know i can't be the endIndex -- it addresses a trailing surrogate.)
      return self.resolve(i, preferEnd: false)
    }
    return unicodeScalarIndex(roundingDown: i)
  }
}

@available(macOS 13.3, iOS 16.4, watchOS 9.4, tvOS 16.4, *)
extension _BString {
  func characterIndex(roundingUp i: Index) -> Index {
    let j = characterIndex(roundingDown: i)
    if i == j { return j }
    return characterIndex(after: j)
  }

  func unicodeScalarIndex(roundingUp i: Index) -> Index {
    let j = unicodeScalarIndex(roundingDown: i)
    if i == j { return j }
    return unicodeScalarIndex(after: j)
  }

  func utf8Index(roundingUp i: Index) -> Index {
    // Note: this orders UTF-16 trailing surrogate indices in between the first and second byte
    // of the UTF-8 encoding.
    let j = utf8Index(roundingDown: i)
    if i == j { return j }
    return utf8Index(after: j)
  }

  func utf16Index(roundingUp i: Index) -> Index {
    // Note: if `i` addresses some byte in the middle of a non-BMP scalar then the result will
    // point to the trailing surrogate.
    let j = utf16Index(roundingDown: i)
    if i == j { return j }
    return utf16Index(after: j)
  }
}

@available(macOS 13.3, iOS 16.4, watchOS 9.4, tvOS 16.4, *)
extension _BString {
  func _character(at start: Index) -> (character: Character, end: Index) {
    let start = characterIndex(roundingDown: start)
    precondition(start._utf8Offset < utf8Count, "Index out of bounds")

    var ri = start._rope!
    var ci = start._chunkIndex
    var chunk = rope[ri]
    let char = chunk.wholeCharacters[ci]
    let endOffset = start._utf8ChunkOffset + char.utf8.count
    if endOffset < chunk.utf8Count {
      let endStringIndex = chunk.string._utf8Index(at: endOffset)
      let endIndex = Index(
        baseUTF8Offset: start._utf8BaseOffset, rope: ri, chunk: endStringIndex
      )._knownCharacterAligned()
      return (char, endIndex)
    }
    var s = String(char)
    var base = start._utf8BaseOffset + chunk.utf8Count
    while true {
      rope.formIndex(after: &ri)
      guard ri < rope.endIndex else {
        ci = "".endIndex
        break
      }
      chunk = rope[ri]
      s.append(contentsOf: chunk.prefix)
      if chunk.hasBreaks {
        ci = chunk.firstBreak
        break
      }
      base += chunk.utf8Count
    }
    return (Character(s), Index(baseUTF8Offset: base, rope: ri, chunk: ci)._knownCharacterAligned())
  }

  subscript(utf8 index: Index) -> UInt8 {
    precondition(index < endIndex, "Index out of bounds")
    let index = resolve(index, preferEnd: false)
    return rope[index._rope!].string.utf8[index._chunkIndex]
  }

  subscript(utf8 offset: Int) -> UInt8 {
    precondition(offset >= 0 && offset < utf8Count, "Offset out of bounds")
    let index = utf8Index(at: offset)
    return self[utf8: index]
  }

  subscript(utf16 index: Index) -> UInt16 {
    precondition(index < endIndex, "Index out of bounds")
    let index = resolve(index, preferEnd: false)
    return rope[index._rope!].string.utf16[index._chunkIndex]
  }

  subscript(utf16 offset: Int) -> UInt16 {
    precondition(offset >= 0 && offset < utf16Count, "Offset out of bounds")
    let index = utf16Index(at: offset)
    return self[utf16: index]
  }

  subscript(character index: Index) -> Character {
    _character(at: index).character
  }

  subscript(character offset: Int) -> Character {
    precondition(offset >= 0 && offset < utf8Count, "Offset out of bounds")
    return _character(at: Index(_utf8Offset: offset)).character
  }

  subscript(unicodeScalar index: Index) -> Unicode.Scalar {
    precondition(index < endIndex, "Index out of bounds")
    let index = resolve(index, preferEnd: false)
    return rope[index._rope!].string.unicodeScalars[index._chunkIndex]
  }

  subscript(unicodeScalar offset: Int) -> Unicode.Scalar {
    precondition(offset >= 0 && offset < unicodeScalarCount, "Offset out of bounds")
    let index = unicodeScalarIndex(at: offset)
    return self[unicodeScalar: index]
  }
}

@available(macOS 13.3, iOS 16.4, watchOS 9.4, tvOS 16.4, *)
extension _BString {
  func _foreachChunk(
    from start: Index,
    to end: Index,
    _ body: (Substring) -> Void
  ) {
    precondition(start <= end)
    guard start < end else { return }
    let start = resolve(start, preferEnd: false)
    let end = resolve(end, preferEnd: true)

    var ri = start._rope!
    let endRopeIndex = end._rope!

    if ri == endRopeIndex {
      let str = self.rope[ri].string
      body(str[start._chunkIndex ..< end._chunkIndex])
      return
    }

    let firstChunk = self.rope[ri].string
    body(firstChunk[start._chunkIndex...])

    rope.formIndex(after: &ri)
    while ri < endRopeIndex {
      let string = rope[ri].string
      body(string[...])
    }

    let lastChunk = self.rope[ri].string
    body(lastChunk[..<end._chunkIndex])
  }
}

#endif
