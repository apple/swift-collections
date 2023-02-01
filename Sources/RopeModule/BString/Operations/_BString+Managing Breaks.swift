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
  func _breakState(
    upTo end: Path,
    in chunk: Chunk,
    nextScalarHint: Unicode.Scalar? = nil
  ) -> (prevBreak: Path, state: _CharacterRecognizer) {
    guard end.rope > rope.startIndex || end._chunk > 0 else {
      return (Path(startOf: rope.startIndex), _CharacterRecognizer())
    }

    if let next = nextScalarHint, end.chunk > chunk.string.startIndex {
      let i = chunk.string.unicodeScalars.index(before: end.chunk)
      let prev = chunk.string.unicodeScalars[i]
      if _CharacterRecognizer.quickBreak(between: prev, and: next) == true {
        return (end, _CharacterRecognizer())
      }
    }

    if let r = chunk.immediateBreakState(upTo: end.chunk) {
      return (Path(end.rope, r.prevBreak), r.state)
    }
    // Find chunk that includes the start of the character.
    var it = rope.makeIterator(from: end.rope)
    while it.stepBackward() {
      if it.current.hasBreaks { break }
    }
    precondition(it.index < end.rope)
    let prev = Path(it.index, it.current.lastBreak)

    // Collect grapheme breaking state.
    var state = _CharacterRecognizer(partialCharacter: it.current.suffix)
    while it.stepForward(), it.index < end.rope {
      state.consumePartialCharacter(it.current.string[...])
    }
    state.consumePartialCharacter(it.current.string[..<end.chunk])
    return (prev, state)
  }

  func _breakState(
    upTo index: Index,
    nextScalarHint: Unicode.Scalar? = nil
  ) -> (start: Path, end: Path, state: _CharacterRecognizer) {
    guard index > startIndex else {
      let dummy = Path(startOf: rope.startIndex)
      return (dummy, dummy, _CharacterRecognizer())
    }
    let end = path(to: index, preferEnd: true)
    let r = _breakState(upTo: end.path, in: end.chunk, nextScalarHint: nextScalarHint)
    return (r.prevBreak, end.path, r.state)
  }
}

extension _BString {
  /// - Returns: the position at which the grapheme breaks finally sync up with the originals.
  ///  (or nil if they never did).
  @discardableResult
  mutating func resyncBreaks(
    startingAt index: Index,
    old: inout _CharacterRecognizer,
    new: inout _CharacterRecognizer
  ) -> Path? {
    guard index < endIndex else { return nil }
    let p = path(to: index, preferEnd: false).path
    var path = (rope: p.rope, chunk: p.chunk)

    let end = rope.mutatingForEach(from: &path.rope) { chunk in
      let start = path.chunk
      path.chunk = "".startIndex
      return chunk.resyncBreaks(startingAt: start, old: &old, new: &new)
    }
    guard let end else { return nil }
    path.chunk = end
    return Path(path.rope, path.chunk)
  }

  mutating func resyncBreaksToEnd(
    startingAt index: Index,
    old: inout _CharacterRecognizer,
    new: inout _CharacterRecognizer
  ) {
    guard let _ = resyncBreaks(startingAt: index, old: &old, new: &new) else { return }
    let state = _breakState(upTo: endIndex).state
    old = state
    new = state
  }
}

extension _BString.Rope {
  mutating func resyncBreaks(
    old: inout _CharacterRecognizer,
    new: inout _CharacterRecognizer
  ) -> Bool {
    var index = startIndex
    let r = self.mutatingForEach(from: &index) {
      $0.resyncBreaksFromStart(old: &old, new: &new)
    }
    return r != nil
  }

  mutating func _resyncBreaks(
    old: inout _CharacterRecognizer,
    new: inout _CharacterRecognizer
  ) -> (path: Index, String.Index)? {
    var index = startIndex
    let r = self.mutatingForEach(from: &index) {
      $0.resyncBreaksFromStart(old: &old, new: &new)
    }
    guard let r else { return nil }
    return (index, r)
  }

