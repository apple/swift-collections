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

#if compiler(>=6.2)
extension _HTable {
  @usableFromInline
  @frozen
  internal enum Variant: ~Copyable {
    case small(_HTable.Small)
    case large(_HTable)
  }

  @usableFromInline
  @frozen
  internal struct Small: ~Copyable {
    @_alwaysEmitIntoClient
    internal var count: Int
    
    @_transparent
    @_alwaysEmitIntoClient
    internal init() {
      self.count = 0
    }
  }
}
#endif
