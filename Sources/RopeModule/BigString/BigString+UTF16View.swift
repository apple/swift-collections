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
  public struct UTF16View {
    internal var _guts: _BString

    internal init(_guts: _BString) {
      self._guts = _guts
    }
  }

  public var utf16: UTF16View {
    get {
      UTF16View(_guts: _guts)
    }
    set {
      _guts = newValue._guts
    }
    _modify {
      var view = UTF16View(_guts: _guts)
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
  public init(_ content: UTF16View) {
    self._guts = content._guts
  }
}

@available(macOS 13.3, iOS 16.4, watchOS 9.4, tvOS 16.4, *)
extension BigString.UTF16View: CustomStringConvertible {
  public var description: String {
    var d = "<"
    d += self.lazy
      .map { String($0, radix: 16, uppercase: true)._lpad(to: 4, with: "0") }
      .joined(separator: " ")
    d += ">"
    return d
  }
}

@available(macOS 13.3, iOS 16.4, watchOS 9.4, tvOS 16.4, *)
extension BigString.UTF16View: Equatable {
  public static func ==(left: Self, right: Self) -> Bool {
    left._guts.utf8IsEqual(to: right._guts)
  }
}

@available(macOS 13.3, iOS 16.4, watchOS 9.4, tvOS 16.4, *)
extension BigString.UTF16View: Comparable {
  public static func <(left: Self, right: Self) -> Bool {
    left._guts.utf8IsLess(than: right._guts)
  }
}

@available(macOS 13.3, iOS 16.4, watchOS 9.4, tvOS 16.4, *)
extension BigString.UTF16View: Hashable {
  public func hash(into hasher: inout Hasher) {
    _guts.hashUTF8(into: &hasher)
  }
}

@available(macOS 13.3, iOS 16.4, watchOS 9.4, tvOS 16.4, *)
extension BigString.UTF16View: Sequence {
  public struct Iterator: IteratorProtocol {
    public typealias Element = UInt16

    internal var _base: _BString.UTF16Iterator

    internal init(_base: _BString.UTF16Iterator) {
      self._base = _base
    }

    public mutating func next() -> UInt16? {
      _base.next()
    }
  }

  public func makeIterator() -> Iterator {
    Iterator(_base: self._guts.makeUTF16Iterator())
  }
}

@available(macOS 13.3, iOS 16.4, watchOS 9.4, tvOS 16.4, *)
extension BigString.UTF16View: BidirectionalCollection {
  public typealias Index = BigString.Index
  public typealias Element = UInt16

  public var count: Int {
    _guts.utf16Count
  }

  public var startIndex: Index {
    Index(_guts.startIndex)
  }

  public var endIndex: Index {
    Index(_guts.endIndex)
  }

  public func index(after i: Index) -> Index {
    Index(_guts.utf16Index(after: i._value))
  }

  public func index(before i: Index) -> Index {
    Index(_guts.utf16Index(before: i._value))
  }

  public func index(_ i: Index, offsetBy distance: Int) -> Index {
    Index(_guts.utf16Index(i._value, offsetBy: distance))
  }

  public func distance(from start: Index, to end: Index) -> Int {
    _guts.utf16Distance(from: start._value, to: end._value)
  }

  public subscript(position: Index) -> UInt16 {
    _guts[utf16: position._value]
  }
}

#endif
