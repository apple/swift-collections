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

#if compiler(>=6.2)

#if !COLLECTIONS_SINGLE_MODULE
import InternalCollectionsUtilities
#endif

#if compiler(>=6.4)
@available(SwiftStdlib 6.4, *)
extension RigidDeque: Hashable where Element: Hashable & ~Copyable {
}

@available(SwiftStdlib 5.0, *)
extension RigidDeque where Element: Hashable & ~Copyable {
  @inlinable
  public func hash(into hasher: inout Hasher) {
    hasher.combine(self.count)
    let segments = self._handle.segments()
    segments.first.span._hashContents(into: &hasher)
    if let second = segments.second {
      second.span._hashContents(into: &hasher)
    }
  }
}
#else
@available(SwiftStdlib 5.0, *)
extension RigidDeque where Element: Hashable {
  @inlinable
  public func hash(into hasher: inout Hasher) {
    hasher.combine(self.count)
    let segments = self._handle.segments()
    segments.first.span._hashContents(into: &hasher)
    if let second = segments.second {
      second.span._hashContents(into: &hasher)
    }
  }
}
#endif

#endif
