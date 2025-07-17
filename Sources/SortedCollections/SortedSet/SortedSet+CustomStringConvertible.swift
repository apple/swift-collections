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

#if !$Embedded
extension SortedSet: CustomStringConvertible, CustomDebugStringConvertible {
  @inlinable
  public var description: String {
    var result = "["
    var first = true
    for element in self {
      if first {
        first = false
      } else {
        result += ", "
      }
      print(element, terminator: "", to: &result)
    }
    result += "]"
    return result
  }
  
  @inlinable
  public var debugDescription: String {
    var result = "SortedSet<\(Element.self)>(["
    var first = true
    for element in self {
      if first {
        first = false
      } else {
        result += ", "
      }
      
      debugPrint(element, terminator: "", to: &result)
    }
    result += "])"
    return result
  }
}
#endif
