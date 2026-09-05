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

#if compiler(>=6.3)

#if compiler(>=6.4) && UnstableContainersPreview
@available(SwiftStdlib 5.0, *)
extension TemporaryArray: Equatable where Element: Equatable & ~Copyable {
  @_alwaysEmitIntoClient
  public static func ==(
    left: borrowing Self,
    right: borrowing Self
  ) -> Bool {
    left.span._elementsEqual(to: right.span)
  }
}
#else
@available(SwiftStdlib 5.0, *)
extension TemporaryArray where Element: Equatable {
  @_alwaysEmitIntoClient
  public static func ==(
    left: borrowing Self,
    right: borrowing Self
  ) -> Bool {
    left.span._elementsEqual(to: right.span)
  }
}
#endif

#endif
