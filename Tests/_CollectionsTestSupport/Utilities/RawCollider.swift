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
  package var hash: Hash

  package init(_ identity: Int, _ hash: Hash) {
    self.identity = identity
    self.hash = hash
  }

  package init(_ identity: Int, _ rawHashValue: Int) {
    self.identity = identity
    self.hash = Hash(rawHashValue)
  }

  package init(_ identity: Int) {
    self.identity = identity
    self.hash = Hash(identity)
  }

  package init(_ identity: String) {
    self.hash = Hash(identity)!
    self.identity = hash.value
  }

  package static func ==(left: Self, right: Self) -> Bool {
    guard left.identity == right.identity else { return false }
    precondition(left.hash == right.hash)
    return true
  }

  package var hashValue: Int {
    fatalError("Don't")
  }

  package func hash(into hasher: inout Hasher) {
    fatalError("Don't")
  }

  package func _rawHashValue(seed: Int) -> Int {
    hash.value
  }

  package var description: String {
    "\(identity)#\(hash)"
  }
}
