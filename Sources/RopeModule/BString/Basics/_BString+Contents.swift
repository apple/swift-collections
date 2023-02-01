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

extension _BString {
  var characterCount: Int { rope.summary.characters }
  var unicodeScalarCount: Int { rope.summary.unicodeScalars }
  var utf16Count: Int { rope.summary.utf16 }
  var utf8Count: Int { rope.summary.utf8 }
}

extension _BString {
  func distance(
    from start: Index,
    to end: Index,
    in metric: some _StringMetric
  ) -> Int {
    guard !isEmpty else {
      precondition(start == end && start == endIndex, "Invalid index")
      return 0
    }
    let a = path(to: Swift.min(start, end), preferEnd: false)
    let b = path(to: Swift.max(start, end), preferEnd: true)
    if a.path.rope == b.path.rope {
      return metric.distance(from: a.path.chunk, to: b.path.chunk, in: a.chunk)
    }
    var d = 0
    d += rope.distance(from: a.path.rope, to: b.path.rope, in: metric)
    d -= metric.distance(from: a.chunk.string.startIndex, to: a.path.chunk, in: a.chunk)
    d += metric.distance(from: b.chunk.string.startIndex, to: b.path.chunk, in: b.chunk)
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

extension _BString {
  func _path(
    _ i: Index,
    offsetBy distance: Int,
    in metric: some _StringMetric
  ) -> (path: Path, chunk: Chunk) {
    var (path, chunk) = path(to: i, preferEnd: false)
    var d = distance
    let r = metric.formIndex(&path.chunk, offsetBy: &d, in: chunk)
    if r.found {
      return (path, chunk)
    }
    
    if r.forward {
      assert(distance >= 0)
      assert(path.chunk == chunk.string.endIndex)
      d += metric.nonnegativeSize(of: chunk.summary)
      rope.formIndex(&path.rope, offsetBy: &d, in: metric, preferEnd: false)
      precondition(path.rope < rope.endIndex)
      chunk = rope[path.rope]
      path.chunk = metric.index(at: d, in: chunk)
      return (path, chunk)
    }
    
    assert(distance <= 0)
    assert(path.chunk == chunk.string.startIndex)
    rope.formIndex(&path.rope, offsetBy: &d, in: metric, preferEnd: false)
    chunk = rope[path.rope]
    path.chunk = metric.index(at: d, in: chunk)
    return (path, chunk)
  }
  
  func index(
    _ i: Index,
    offsetBy distance: Int,
    in metric: some _StringMetric
  ) -> Index {
    var (path, chunk) = path(to: i, preferEnd: false)
    let base = baseIndex(with: i, at: path.chunk)
    var d = distance
    let r = metric.formIndex(&path.chunk, offsetBy: &d, in: chunk)
    if r.found {
      return index(base: base, offsetBy: path.chunk)
    }
    
    if r.forward {
      assert(distance >= 0)
      assert(path.chunk == chunk.string.endIndex)
      d += metric.nonnegativeSize(of: chunk.summary)
      rope.formIndex(&path.rope, offsetBy: &d, in: metric, preferEnd: false)
      if path.rope == rope.endIndex {
        return Index(_utf8Offset: self.utf8Count)
      }
      chunk = rope[path.rope]
      path.chunk = metric.index(at: d, in: chunk)
      return index(of: path)
    }
    
    assert(distance <= 0)
    assert(path.chunk == chunk.string.startIndex)
    rope.formIndex(&path.rope, offsetBy: &d, in: metric, preferEnd: false)
    chunk = rope[path.rope]
    path.chunk = metric.index(at: d, in: chunk)
    return index(of: path)
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

extension _BString {
  func characterIndex(roundingDown i: Index) -> Index {
    let offset = i._utf8Offset - 1
    precondition(offset >= 0 && offset <= utf8Count, "Index out of bounds")
    guard offset > 0, offset < utf8Count else { return Index(_utf8Offset: offset) }

    let (path, chunk) = path(to: i, preferEnd: true)
    var base = baseIndex(with: i, at: path.chunk)
    if chunk.hasBreaks {
      let first = chunk.firstBreak
      let last = chunk.lastBreak
      if path.chunk == first || path.chunk == last {
        return i
      }
      if path.chunk > chunk.lastBreak {
        return base._advanceUTF8(by: chunk.string._utf8Offset(of: chunk.lastBreak))
      }
      if path.chunk > chunk.firstBreak {
        let j = chunk.string._index(roundingDown: path.chunk)
        return base._advanceUTF8(by: chunk.string._utf8Offset(of: j))
      }
    }

    var it = self.rope.makeIterator(from: path.rope)
    while it.stepBackward() {
      base = base._advanceUTF8(by: -it.current.utf8Count)
      if it.current.hasBreaks { break }
    }
    return base._advanceUTF8(by: it.current.string._utf8Offset(of: it.current.lastBreak))
  }

  func unicodeScalarIndex(roundingDown i: Index) -> Index {
    precondition(i <= endIndex, "Index out of bounds")
    guard i > startIndex, i < endIndex else { return Index(_utf8Offset: i._utf8Offset) }
    let (path, chunk) = path(to: i, preferEnd: true)
    let j = chunk.string.unicodeScalars._index(roundingDown: path.chunk)
    return i._advanceUTF8(by: j._utf8Offset - path.chunk._utf8Offset)
  }

  func utf8Index(roundingDown i: Index) -> Index {
    precondition(i <= endIndex, "Index out of bounds")
    // Clear any UTF-16 offset
    return Index(_utf8Offset: i._utf8Offset)
  }

  func utf16Index(roundingDown i: Index) -> Index {
    if i._utf16Delta > 0 {
      precondition(i <= endIndex, "Index out of bounds")
      return i
    }
    return unicodeScalarIndex(roundingDown: i)
  }
}

extension _BString {
  func _character(
    at start: Path, base: Index?, in chunk: Chunk
  ) -> (character: Character, end: Path, base: Index?) {
    let offset = chunk.string._utf8Offset(of: start.chunk)
    let c = chunk.string[start.chunk]
    let d = c.utf8.count
    if offset + d < chunk.utf8Count {
      return (
        character: c,
        end: Path(start.rope, chunk.string._utf8Index(at: offset + d)),
        base: base)
    }
    var s = String(c)
    var base = base
    var it = self.rope.makeIterator(from: start.rope)
    while true {
      base = base?._advanceUTF8(by: it.current.utf8Count)
      guard it.stepForward() else { break }
      let chunk = it.current
      s.append(contentsOf: chunk.prefix)
      if chunk.hasBreaks { break }
    }
    return (Character(s), Path(it.index, it.current.firstBreak), base)
  }

  subscript(utf8 index: Index) -> UInt8 {
    precondition(index < endIndex, "Index out of bounds")
    let (path, chunk) = path(to: index, preferEnd: false)
    return chunk.string.utf8[path.chunk]
  }

  subscript(utf16 index: Index) -> UInt16 {
    precondition(index < endIndex, "Index out of bounds")
    let (path, chunk) = path(to: index, preferEnd: false)
    return chunk.string.utf16[path.chunk]
  }

  subscript(character index: Index) -> Character {
    precondition(index < endIndex, "Index out of bounds")
    let (path, chunk) = path(to: index, preferEnd: false)
    let base = baseIndex(with: index, at: path.chunk)
    return _character(at: path, base: base, in: chunk).character
  }

  subscript(character offset: Int) -> Character {
    let (path, chunk) = _path(startIndex, offsetBy: offset, in: CharacterMetric())
    return _character(at: path, base: nil, in: chunk).character
  }

  subscript(unicodeScalar index: Index) -> Unicode.Scalar {
    precondition(index < endIndex, "Index out of bounds")
    let (path, chunk) = path(to: index, preferEnd: false)
    return chunk.string.unicodeScalars[path.chunk]
  }

  subscript(unicodeScalar offset: Int) -> Unicode.Scalar {
    precondition(offset >= 0 && offset < unicodeScalarCount, "Offset out of bounds")
    let (path, chunk) = _path(startIndex, offsetBy: offset, in: UnicodeScalarMetric())
    return chunk.string.unicodeScalars[path.chunk]
  }
}
