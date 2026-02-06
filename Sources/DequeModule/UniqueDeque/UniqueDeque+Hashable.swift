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

@available(SwiftStdlib 5.0, *)
extension UniqueDeque /*: Hashable */ where Element: Hashable /* & ~Copyable */ {
  @inlinable
  public func hash(into hasher: inout Hasher) {
    self._storage.hash(into: &hasher)
  }
}

#endif
