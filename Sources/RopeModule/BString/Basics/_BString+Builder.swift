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
  struct Builder {
    typealias Chunk = _BString.Chunk
    typealias Ingester = _BString.Ingester
    typealias Rope = _BString.Rope
    
    var base: Rope.Builder
    var suffixStartState: _CharacterRecognizer
    var prefixEndState: _CharacterRecognizer
    
    init(
      base: Rope.Builder,
      prefixEndState: _CharacterRecognizer,
      suffixStartState: _CharacterRecognizer
    ) {
      self.base = base
      self.suffixStartState = suffixStartState
      self.prefixEndState = prefixEndState
    }

    init() {
      self.base = Rope.Builder()
      self.suffixStartState = _CharacterRecognizer()
      self.prefixEndState = _CharacterRecognizer()
    }
  }
}

@available(macOS 13.3, iOS 16.4, watchOS 9.4, tvOS 16.4, *)
extension _Rope<_BString.Chunk>.Builder {
  func breakState() -> _CharacterRecognizer {
    let chars = self.prefixSummary.characters
    assert(self.isPrefixEmpty || chars > 0)
    let metric = _BString.CharacterMetric()
    var state = _CharacterRecognizer()
    _ = self.forEachElementInPrefix(from: chars - 1, in: metric) { chunk, i in
      if let i {
        state = .init(partialCharacter: chunk.string[i...])
      } else {
        state.consumePartialCharacter(chunk.string[...])
      }
      return true
    }
    return state
  }
}

@available(macOS 13.3, iOS 16.4, watchOS 9.4, tvOS 16.4, *)
extension _BString.Builder {
  mutating func append(_ str: __owned some StringProtocol) {
    append(Substring(str))
  }
  
  mutating func append(_ str: __owned String) {
    append(str[...])
  }
  
  mutating func append(_ str: __owned Substring) {
    guard !str.isEmpty else { return }
    var ingester = Ingester(str, startState: self.prefixEndState)
    if var prefix = base.prefix._take() {
      if let slice = ingester.nextSlice(maxUTF8Count: prefix.value.availableSpace) {
        prefix.value._append(slice)
      }
      self.base.prefix = prefix
    }
    while let next = ingester.nextChunk() {
      base.append(next)
    }
    self.prefixEndState = ingester.state
  }
  
  mutating func append(_ newChunk: __owned Chunk) {
    var state = _CharacterRecognizer()
    append(newChunk, state: &state)
  }
  
  mutating func append(_ newChunk: __owned Chunk, state: inout _CharacterRecognizer) {
    var newChunk = newChunk
    newChunk.resyncBreaksFromStartToEnd(old: &state, new: &self.prefixEndState)
    self.base.append(newChunk)
  }
  
  mutating func append(_ other: __owned _BString) {
    var state = _CharacterRecognizer()
    append(other.rope, state: &state)
  }

  mutating func append(_ other: __owned _BString, in range: Range<_BString.Index>) {
    let extract = _BString(other, in: range, state: &self.prefixEndState)
    self.base.append(extract.rope)
  }

  mutating func append(_ other: __owned Rope, state: inout _CharacterRecognizer) {
    guard !other.isEmpty else { return }
    var other = _BString(rope: other)
    other.rope.resyncBreaksToEnd(old: &state, new: &self.prefixEndState)
    self.base.append(other.rope)
  }
  
  mutating func append(from ingester: inout Ingester) {
    assert(ingester.state == self.prefixEndState)
    if var prefix = base.prefix._take() {
      if let first = ingester.nextSlice(maxUTF8Count: prefix.value.availableSpace) {
        prefix.value._append(first)
      }
      base.prefix = prefix
    }
    
    let suffixCount = base.suffix?.value.utf8Count ?? 0
    
    while let chunk = ingester.nextWellSizedChunk(suffix: suffixCount) {
      base.append(chunk)
    }
    precondition(ingester.isAtEnd)
    self.prefixEndState = ingester.state
  }
}

@available(macOS 13.3, iOS 16.4, watchOS 9.4, tvOS 16.4, *)
extension _BString.Builder {
  mutating func finalize() -> _BString {
    // Resync breaks in suffix.
    _ = base.mutatingForEachSuffix { chunk in
      chunk.resyncBreaksFromStart(old: &suffixStartState, new: &prefixEndState)
    }
    // Roll it all up.
    let rope = self.base.finalize()
    let string = _BString(rope: rope)
    string.invariantCheck()
    return string
  }
}

#endif
