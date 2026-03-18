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

#if compiler(>=6.4) && COLLECTIONS_UNSTABLE_HASHED_CONTAINERS

@available(SwiftStdlib 5.0, *)
extension UniqueDictionary where Key: ~Copyable, Value: ~Copyable {
  @inlinable
  public init() {
    self.init(_storage: .init())
  }
  
  @inlinable
  public init(minimumCapacity: Int) {
    let table = _HTable(minimumCapacity: minimumCapacity)
    self.init(_storage: RigidDictionary(_table: table))
  }
  
  @inlinable
  public init(consuming set: consuming RigidDictionary<Key, Value>) {
    self.init(_storage: set)
  }
}

#endif
