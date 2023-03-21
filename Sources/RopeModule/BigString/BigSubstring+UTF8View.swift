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
extension BigSubstring {
  public struct UTF8View: Sendable {
    internal var _guts: _BSubstring.UTF8View

    internal init(_guts: _BSubstring.UTF8View) {
      self._guts = _guts
    }
  }

  public var utf8: UTF8View {
    UTF8View(_guts: _guts.utf8)
  }
}

@available(macOS 13.3, iOS 16.4, watchOS 9.4, tvOS 16.4, *)
extension BigString {
  public init?(_ utf8: BigSubstring.UTF8View) {
    guard let guts = _BString(utf8._guts) else { return nil }
    self.init(_guts: guts)
  }
}

@available(macOS 13.3, iOS 16.4, watchOS 9.4, tvOS 16.4, *)
extension BigSubstring.UTF8View {
  public var base: BigString.UTF8View {
    BigString.UTF8View(_guts: _guts.base)
  }
}

@available(macOS 13.3, iOS 16.4, watchOS 9.4, tvOS 16.4, *)
extension BigSubstring.UTF8View: Equatable {
  public static func ==(left: Self, right: Self) -> Bool {
    left._guts == right._guts
  }
}

@available(macOS 13.3, iOS 16.4, watchOS 9.4, tvOS 16.4, *)
extension BigSubstring.UTF8View: Hashable {
  public func hash(into hasher: inout Hasher) {
    _guts.hash(into: &hasher)
  }
}

@available(macOS 13.3, iOS 16.4, watchOS 9.4, tvOS 16.4, *)
extension BigSubstring.UTF8View: Sequence {
  public typealias Element = UInt8
  public typealias Iterator = _BSubstring.UTF8View.Iterator

  public func makeIterator() -> Iterator {
    _guts.makeIterator()
  }
}

@available(macOS 13.3, iOS 16.4, watchOS 9.4, tvOS 16.4, *)
extension BigSubstring.UTF8View: BidirectionalCollection {
  public typealias Index = BigString.Index
  public typealias SubSequence = Self

  public var startIndex: Index { Index(_guts.startIndex) }
  public var endIndex: Index { Index(_guts.endIndex) }
  public var count: Int { _guts.count }
  public func index(after i: Index) -> Index { Index(_guts.index(after: i._value)) }
  public func index(before i: Index) -> Index { Index(_guts.index(after: i._value)) }
  public func index(_ i: Index, offsetBy distance: Int) -> Index {
    Index(_guts.index(i._value, offsetBy: distance))
  }
  public func index(_ i: Index, offsetBy distance: Int, limitedBy limit: Index) -> Index? {
    _guts.index(i._value, offsetBy: distance, limitedBy: limit._value).map { Index($0) }
  }
  public func distance(from start: Index, to end: Index) -> Int {
    _guts.distance(from: start._value, to: end._value)
  }
  public subscript(position: Index) -> UInt8 {
    _guts[position._value]
  }
  public subscript(bounds: Range<Index>) -> Self {
    BigSubstring.UTF8View(_guts: _guts[bounds._base])
  }
}

@available(macOS 13.3, iOS 16.4, watchOS 9.4, tvOS 16.4, *)
extension BigSubstring.UTF8View {
  internal func index(roundingDown i: Index) -> Index {
    Index(_guts.index(roundingDown: i._value))
  }

  internal func index(roundingUp i: Index) -> Index {
    Index(_guts.index(roundingUp: i._value))
  }
}

#endif
