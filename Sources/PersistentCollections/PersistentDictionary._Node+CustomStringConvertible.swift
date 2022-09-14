//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Collections open source project
//
// Copyright (c) 2022 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
//
//===----------------------------------------------------------------------===//

extension PersistentDictionary._Node: CustomStringConvertible {
  @usableFromInline
  internal var description: String {
    guard count > 0 else {
      return "[:]"
    }
    
    var result = "["
    var first = true
    for (key, value) in _items {
      if first {
        first = false
      } else {
        result += ", "
      }
      result += "\(key): \(value)"
    }
    for node in _children {
      if first {
        first = false
      } else {
        result += ", "
      }
      result += "\(node.description)"
    }
    result += "]"
    return result
  }
}
