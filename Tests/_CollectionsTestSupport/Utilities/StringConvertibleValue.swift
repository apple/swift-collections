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

public struct StringConvertibleValue {
  public var value: Int
  public init(_ value: Int) { self.value = value }
}

extension StringConvertibleValue: ExpressibleByIntegerLiteral {
  public init(integerLiteral value: Int) {
    self.init(value)
  }
}

extension StringConvertibleValue: CustomStringConvertible {
  public var description: String {
    "description(\(value))"
  }
}

extension StringConvertibleValue: CustomDebugStringConvertible {
  public var debugDescription: String {
    "debugDescription(\(value))"
  }
}
