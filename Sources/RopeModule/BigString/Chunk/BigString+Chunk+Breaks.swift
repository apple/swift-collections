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
extension BigString._Chunk {
  @inline(__always)
  var hasBreaks: Bool { counts.hasBreaks }

  var firstBreak: Index {
    get {
      Index(utf8Offset: prefixCount).characterAligned
    }

    set {
      counts.prefix = newValue.utf8Offset
    }
  }

  var lastBreak: Index {
    get {
      Index(utf8Offset: utf8Count - suffixCount).characterAligned
    }

    set {
      counts.suffix = utf8Count - newValue.utf8Offset
    }
  }

  var prefix: UTF8Span {
    utf8Span(from: startIndex, to: firstBreak)
  }

  var suffix: UTF8Span {
    utf8Span(from: lastBreak)
  }

  var wholeCharacters: UTF8Span {
    utf8Span(from: firstBreak)
  }
}

@available(SwiftStdlib 6.2, *)
extension BigString._Chunk {
  var immediateLastBreakState: _CharacterRecognizer? {
    guard hasBreaks else { return nil }
    return _CharacterRecognizer(partialCharacter: suffix)
  }

  func nearestBreak(before index: Index) -> Index? {
    let index = scalarIndex(roundingDown: index)
    let first = firstBreak
    guard index > first else { return nil }
    let last = lastBreak
    guard index <= last else { return last }
    let rounded = characterIndex(roundingDown: index)
    guard rounded == index else { return rounded }
    return characterIndex(before: rounded)
  }

  func immediateBreakState(
    upTo index: Index
  ) -> (prevBreak: Index, state: _CharacterRecognizer)? {
    guard let prev = nearestBreak(before: index) else { return nil }
    let state = _CharacterRecognizer(partialCharacter: utf8Span(from: prev, to: index))
    return (prev, state)
  }
}

#endif // compiler(>=6.2) && !$Embedded
