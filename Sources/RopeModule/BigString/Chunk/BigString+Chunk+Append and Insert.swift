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

@available(SwiftStdlib 6.2, *)
extension BigString._Chunk {
  mutating func append(_ other: borrowing BigString._Chunk) {
    _append(other.utf8Span, other.counts)
  }

  mutating func append(from ingester: inout BigString._Ingester) -> Self? {
    let desired = BigString._Ingester.desiredNextChunkSize(
      remaining: self.utf8Count + ingester.remainingUTF8)
    if desired == self.utf8Count {
      return nil
    }
    if desired > self.utf8Count {
      if let slice = ingester.nextSlice(maxUTF8Count: desired - self.utf8Count) {
        self._append(slice)
      }
      return nil
    }

    // Split current chunk.
    let cut = scalarIndex(roundingDown: Index(utf8Offset: desired))
    var new = self.split(at: cut)
    precondition(!self.isUndersized)
    let slice = ingester.nextSlice()!
    new._append(slice)
    precondition(ingester.isAtEnd)
    precondition(!new.isUndersized)
    return new
  }

  mutating func _append(_ other: Slice) {
    let c = Counts(other)
    _append(other.string, c)
  }

  mutating func _append(_ str: consuming Substring, _ other: Counts) {
    _append(other) {
      _ = $0.initialize(from: str.utf8)
    }
  }

  mutating func _append(_ span: UTF8Span, _ other: Counts) {
    _append(other) { buffer in
      span.span.withUnsafeBufferPointer {
        _ = buffer.initialize(fromContentsOf: $0)
      }
    }
  }

  mutating func _append(
    _ newCounts: Counts,
    _ body: (UnsafeMutableBufferPointer<UInt8>) -> ()
  ) {
    ensureUnique()

    let utf8Before = Int(counts.utf8)
    counts.append(newCounts)

    storage.withUnsafeMutablePointerToElements {
      let buffer = UnsafeMutableBufferPointer(
        start: $0,
        count: Self.maxUTF8Count
      )

      body(buffer.extracting(utf8Before...))
    }

    invariantCheck()
  }

  // Note: This assumes you've already called 'ensureUnique()'
  mutating func _shift(_ range: Range<Index>, to: Index) {
    let originalRange = range.lowerBound.utf8Offset..<range.upperBound.utf8Offset
    precondition(to.utf8Offset + originalRange.count <= Self.maxUTF8Count)

    // Only grab the slice pointing at initialized code units.
    let originalBuffer = _mutableBytes.extracting(originalRange)

    // Grab the buffer starting from the shifted utf8 offset till the
    // length of the already initialized buffer.
    let newOriginalRange = to.utf8Offset ..< originalRange.count + to.utf8Offset
    let newOriginalBuffer = _mutableBytes.extracting(newOriginalRange)

    // Initialize the contents of the new buffer from the original.
    //
    // Note: This most likely overlaps
    _ = newOriginalBuffer.moveInitialize(fromContentsOf: originalBuffer)
  }

  mutating func _prepend(_ span: UTF8Span, _ other: Counts) {
    ensureUnique()

    precondition(utf8Count + span.count <= Self.maxUTF8Count)

    // We first need to shift our contents down to make space for the prepended
    // text.
    _shift(startIndex..<endIndex, to: Index(utf8Offset: Int(other.utf8)))

    // Grab the prepended text's buffer.
    let prependRange = 0..<Int(other.utf8)
    let prependBuffer = _mutableBytes.extracting(prependRange)

    // Initialize the beginning of the chunk with the prepended text.
    span.span.withUnsafeBufferPointer {
      _ = prependBuffer.initialize(fromContentsOf: $0)
    }

    let c = counts
    counts = other
    counts.append(c)
    invariantCheck()
  }
}

