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

import ContainersPreview

#if compiler(>=6.4) && UnstableContainersPreview
@available(SwiftStdlib 6.4, *)
extension Container
where
  Self: ~Copyable & ~Escapable,
  Element: ~Copyable
{
  @_alwaysEmitIntoClient
  package func _index(atOffset offset: Int) -> Index {
    self.index(self.startIndex, offsetBy: offset)
  }
}
#endif
