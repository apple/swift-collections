//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Collections open source project
//
// Copyright (c) 2026 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
//
//===----------------------------------------------------------------------===//

extension String {
  @_alwaysEmitIntoClient
  package func _lpad(_ width: Int, with character: Character = " ") -> Self {
    let c = count
    guard c < width else { return self }
    return String(repeating: character, count: width - c) + self
  }
  
  @_alwaysEmitIntoClient
  package func _rpad(_ width: Int, with character: Character = " ") -> Self {
    let c = count
    guard c < width else { return self }
    return self + String(repeating: character, count: width - c)
  }
  
  @_alwaysEmitIntoClient
  package func _cpad(_ width: Int, with character: Character = " ") -> Self {
    let c = count
    guard c < width else { return self }
    let l = String(repeating: character, count: (width - c + 1) / 2)
    let r = String(repeating: character, count: (width - c) / 2)
    return l + self + r
  }
}