@available(SwiftStdlib 6.2, *)
extension BigString._Chunk {
  mutating func _insert(
    _ slice: Slice,
    at index: Index,
    old: inout _CharacterRecognizer,
    new: inout _CharacterRecognizer
  ) -> Index? {
    let count = slice.string.utf8.count
    precondition(utf8Count + count <= Self.maxUTF8Count)

    let parts = self.splitCounts(at: index)

    // Shift the right parts down to make space for the insertion.
    let from = index.utf8Offset
    let to = index.utf8Offset + slice.string.utf8.count
    _shift(index..<endIndex, to: Index(utf8Offset: to))

    // Initialize the gap with the contents of the insertion string.
    _ = _mutableBytes.extracting(from..<to).initialize(from: slice.string.utf8)

    self.counts = parts.left
    self.counts.append(Counts(slice))
    self.counts.append(parts.right)

    let end = Index(utf8Offset: index.utf8Offset + count)
    return resyncBreaks(startingAt: end, old: &old, new: &new)
  }

  typealias States = (increment: Int, old: _CharacterRecognizer, new: _CharacterRecognizer)

  mutating func insertAll(
    from ingester: inout BigString._Ingester,
    at index: Index
  ) -> States? {
    let remaining = ingester.remainingUTF8
    precondition(self.utf8Count + remaining <= Self.maxUTF8Count)
    var startState = ingester.state
    guard let slice = ingester.nextSlice(maxUTF8Count: remaining) else { return nil }
    var endState = ingester.state
    assert(ingester.isAtEnd)
    let offset = index.utf8Offset
    if let _ = self._insert(slice, at: index, old: &startState, new: &endState) {
      return nil
    }
    return (self.utf8Count - offset, startState, endState)
  }

  enum InsertResult {
    case inline(States?)
    case split(spawn: BigString._Chunk, endStates: States?)
    case large
  }

  mutating func insert(
    from ingester: inout BigString._Ingester,
    at index: Index
  ) -> InsertResult {
    ensureUnique()

    let origCount = self.utf8Count
    let rem = ingester.remainingUTF8
    guard rem > 0 else { return .inline(nil) }
    let sum = origCount + rem

    let offset = index.utf8Offset
    if sum <= Self.maxUTF8Count {
      let r = insertAll(from: &ingester, at: index)
      return .inline(r)
    }

    let desired = BigString._Ingester.desiredNextChunkSize(remaining: sum)
    guard sum - desired + Self.maxSlicingError <= Self.maxUTF8Count else { return .large }

    if desired <= offset {
      // Inserted text lies entirely within `spawn`.
      let desiredIndex = Index(utf8Offset: desired)
      let cut = scalarIndex(roundingDown: desiredIndex)
      var spawn = split(at: cut)
      let i = Index(utf8Offset: offset - utf8Count)
      let r = spawn.insertAll(from: &ingester, at: i)
      assert(r == nil || r?.increment == sum - offset)
      return .split(spawn: spawn, endStates: r)
    }
    if desired >= offset + rem {
      // Inserted text lies entirely within `self`.
      let i = Index(utf8Offset: desired - rem)
      let cut = scalarIndex(roundingDown: i)
      assert(cut >= index)
      var spawn = split(at: cut)
      guard
        var r = self.insertAll(from: &ingester, at: Index(utf8Offset: offset)),
        nil == spawn.resyncBreaks(startingAt: spawn.startIndex, old: &r.old, new: &r.new)
      else {
        return .split(spawn: spawn, endStates: nil)
      }
      return .split(spawn: spawn, endStates: (sum - offset, r.old, r.new))
    }
    // Inserted text is split across `self` and `spawn`.
    var spawn = split(at: index)
    var old = ingester.state
    if let slice = ingester.nextSlice(maxUTF8Count: desired - offset) {
      self._append(slice)
    }
    let slice = ingester.nextSlice()!
    assert(ingester.isAtEnd)
    var new = ingester.state
    let stop = spawn._insert(slice, at: spawn.startIndex, old: &old, new: &new)
    if stop != nil {
      return .split(spawn: spawn, endStates: nil)
    }
    return .split(spawn: spawn, endStates: (sum - offset, old, new))
  }
}
