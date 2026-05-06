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

#if !COLLECTIONS_SINGLE_MODULE
import InternalCollectionsUtilities
import ContainersPreview
#endif

#if compiler(>=6.4) && UnstableHashedContainers && UnstableContainersPreview

@available(SwiftStdlib 6.4, *)
extension UniqueSet: Hashable {}

@available(SwiftStdlib 5.0, *)
extension UniqueSet {
  @inlinable
  public func hash(into hasher: inout Hasher) {
    _storage.hash(into: &hasher)
  }
  
  @inlinable
  public func _rawHashValue(seed: Int) -> Int {
    _storage._rawHashValue(seed: seed)
  }
}

#endif
