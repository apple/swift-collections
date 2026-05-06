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

#if compiler(>=6.4) && UnstableHashedContainers

@available(SwiftStdlib 5.0, *)
extension UniqueDictionary: Hashable where Value: Hashable {
  @inlinable
  @inline(__always)
  public func hash(into hasher: inout Hasher) {
    self._storage.hash(into: &hasher)
  }
}

#endif
