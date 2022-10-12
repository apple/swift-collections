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

extension BitArray: CustomStringConvertible {
  // A textual representation of this instance.
  public var description: String {
    _bitString
  }

  internal var _bitString: String {
    var result: String
    if #available(macOS 11.0, iOS 14.0, watchOS 7.0, tvOS 14.0, *) {
      result = String(unsafeUninitializedCapacity: self.count) { target in
        let b0: UInt8 = 48 // ASCII 0
        let b1: UInt8 = 49 // ASCII 1
        var i = 0
        for v in self {
          target.initializeElement(at: i, to: v ? b1 : b0)
          i &+= 1
        }
        return i
      }
    } else {
      result = ""
      result.reserveCapacity(self.count)
      for v in self {
        result.append(v ? "1" : "0")
      }
    }
    if result.isEmpty { result = "0" }
    return result
  }
}
