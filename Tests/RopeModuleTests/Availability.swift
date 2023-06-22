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

var isRunningOnSwiftStdlib5_8: Bool {
  if #available(macOS 13.3, iOS 16.4, watchOS 9.4, tvOS 16.4, xrOS 1.0, *) {
    return true
  }
  return false
}


#if swift(<5.8)
extension String.Index {
  var _description: String {
    let raw = unsafeBitCast(self, to: UInt64.self)
    let encodedOffset = Int(truncatingIfNeeded: raw &>> 16)
    let transcodedOffset = Int(truncatingIfNeeded: (raw &>> 14) & 0x3)
    var d = "\(encodedOffset)[unknown]"
    if transcodedOffset > 0 {
      d += "+\(transcodedOffset)"
    }
    return d
  }
}
#endif
