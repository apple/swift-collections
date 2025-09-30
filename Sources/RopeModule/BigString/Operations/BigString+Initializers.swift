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

#if compiler(>=6.2) && !$Embedded

@available(SwiftStdlib 6.2, *)
extension BigString {
  internal init(_from input: some StringProtocol) {
    var builder = _Rope.Builder()
    var ingester = _Ingester(input)
    while let chunk = ingester.nextWellSizedChunk() {
      builder.insertBeforeTip(chunk)
    }
    self._rope = builder.finalize()
  }

  internal init(_from input: some Sequence<Character>) {
    var builder = Builder()
    var piece = ""
    for character in input {
      piece.append(character)
      if piece.utf8.count >= _Chunk.minUTF8Count {
        builder.append(piece)
        piece = ""
      }
    }
    builder.append(piece)
    self = builder.finalize()
  }

  internal init(_from input: some Sequence<UnicodeScalar>) {
    var builder = Builder()
    var piece = ""
    for scalar in input {
      piece.unicodeScalars.append(scalar)
      if piece.utf8.count >= _Chunk.minUTF8Count {
        builder.append(piece)
        piece = ""
      }
    }
    builder.append(piece)
    self = builder.finalize()
  }

  internal init(_from other: BigSubstring) {
    self.init(_from: other._base, in: other._bounds)
  }

  internal init(_from other: BigSubstring.UnicodeScalarView) {
    self.init(_from: other._base, in: other._bounds)
  }

  internal init(
    _from other: Self,
    in range: Range<Index>
  ) {
    self._rope = other._rope.extract(
      from: range.lowerBound.utf8Offset,
      to: range.upperBound.utf8Offset,
      in: _UTF8Metric())
    var old = other._breakState(upTo: range.lowerBound)
    var new = _CharacterRecognizer()
    _ = self._rope.resyncBreaks(old: &old, new: &new)
  }

  internal init(
    _ other: Self,
    in range: Range<Index>,
    state: inout _CharacterRecognizer
  ) {
    self._rope = other._rope.extract(
      from: range.lowerBound.utf8Offset,
      to: range.upperBound.utf8Offset,
      in: _UTF8Metric())
    var old = other._breakState(upTo: range.lowerBound)
    self._rope.resyncBreaksToEnd(old: &old, new: &state)
  }
}

@available(SwiftStdlib 6.2, *)
extension String {
  public init(_ big: BigString) {
    guard !big.isEmpty else {
      self.init()
      return
    }

    self.init(unsafeUninitializedCapacity: big._utf8Count) {
      var buffer = $0

      for chunk in big._rope {
        let result = buffer.initialize(fromContentsOf: chunk._bytes)
        buffer = buffer.extracting(result...)
      }

      return big._utf8Count
    }
  }

  internal init(_from big: BigString, in range: Range<BigString.Index>) {
    self.init()

    var start = big._unicodeScalarIndex(roundingDown: range.lowerBound)
    start = big.resolve(start, preferEnd: false)

    var end = big._unicodeScalarIndex(roundingDown: range.upperBound)
    end = big.resolve(end, preferEnd: true)

    let utf8Capacity = end.utf8Offset - start.utf8Offset
    guard utf8Capacity > 0 else { return }

    self.init(unsafeUninitializedCapacity: utf8Capacity) {
      let startRopeIndex = start._rope!
      let endRopeIndex = end._rope!

      var dest = $0

      // Fast path: The entire contents of range exist within the same chunk.
      if startRopeIndex == endRopeIndex {
        let src = big._rope[startRopeIndex]._bytes.extracting(start._chunkIndex.utf8Offset ..< end._chunkIndex.utf8Offset)
        return dest.initialize(fromContentsOf: src)
      }

      var src = big._rope[startRopeIndex]._bytes.extracting(start._chunkIndex.utf8Offset...)
      var result = dest.initialize(fromContentsOf: src)
      dest = dest.extracting(result...)

      var i = big._rope.index(after: startRopeIndex)
      while i < endRopeIndex {
        let initialized = dest.initialize(fromContentsOf: big._rope[i]._bytes)
        result += initialized
        dest = dest.extracting(initialized...)
        big._rope.formIndex(after: &i)
      }

      src = big._rope[endRopeIndex]._bytes.extracting(..<end._chunkIndex.utf8Offset)
      result += dest.initialize(fromContentsOf: src)

      return result
    }
  }

  public init(_ big: BigSubstring) {
    self.init(_from: big._base, in: big._bounds)
  }

  public init(_ big: BigString.UnicodeScalarView) {
    self.init(big._base)
  }

  public init(_ big: BigSubstring.UnicodeScalarView) {
    self.init(_from: big._base, in: big._bounds)
  }
}

#endif // compiler(>=6.2) && !$Embedded
