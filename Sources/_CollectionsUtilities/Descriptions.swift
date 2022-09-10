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

@inlinable
public func _arrayDescription<C: Collection>(
  for elements: C,
  typeName: String? = nil
) -> String {
  var result = ""
  if let typeName = typeName {
    result += "\(typeName)("
  }
  result += "["
  var first = true
  for item in elements {
    if first {
      first = false
    } else {
      result += ", "
    }
    print(item, terminator: "", to: &result)
  }
  result += "]"
  if typeName != nil { result += ")" }
  return result
}

@inlinable
public func _dictionaryDescription<Key, Value, C: Collection>(
  for elements: C,
  typeName: String? = nil
) -> String where C.Element == (key: Key, value: Value) {
  var result = ""
  if let typeName = typeName {
    result += "\(typeName)("
  }

  if elements.isEmpty {
    result += "[:]"
  } else {
    result += "["
    var first = true
    for (key, value) in elements {
      if first {
        first = false
      } else {
        result += ", "
      }
      result += "\(key): \(value)"
    }
    result += "]"
  }

  if typeName != nil {
    result += ")"
  }
  return result
}