  mutating func resyncBreaksToEnd(
    old: inout _CharacterRecognizer,
    new: inout _CharacterRecognizer
  ) {
    guard let (index, i) = _resyncBreaks(old: &old, new: &new) else { return }

    let chars = self.summary.characters
    if chars > 0 {
      var it = makeIterator(from: endIndex)
      while it.stepBackward() {
        if it.current.hasBreaks { break }
        if it.index == index { break }
      }
      if it.index > index || it.current.lastBreak > i {
        new = it.current.immediateLastBreakState!
        while it.stepForward() {
          new.consumePartialCharacter(it.current.string[...])
        }
        old = new
        return
      }
    }
    var it = makeIterator(from: index)
    let suffix = it.current.string.unicodeScalars[i...].dropFirst()
    new.consumePartialCharacter(suffix)
    while it.stepForward() {
      new.consumePartialCharacter(it.current.string[...])
    }
    old = new
  }
}

extension _BString.Chunk {
  /// Resyncronize chunk metadata with the (possibly) reshuffled grapheme
  /// breaks after an insertion that ended at `index`.
  ///
  /// This assumes that the chunk's prefix and suffix counts have already
  /// been adjusted to remain on Unicode scalar boundaries, and that they
  /// are also in sync with the grapheme breaks up to `index`. If the
  /// prefix ends after `index`, then this function may update it to address
  /// the correct scalar. Similarly, the suffix count may be updated to
  /// reflect the new position of the last grapheme break, if necessary.
  mutating func resyncBreaks(
    startingAt index: String.Index,
    old: inout _CharacterRecognizer,
    new: inout _CharacterRecognizer
  ) -> String.Index? {
    var i = index
    let u = string.unicodeScalars
    assert(u._index(roundingDown: i) == i)

    // FIXME: Rewrite in terms of `firstBreak(in:)`.
    var first: String.Index? = nil
    var last: String.Index? = nil
  loop:
    while i < u.endIndex {
      let scalar = u[i]
      let a = old.hasBreak(before: scalar)
      let b = new.hasBreak(before: scalar)
      if b {
        first = first ?? i
        last = i
      }
      switch (a, b) {
      case (true, true):
        break loop // Resync complete ✨
      case (false, false):
        if old == new { break loop }
      case (false, true):
        counts._characters += 1
      case (true, false):
        counts._characters -= 1
      }
      u.formIndex(after: &i)
    }

    // Grapheme breaks in `index...i` may have changed. Update `firstBreak` and `lastBreak`
    // accordingly.

    assert((first == nil) == (last == nil))
    if index <= firstBreak {
      if let first {
        // We have seen the new first break.
        firstBreak = first
      } else if i >= firstBreak {
        // The old firstBreak is no longer a break.
        if i < lastBreak {
          // The old lastBreak is still valid. Find the first break in i+1...endIndex.
          let j = u.index(after: i)
          var tmp = new
          firstBreak = tmp.firstBreak(in: string[j...])!.lowerBound
        } else {
          // No breaks anywhere in the string.
          firstBreak = u.endIndex
        }
      }
    }

    if i >= lastBreak {
      if let last {
        // We have seen the new last break.
        lastBreak = last
      } else if firstBreak == u.endIndex {
        // We already know there are no breaks anywhere in the string.
        lastBreak = u.startIndex
      } else {
        // We have a `firstBreak`, but no break in `index...i`.
        // Find last break in `firstBreak...<index`.
        let wholeChars = self.string[firstBreak..<index]
        lastBreak = wholeChars.index(before: wholeChars.endIndex)
      }
    }

    return i < u.endIndex ? i : nil
  }

  mutating func resyncBreaksFromStart(
    old: inout _CharacterRecognizer,
    new: inout _CharacterRecognizer
  ) -> String.Index? {
    resyncBreaks(startingAt: string.startIndex, old: &old, new: &new)
  }

  mutating func resyncBreaksFromStartToEnd(
    old: inout _CharacterRecognizer,
    new: inout _CharacterRecognizer
  ) {
    guard let i = resyncBreaks(startingAt: string.startIndex, old: &old, new: &new) else {
      return
    }
    if i < lastBreak {
      new = _CharacterRecognizer(partialCharacter: string[lastBreak...])
    } else {
      assert(old == new)
      let j = string.unicodeScalars.index(after: i)
      new.consumePartialCharacter(string[j...])
    }
    old = new
    return
  }
}
