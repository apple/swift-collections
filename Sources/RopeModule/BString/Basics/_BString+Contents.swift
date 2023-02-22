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
  var isEmpty: Bool {
    rope.summary.isZero
  }
  
  var startIndex: Index {
    Index(_utf8Offset: 0)
  }
  
  var endIndex: Index {
    Index(_utf8Offset: utf8Count)
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
    index(i, offsetBy: distance, in: CharacterMetric())
  }
  
  func unicodeScalarIndex(_ i: Index, offsetBy distance: Int) -> Index {
    index(i, offsetBy: distance, in: UnicodeScalarMetric())
  }
  
  func utf16Index(_ i: Index, offsetBy distance: Int) -> Index {
    index(i, offsetBy: distance, in: UTF16Metric())
  }
  
  func utf8Index(_ i: Index, offsetBy distance: Int) -> Index {
    let offset = i._utf8Offset + distance
    precondition(offset >= 0 && offset <= utf8Count, "Index out of bounds")
    return Index(_utf8Offset: offset)
  }
}

@available(macOS 13.3, iOS 16.4, watchOS 9.4, tvOS 16.4, *)
extension _BString {
  func characterIndex(after i: Index) -> Index {
    index(i, offsetBy: 1, in: CharacterMetric())
  }
  
  func unicodeScalarIndex(after i: Index) -> Index {
    index(i, offsetBy: 1, in: UnicodeScalarMetric())
  }
  
  func utf16Index(after i: Index) -> Index {
    index(i, offsetBy: 1, in: UTF16Metric())
  }
  
  func utf8Index(after i: Index) -> Index {
    let offset = i._utf8Offset + 1
    precondition(offset >= 0 && offset <= utf8Count, "Index out of bounds")
    return Index(_utf8Offset: offset)
  }
}

@available(macOS 13.3, iOS 16.4, watchOS 9.4, tvOS 16.4, *)
extension _BString {
  func characterIndex(before i: Index) -> Index {
    index(i, offsetBy: -1, in: CharacterMetric())
  }
  
  func unicodeScalarIndex(before i: Index) -> Index {
    index(i, offsetBy: -1, in: UnicodeScalarMetric())
  }
  
  func utf16Index(before i: Index) -> Index {
    index(i, offsetBy: -1, in: UTF16Metric())
  }
  
  func utf8Index(before i: Index) -> Index {
    let offset = i._utf8Offset - 1
    precondition(offset >= 0 && offset <= utf8Count, "Index out of bounds")
    return Index(_utf8Offset: offset)
  }
}

@available(macOS 13.3, iOS 16.4, watchOS 9.4, tvOS 16.4, *)
extension _BString {
  func characterIndex(roundingDown i: Index) -> Index {
    let offset = i._utf8Offset
    precondition(offset >= 0 && offset <= utf8Count, "Index out of bounds")
    guard offset > 0 else { return resolve(i, preferEnd: false) }
    guard offset < utf8Count else { return resolve(i, preferEnd: true) }

    let i = resolve(i, preferEnd: true)
    var ri = i._rope!
    let ci = i._chunkIndex
    var chunk = rope[ri]
    if chunk.hasBreaks {
      let first = chunk.firstBreak
      let last = chunk.lastBreak
      if ci == first || ci == last { return i }
      if ci > last {
        return Index(baseUTF8Offset: i._utf8BaseOffset, rope: ri, chunk: last)
      }
      if ci > first {
        let j = chunk.wholeCharacters._index(roundingDown: ci)
        return Index(baseUTF8Offset: i._utf8BaseOffset, rope: ri, chunk: j)
      }
    }

    var baseOffset = i._utf8BaseOffset
    while ri > self.rope.startIndex {
      self.rope.formIndex(before: &ri)
      chunk = self.rope[ri]
      baseOffset -= chunk.utf8Count
      if chunk.hasBreaks { break }
    }
    return Index(baseUTF8Offset: baseOffset, rope: ri, chunk: chunk.lastBreak)
  }

  func unicodeScalarIndex(roundingDown i: Index) -> Index {
    precondition(i <= endIndex, "Index out of bounds")
    guard i > startIndex else { return resolve(i, preferEnd: false) }
    guard i < endIndex else { return endIndex }

    let start = self.resolve(i, preferEnd: false)
    let ri = start._rope!
    let chunk = self.rope[ri]
    let ci = chunk.string.unicodeScalars._index(roundingDown: start._chunkIndex)
    return Index(baseUTF8Offset: start._utf8BaseOffset, rope: ri, chunk: ci)
  }

  func utf8Index(roundingDown i: Index) -> Index {
    precondition(i <= endIndex, "Index out of bounds")
    var r = i
    r._clearUTF16TrailingSurrogate()
    return r
  }

  func utf16Index(roundingDown i: Index) -> Index {
    if i._isUTF16TrailingSurrogate {
      precondition(i <= endIndex, "Index out of bounds")
      return i
    }
    return unicodeScalarIndex(roundingDown: i)
  }
}

@available(macOS 13.3, iOS 16.4, watchOS 9.4, tvOS 16.4, *)
extension _BString {
  func _character(at start: Index) -> (character: Character, end: Index) {
    precondition(start._utf8Offset < utf8Count, "Index out of bounds")
    let start = resolve(start, preferEnd: false)
    var ri = start._rope!
    var ci = start._chunkIndex
    var chunk = rope[ri]
    let char = chunk.string[ci]
    let endOffset = start._utf8ChunkOffset + char.utf8.count
    if endOffset < chunk.utf8Count {
      let endIndex = chunk.string._utf8Index(at: endOffset)
      return (char, Index(baseUTF8Offset: start._utf8BaseOffset, rope: ri, chunk: endIndex))
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
    return (Character(s), Index(baseUTF8Offset: base, rope: ri, chunk: ci))
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

#endif
