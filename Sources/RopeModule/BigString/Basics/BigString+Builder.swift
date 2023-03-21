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
extension BigString {
  struct Builder {
    typealias Chunk = BigString.Chunk
    typealias Ingester = BigString.Ingester
    typealias _Storage = BigString._Storage
    
    var base: _Storage.Builder
    var suffixStartState: _CharacterRecognizer
    var prefixEndState: _CharacterRecognizer
    
    init(
      base: _Storage.Builder,
      prefixEndState: _CharacterRecognizer,
      suffixStartState: _CharacterRecognizer
    ) {
      self.base = base
      self.suffixStartState = suffixStartState
      self.prefixEndState = prefixEndState
    }

    init() {
      self.base = _Storage.Builder()
      self.suffixStartState = _CharacterRecognizer()
      self.prefixEndState = _CharacterRecognizer()
    }
  }
}

@available(macOS 13.3, iOS 16.4, watchOS 9.4, tvOS 16.4, *)
extension _Rope<BigString.Chunk>.Builder {
  func breakState() -> _CharacterRecognizer {
    let chars = self.prefixSummary.characters
    assert(self.isPrefixEmpty || chars > 0)
    let metric = BigString.CharacterMetric()
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
extension BigString.Builder {
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
  
  mutating func append(_ other: __owned BigString) {
    var state = _CharacterRecognizer()
    append(other._rope, state: &state)
  }

  mutating func append(_ other: __owned BigString, in range: Range<BigString.Index>) {
    let extract = BigString(other, in: range, state: &self.prefixEndState)
    self.base.append(extract._rope)
  }

  mutating func append(_ other: __owned _Storage, state: inout _CharacterRecognizer) {
    guard !other.isEmpty else { return }
    var other = BigString(_rope: other)
    other._rope.resyncBreaksToEnd(old: &state, new: &self.prefixEndState)
    self.base.append(other._rope)
  }
  
  mutating func append(from ingester: inout Ingester) {
    //assert(ingester.state._isKnownEqual(to: self.prefixEndState))
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
extension BigString.Builder {
  mutating func finalize() -> BigString {
    // Resync breaks in suffix.
    _ = base.mutatingForEachSuffix { chunk in
      chunk.resyncBreaksFromStart(old: &suffixStartState, new: &prefixEndState)
    }
    // Roll it all up.
    let _rope = self.base.finalize()
    let string = BigString(_rope: _rope)
    string._invariantCheck()
    return string
  }
}

#endif
