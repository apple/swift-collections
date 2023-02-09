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
  internal init(_ input: some StringProtocol) {
    var builder = Rope.Builder()
    var ingester = Ingester(input)
    while let chunk = ingester.nextWellSizedChunk() {
      builder.append(chunk)
    }
    self.rope = builder.finalize()
  }

  internal init(_ input: some Sequence<Character>) {
    var builder = Builder()
    var piece = ""
    for character in input {
      piece.append(character)
      if piece.utf8.count >= Chunk.minUTF8Count {
        builder.append(piece)
        piece = ""
      }
    }
    builder.append(piece)
    self = builder.finalize()
  }

  internal init(_ input: some Sequence<UnicodeScalar>) {
    var builder = Builder()
    var piece = ""
    for scalar in input {
      piece.unicodeScalars.append(scalar)
      if piece.utf8.count >= Chunk.minUTF8Count {
        builder.append(piece)
        piece = ""
      }
    }
    builder.append(piece)
    self = builder.finalize()
  }

  internal init(
    _ other: Self,
    in range: Range<Index>
  ) {
    self.rope = other.rope.extract(
      from: range.lowerBound._utf8Offset,
      to: range.upperBound._utf8Offset,
      in: UTF8Metric())
    var old = other._breakState(upTo: range.lowerBound).state
    var new = _CharacterRecognizer()
    _ = self.rope.resyncBreaks(old: &old, new: &new)
  }

  internal init(
    _ other: Self,
    in range: Range<Index>,
    state: inout _CharacterRecognizer
  ) {
    self.rope = other.rope.extract(
      from: range.lowerBound._utf8Offset,
      to: range.upperBound._utf8Offset,
      in: UTF8Metric())
    var old = other._breakState(upTo: range.lowerBound).state
    var new = state
    self.rope.resyncBreaksToEnd(old: &old, new: &new)
  }
}

@available(macOS 13.3, iOS 16.4, watchOS 9.4, tvOS 16.4, *)
extension String {
  internal init(_from big: _BString) {
    guard !big.isEmpty else {
      self.init()
      return
    }
    if big.rope.isSingleton {
      self = big.rope[big.rope.startIndex].string
      return
    }
    self.init()
    self.reserveCapacity(big.utf8Count)
    for chunk in big.rope {
      self.append(chunk.string)
    }
  }
  
  internal init(_from big: _BString, in range: Range<_BString.Index>) {
    self.init()
    let estimatedUTF8Size = range.upperBound._utf8Offset - range.lowerBound._utf8Offset
    guard estimatedUTF8Size > 0 else {
      // We can safely ignore UTF-16 offsets, as we're rounding down to scalar boundaries
      // anyway.
      return
    }
    // Note: if the range isn't scalar aligned, then this may be slightly under- or overestimating
    // the actual size of the result. (Underestimations can be problematic due to String's
    // exponential resizing. If those become an issue, consider adding +3 here.)
    self.reserveCapacity(estimatedUTF8Size)

    let start = big.path(to: range.lowerBound, preferEnd: false)
    let end = big.path(to: range.upperBound, preferEnd: true)
    
    if start.path.rope == end.path.rope {
      self += start.chunk.string[start.path.chunk ..< end.path.chunk]
      return
    }

    self += start.chunk.string[start.path.chunk...]
    
    var it = big.rope.makeIterator(from: start.path.rope)
    while it.stepForward(), it.index < end.path.rope {
      self += it.current.string
    }
    self += end.chunk.string[..<end.path.chunk]
  }
}

@available(macOS 13.3, iOS 16.4, watchOS 9.4, tvOS 16.4, *)
extension _BString {
  internal init(repeating value: Self, count: Int) {
    precondition(count >= 0, "Negative count")
    guard count > 0 else {
      self.init()
      return
    }
    self.init()
    var c = 0

    var piece = value
    var current = 1

    while c < count {
      if count & current != 0 {
        self.append(contentsOf: piece)
        c |= current
      }
      piece.append(contentsOf: piece)
      current *= 2
    }
  }
}

#endif
