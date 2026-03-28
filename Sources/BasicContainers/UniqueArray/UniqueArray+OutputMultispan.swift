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

#if compiler(>=6.2) && COLLECTIONS_UNSTABLE_CONTAINERS_PREVIEW

@available(SwiftStdlib 5.0, *)
extension UniqueArray where Element: ~Copyable {
  @_alwaysEmitIntoClient
  public mutating func append<E: Error>(
    addingCount newItemCount: Int,
    initializingWith initializer: @escaping (inout OutputMultispan<Element>) async throws(E) -> Void
  ) async throws(E) {
    _ensureFreeCapacity(newItemCount)
    return try await _storage.append(
      addingCount: newItemCount,
      initializingWith: initializer)
  }

  @inlinable
  public init<E: Error>(
    capacity: Int,
    initializingWith body: @escaping (inout OutputMultispan<Element>) async throws(E) -> Void
  ) async throws(E) {
    self.init(capacity: capacity)
    try await append(addingCount: capacity, initializingWith: body)
  }
}

#endif
