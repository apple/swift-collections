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
  struct ChunkIterator {
    var base: Rope.Iterator

    init(base: Rope.Iterator) {
      self.base = base
    }
  }

  func makeChunkIterator() -> ChunkIterator {
    ChunkIterator(base: rope.makeIterator())
  }
}

@available(macOS 13.3, iOS 16.4, watchOS 9.4, tvOS 16.4, *)
extension _BString.ChunkIterator: IteratorProtocol {
  typealias Element = String

  mutating func next() -> String? {
    base.next()?.string
  }
}

@available(macOS 13.3, iOS 16.4, watchOS 9.4, tvOS 16.4, *)
extension _BString {
  @available(*, deprecated)
  internal typealias UTF8Iterator = UTF8View.Iterator

  @available(*, deprecated)
  internal func makeUTF8Iterator() -> UTF8Iterator {
    UTF8Iterator(_base: self, from: self.startIndex)
  }

  @available(*, deprecated)
  internal func makeUTF8Iterator(from start: Index) -> UTF8Iterator {
    UTF8Iterator(_base: self, from: start)
  }
}

@available(macOS 13.3, iOS 16.4, watchOS 9.4, tvOS 16.4, *)
extension _BString {
  @available(*, deprecated)
  internal typealias UTF16Iterator = UTF16View.Iterator

  @available(*, deprecated)
  internal func makeUTF16Iterator() -> UTF16Iterator {
    UTF16Iterator(_base: self, from: self.startIndex)
  }

  @available(*, deprecated)
  internal func makeUTF16Iterator(from start: Index) -> UTF16Iterator {
    UTF16Iterator(_base: self, from: start)
  }
}

@available(macOS 13.3, iOS 16.4, watchOS 9.4, tvOS 16.4, *)
extension _BString {
  @available(*, deprecated)
  internal typealias UnicodeScalarIterator = UnicodeScalarView.Iterator

  @available(*, deprecated)
  internal func makeUnicodeScalarIterator() -> UnicodeScalarIterator {
    UnicodeScalarIterator(_base: self, from: startIndex)
  }

  @available(*, deprecated)
  internal func makeUnicodeScalarIterator(from start: Index) -> UnicodeScalarIterator {
    UnicodeScalarIterator(_base: self, from: start)
  }
}

#endif
