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
  struct Path {
    var rope: Rope.Index
    var _chunk: UInt16

    init(startOf rope: Rope.Index) {
      self.rope = rope
      self._chunk = 0
    }

    init(_ rope: Rope.Index, _ chunk: String.Index) {
      self.rope = rope
      self._chunk = chunk._chunkData
    }

    var chunk: String.Index {
      get {
        String.Index(_chunkData: _chunk)
      }
      set {
        _chunk = newValue._chunkData
      }
      _modify {
        var index = self.chunk
        defer {
          self.chunk = index
        }
        yield &index
      }
    }
  }
}

@available(macOS 13.3, iOS 16.4, watchOS 9.4, tvOS 16.4, *)
extension _BString.Path: CustomStringConvertible {
  var description: String {
    "\(rope).\(chunk._description)"
  }
}

@available(macOS 13.3, iOS 16.4, watchOS 9.4, tvOS 16.4, *)
extension _BString {
  func path(
    to i: Index,
    preferEnd: Bool
  ) -> (path: Path, chunk: Chunk) {
    let (ropeIndex, remaining) = rope.find(
      at: i._utf8Offset, in: UTF8Metric(), preferEnd: preferEnd)
    let chunk = rope[ropeIndex]
    let chunkIndex = chunk.index(at: remaining, utf16Delta: i._utf16Delta)
    return (Path(ropeIndex, chunkIndex), chunk)
  }
}

@available(macOS 13.3, iOS 16.4, watchOS 9.4, tvOS 16.4, *)
extension _BString {
  func baseIndex(
    with index: Index,
    at chunkIndex: String.Index
  ) -> Index {
    Index(_utf8Offset: index._utf8Offset - chunkIndex._utf8Offset)
  }

  func index(base: Index, offsetBy index: String.Index) -> Index {
    assert(index._canBeUTF8)
    return Index(
      _utf8Offset: base._utf8Offset + index._utf8Offset,
      utf16Delta: index._utf16Delta)
  }

  func index(of path: Path) -> Index {
    let position = rope.distance(from: rope.startIndex, to: path.rope, in: UTF8Metric())
    let base = Index(_utf8Offset: position)
    return index(base: base, offsetBy: path.chunk)
  }
}

#endif
