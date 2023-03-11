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
  public struct UTF8View {
    internal var _guts: _BString

    internal init(_guts: _BString) {
      self._guts = _guts
    }
  }

  public var utf8: UTF8View {
    get {
      UTF8View(_guts: _guts)
    }
    set {
      _guts = newValue._guts
    }
    _modify {
      var view = UTF8View(_guts: _guts)
      self._guts = .init()
      defer {
        self._guts = view._guts
      }
      yield &view
    }
  }
}

@available(macOS 13.3, iOS 16.4, watchOS 9.4, tvOS 16.4, *)
extension BigString {
  public init(_ content: UTF8View) {
    self._guts = content._guts
  }
}

@available(macOS 13.3, iOS 16.4, watchOS 9.4, tvOS 16.4, *)
extension BigString.UTF8View: CustomStringConvertible {
  public var description: String {
    var d = "<"
    d += self.lazy
      .map { String($0, radix: 16, uppercase: true)._lpad(to: 2, with: "0") }
      .joined(separator: " ")
    d += ">"
    return d
  }
}

@available(macOS 13.3, iOS 16.4, watchOS 9.4, tvOS 16.4, *)
extension BigString.UTF8View: Equatable {
  public static func ==(left: Self, right: Self) -> Bool {
    _BString.utf8IsEqual(left._guts, to: right._guts)
  }
}

@available(macOS 13.3, iOS 16.4, watchOS 9.4, tvOS 16.4, *)
extension BigString.UTF8View: Comparable {
  public static func <(left: Self, right: Self) -> Bool {
    left._guts.utf8IsLess(than: right._guts)
  }
}

@available(macOS 13.3, iOS 16.4, watchOS 9.4, tvOS 16.4, *)
extension BigString.UTF8View: Hashable {
  public func hash(into hasher: inout Hasher) {
    _guts.hashUTF8(into: &hasher)
  }
}

@available(macOS 13.3, iOS 16.4, watchOS 9.4, tvOS 16.4, *)
extension BigString.UTF8View: Sequence {
  public struct Iterator: IteratorProtocol {
    public typealias Element = UInt8

    internal var _base: _BString.UTF8Iterator

    internal init(_base: _BString.UTF8Iterator) {
      self._base = _base
    }

    public mutating func next() -> UInt8? {
      _base.next()
    }
  }

  public func makeIterator() -> Iterator {
    Iterator(_base: self._guts.makeUTF8Iterator())
  }
}

@available(macOS 13.3, iOS 16.4, watchOS 9.4, tvOS 16.4, *)
extension BigString.UTF8View: BidirectionalCollection {
  public typealias Index = BigString.Index
  public typealias Element = UInt8

  public var count: Int {
    _guts.utf8Count
  }

  public var startIndex: Index {
    Index(_guts.startIndex)
  }

  public var endIndex: Index {
    Index(_guts.endIndex)
  }

  public func index(after i: Index) -> Index {
    Index(_guts.utf8Index(after: i._value))
  }

  public func index(before i: Index) -> Index {
    Index(_guts.utf8Index(before: i._value))
  }

  public func index(_ i: Index, offsetBy distance: Int) -> Index {
    Index(_guts.utf8Index(i._value, offsetBy: distance))
  }

  public func distance(from start: Index, to end: Index) -> Int {
    _guts.utf8Distance(from: start._value, to: end._value)
  }

  public subscript(position: Index) -> UInt8 {
    _guts[utf8: position._value]
  }
}

#endif
