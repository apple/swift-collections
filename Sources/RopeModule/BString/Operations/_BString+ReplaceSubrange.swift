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
  mutating func replaceSubrange(_ range: Range<Index>, with newElements: some StringProtocol) {
    precondition(range.upperBound <= endIndex, "Index out of bounds")
    if range.isEmpty {
      insert(contentsOf: newElements, at: range.lowerBound)
      return
    }
    var builder = _split(removing: range)
    var ingester = Ingester(Substring(newElements), startState: builder.prefixEndState)
    builder.append(from: &ingester)
    self = builder.finalize()
  }

  mutating func replaceSubrange(_ range: Range<Index>, with newElements: _BString) {
    precondition(range.upperBound <= endIndex, "Index out of bounds")
    if range.isEmpty {
      insert(contentsOf: newElements, at: range.lowerBound)
      return
    }
    var builder = _split(removing: range)
    builder.append(newElements)
    self = builder.finalize()
  }

  mutating func replaceSubrange(
    _ targetRange: Range<Index>,
    with newElements: _BString,
    in sourceRange: Range<Index>
  ) {
    if sourceRange._isEmptyUTF8 {
      removeSubrange(targetRange)
      return
    }
    if targetRange._isEmptyUTF8 {
      insert(
        contentsOf: newElements,
        in: sourceRange,
        at: targetRange.lowerBound)
      return
    }
    precondition(targetRange.upperBound <= endIndex, "Index out of bounds")
    var builder = _split(removing: targetRange)
    builder.append(newElements, in: sourceRange)
    self = builder.finalize()
  }

  mutating func _split(removing range: Range<Index>) -> Builder {
    let lower = range.lowerBound._utf8Offset
    let upper = range.upperBound._utf8Offset

    // FIXME: Don't split the indices twice -- they are currently split once here and once in the
    // builder initializer below.
    let startState = _breakState(upTo: range.lowerBound)
    let endState = _breakState(upTo: range.upperBound)

    let b = rope.builder(removing: lower ..< upper, in: UTF8Metric())
    return Builder(base: b, prefixEndState: startState, suffixStartState: endState)
  }
}

#endif
