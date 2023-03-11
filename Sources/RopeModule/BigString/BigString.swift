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
public struct BigString: Sendable {
  internal var _guts: _BString

  internal init(_guts: _BString) {
    self._guts = _guts
  }
  
  public init() {
    _guts = _BString()
  }
}

@available(macOS 13.3, iOS 16.4, watchOS 9.4, tvOS 16.4, *)
extension BigString: ExpressibleByStringLiteral {
  public init(stringLiteral value: String) {
    self.init(value)
  }
}

@available(macOS 13.3, iOS 16.4, watchOS 9.4, tvOS 16.4, *)
extension BigString: CustomStringConvertible, LosslessStringConvertible {
  public var description: String {
    String(_from: _guts)
  }
}

@available(macOS 13.3, iOS 16.4, watchOS 9.4, tvOS 16.4, *)
extension BigString: TextOutputStream {
  public mutating func write(_ string: String) {
    self.append(contentsOf: string)
  }
}

@available(macOS 13.3, iOS 16.4, watchOS 9.4, tvOS 16.4, *)
extension BigString {
  public static var _minimumCapacity: Int { _BString.minimumCapacity }
  public static var _maximumCapacity: Int { _BString.maximumCapacity }

  public func _invariantCheck() {
    _guts.invariantCheck()
  }
}

@available(macOS 13.3, iOS 16.4, watchOS 9.4, tvOS 16.4, *)
extension String {
  public init(_ big: BigString) {
    self.init(_from: big._guts)
  }

  public init(_ big: BigString.SubSequence) {
    self.init(_from: big.base._guts, in: big.startIndex._value ..< big.endIndex._value)
  }
}

@available(macOS 13.3, iOS 16.4, watchOS 9.4, tvOS 16.4, *)
extension String.UnicodeScalarView {
  public init(_ big: BigString.UnicodeScalarView) {
    self = String(_from: big._guts._base).unicodeScalars
  }
}

@available(macOS 13.3, iOS 16.4, watchOS 9.4, tvOS 16.4, *)
extension Range<BigString.Index> {
  internal var _base: Range<_BString.Index> {
    Range<_BString.Index>(uncheckedBounds: (lowerBound._value, upperBound._value))
  }
}

#else

@available(*, unavailable, message: "BigString requires Swift 5.8")
public struct BigString: Sendable {}

#endif
