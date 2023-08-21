//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Collections open source project
//
// Copyright (c) 2023 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
//
//===----------------------------------------------------------------------===//

struct Const {
  static let maxPartialLength = 8
}

public protocol ARTreeSpec {
  associatedtype Value
}

public struct DefaultSpec<_Value>: ARTreeSpec {
  public typealias Value = _Value
}
