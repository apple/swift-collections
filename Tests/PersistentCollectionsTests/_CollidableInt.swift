//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Collections open source project
//
// Copyright (c) 2021 - 2022 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
//
//===----------------------------------------------------------------------===//

extension Int {
  public init(hashString: String) {
    let s = String(hashString.reversed())
    let hash = UInt(s, radix: 32)!
    self = Int(bitPattern: hash)
  }
}

public final class CollidableInt:
  CustomStringConvertible, CustomDebugStringConvertible, Equatable, Hashable
{
  public let value: Int
  let _hashValue: Int
  
  public init(_ value: Int) {
    self.value = value
    self._hashValue = value
  }
  
  public init(_ value: Int, _ hashValue: Int) {
    self.value = value
    self._hashValue = hashValue
  }

  public init(_ value: Int, _ hashString: String) {

    self.value = value
    self._hashValue = Int(hashString: hashString)
  }

  public var description: String {
    return "\(value)"
  }
  
  public var debugDescription: String {
    return "\(value) [hash = \(_hashValue)]"
  }

  public func _rawHashValue(seed: Int) -> Int {
    _hashValue
  }
  
  public func hash(into hasher: inout Hasher) {
    fatalError()
  }

  public var hashValue: Int {
    fatalError()
  }
  
  public static func == (lhs: CollidableInt, rhs: CollidableInt) -> Bool {
    if lhs.value == rhs.value {
      precondition(lhs._hashValue == rhs._hashValue)
      return true
    }
    return false
  }
}
