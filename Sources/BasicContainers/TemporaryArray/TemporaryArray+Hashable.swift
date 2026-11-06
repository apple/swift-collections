//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Collections open source project
//
// Copyright (c) 2026 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
//
// SPDX-License-Identifier: Apache-2.0 WITH Swift-exception
//
//===----------------------------------------------------------------------===//

#if compiler(>=6.3)

@available(SwiftStdlib 5.0, *)
extension TemporaryArray /*: Hashable FIXME: conform once Hashable supports ~Copyable & ~Escapable types */
where Element: Hashable /* & ~Copyable */ {
  @_alwaysEmitIntoClient
  public func hash(into hasher: inout Hasher) {
    hasher.combine(self.count)
    let span = self.span
    for i in 0 ..< count {
      hasher.combine(span[unchecked: i])
    }
  }
}

#endif
