//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Collections open source project
//
// Copyright (c) 2021 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
//
//===----------------------------------------------------------------------===//

extension Uniqued: Hashable where Element: Hashable {
  public func hash(into hasher: inout Hasher) {
    hasher.combine(count) // Discriminator
    for item in _elements {
      hasher.combine(item)
    }
  }
}
