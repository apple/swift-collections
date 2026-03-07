//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Collections open source project
//
// Copyright (c) 2014 - 2026 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
//
// SPDX-License-Identifier: Apache-2.0 WITH Swift-exception
//
//===----------------------------------------------------------------------===//

public final class HashableBox<T: Hashable>: Hashable {
  public init(_ value: T) { self.value = value }
  public var value: T

  public static func ==(left: HashableBox, right: HashableBox) -> Bool {
    left.value == right.value
  }

  public func hash(into hasher: inout Hasher) {
    hasher.combine(value)
  }
}
