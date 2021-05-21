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

extension _BTree {
  /// Runs some operations on a BTree, ensuring it does not get deallocated in the process
  @_spi(Testing)
  public mutating func withSelf<R>(_ body: (inout _BTree) throws -> R) rethrows -> R {
    try body(&self)
  }
}
