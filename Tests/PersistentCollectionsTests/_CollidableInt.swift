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

final class CollidableInt:
  CustomStringConvertible, CustomDebugStringConvertible, Equatable, Hashable
{
  let value: Int
  let _hashValue: Int
  
  init(_ value: Int) {
    self.value = value
    self._hashValue = value
  }
  
  init(_ value: Int, _ hashValue: Int) {
    self.value = value
    self._hashValue = hashValue
  }
  
  var description: String {
    return "\(value)"
  }
  
  var debugDescription: String {
    return "\(value) [hash = \(_hashValue)]"
  }

  func _rawHashValue(seed: Int) -> Int {
    _hashValue
  }
  
  func hash(into hasher: inout Hasher) {
    fatalError()
  }

  var hashValue: Int {
    fatalError()
  }
  
  static func == (lhs: CollidableInt, rhs: CollidableInt) -> Bool {
    if lhs.value == rhs.value {
      precondition(lhs._hashValue == rhs._hashValue)
      return true
    }
    return false
  }
}
