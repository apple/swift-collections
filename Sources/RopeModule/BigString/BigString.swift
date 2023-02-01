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

public struct BigString: Sendable {
  internal var _guts: _BString

  internal init(_guts: _BString) {
    self._guts = _guts
  }
  
  public init() {
    _guts = _BString()
  }
}

extension BigString: ExpressibleByStringLiteral {
  public init(stringLiteral value: String) {
    self.init(value)
  }
}

extension BigString: CustomStringConvertible, LosslessStringConvertible {
  public var description: String {
    String(_from: _guts)
  }
}

extension BigString: TextOutputStream {
  public mutating func write(_ string: String) {
    self.append(contentsOf: string)
  }
}

extension BigString {
  public func _invariantCheck() {
    _guts.invariantCheck()
  }
}

extension String {
  public init(_ big: BigString) {
    self.init(_from: big._guts)
  }

  public init(_ big: BigString.SubSequence) {
    self.init(_from: big.base._guts, in: big.startIndex._value ..< big.endIndex._value)
  }
}

extension String.UnicodeScalarView {
  public init(_ big: BigString.UnicodeScalarView) {
    self = String(_from: big._guts).unicodeScalars
  }

  public init(_ big: BigString.UnicodeScalarView.SubSequence) {
    self = String().unicodeScalars
  }
}
