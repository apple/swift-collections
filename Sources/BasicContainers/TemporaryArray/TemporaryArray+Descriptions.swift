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
extension TemporaryArray /*: CustomStringConvertible FIXME: conform once the protocol supports ~Copyable & ~Escapable types */
where Element: ~Copyable {
  @_alwaysEmitIntoClient
  public var description: String {
    // FIXME: Print the item descriptions when available.
    "<\(count) items>"
  }
}

@available(SwiftStdlib 5.0, *)
extension TemporaryArray /*: CustomDebugStringConvertible FIXME: conform once the protocol supports ~Copyable & ~Escapable types */
where Element: ~Copyable {
  @_alwaysEmitIntoClient
  public var debugDescription: String {
    // FIXME: Print the item descriptions when available.
    "<\(count) items>"
  }
}

#endif
