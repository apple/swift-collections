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

internal struct Const {
  static let maxPartialLength = 8
  static var testCheckUnique = false
  static var testPrintRc = false
  static var testPrintAddr = false
}

public protocol ARTreeSpec {
  associatedtype Value
}

public struct DefaultSpec<_Value>: ARTreeSpec {
  public typealias Value = _Value
}
