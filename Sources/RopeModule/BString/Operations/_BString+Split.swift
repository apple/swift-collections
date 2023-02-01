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
  mutating func split(
    at index: Index
  ) -> Builder {
    let b = rope.builder(splittingAt: index._utf8Offset, in: UTF8Metric())
    let state = b.breakState()
    let builder = Builder(base: b, prefixEndState: state, suffixStartState: state)
    return builder
  }
  
  mutating func _split(
    at path: Path,
    state: _CharacterRecognizer
  ) -> Builder {
    let b = rope.split(at: path.rope, path.chunk)
    let builder = Builder(base: b, prefixEndState: state, suffixStartState: state)
    return builder
  }
}
