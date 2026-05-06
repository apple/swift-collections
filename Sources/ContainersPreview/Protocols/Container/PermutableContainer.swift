//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Collections open source project
//
// Copyright (c) 2024 - 2026 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
//
// SPDX-License-Identifier: Apache-2.0 WITH Swift-exception
//
//===----------------------------------------------------------------------===//

#if compiler(>=6.4) && UnstableContainersPreview

@available(SwiftStdlib 5.0, *)
public protocol PermutableContainer<Element>: Container, ~Copyable, ~Escapable
where Element: ~Copyable
{
  @_lifetime(self: copy self)
  mutating func swapAt(_ i: Index, _ j: Index)
}

#endif
