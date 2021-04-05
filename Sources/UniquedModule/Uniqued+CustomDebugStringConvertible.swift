//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Collections open source project
//
// Copyright (c) 2021 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
//
//===----------------------------------------------------------------------===//

extension Uniqued: CustomDebugStringConvertible {
  public var debugDescription: String {
    _debugDescription(typeName: _debugTypeName())
  }

  internal func _debugTypeName() -> String {
    // Prefer the name "OrderedSet" when Base is a regular array.
    Base.self == [Element].self
      ? "OrderedSet<\(Element.self)>"
      : "Uniqued<\(Base.self)>"
  }

  internal func _debugDescription(typeName: String) -> String {
    var result = "\(typeName)(["
    var first = true
    for item in self {
      if first {
        first = false
      } else {
        result += ", "
      }
      debugPrint(item, terminator: "", to: &result)
    }
    result += "])"
    return result
  }
}
