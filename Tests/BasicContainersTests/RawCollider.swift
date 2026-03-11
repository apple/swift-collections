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

/// A type with precisely controlled hash values. This can be used to set up
/// hash tables with fully deterministic contents.
package struct RawCollider:
  Hashable, CustomStringConvertible
{
  package var identity: Int
  package var rawHashValue: Int

  package init(_ identity: Int, _ rawHashValue: Int) {
    self.identity = identity
    self.rawHashValue = rawHashValue
  }

  package init(_ identity: Int) {
    self.identity = identity
    self.rawHashValue = identity
  }

  package static func ==(left: Self, right: Self) -> Bool {
    guard left.identity == right.identity else { return false }
    precondition(left.rawHashValue == right.rawHashValue)
    return true
  }

  package var hashValue: Int {
    fatalError("Don't")
  }

  package func hash(into hasher: inout Hasher) {
    fatalError("Don't")
  }

  package func _rawHashValue(seed: Int) -> Int {
    rawHashValue
  }

  package var description: String {
    "\(identity)#\(rawHashValue)"
  }
}
