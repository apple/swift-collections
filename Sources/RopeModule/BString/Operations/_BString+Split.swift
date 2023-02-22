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
  mutating func split(
    at index: Index
  ) -> Builder {
    let b = _ropeBuilder(at: index)
    let state = b.breakState()
    let builder = Builder(base: b, prefixEndState: state, suffixStartState: state)
    return builder
  }

  mutating func split(
    at index: Index,
    state: _CharacterRecognizer
  ) -> Builder {
    let b = _ropeBuilder(at: index)
    let builder = Builder(base: b, prefixEndState: state, suffixStartState: state)
    return builder
  }

  mutating func _ropeBuilder(at index: Index) -> Rope.Builder {
    if let ri = index._rope, rope.isValid(ri) {
      return rope.split(at: ri, index._chunkIndex)
    }
    return rope.builder(splittingAt: index._utf8Offset, in: UTF8Metric())
  }
}

#endif
