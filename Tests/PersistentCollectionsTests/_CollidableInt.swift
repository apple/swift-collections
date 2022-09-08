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
  let hashValue: Int
  
  init(_ value: Int) {
    self.value = value
    self.hashValue = value
  }
  
  init(_ value: Int, _ hashValue: Int) {
    self.value = value
    self.hashValue = hashValue
  }
  
  var description: String {
    return "\(value)"
  }
  
  var debugDescription: String {
    return "\(value) [hash = \(hashValue)]"
  }
  
  func hash(into hasher: inout Hasher) {
    hasher.combine(hashValue)
  }
  
  static func == (lhs: CollidableInt, rhs: CollidableInt) -> Bool {
    if lhs.value == rhs.value {
      precondition(lhs.hashValue == rhs.hashValue)
      return true
    }
    return false
  }
}
