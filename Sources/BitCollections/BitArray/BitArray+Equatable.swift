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

extension BitArray: Equatable {
  public static func ==(left: Self, right: Self) -> Bool {
    guard left._count == right._count else { return false }
    return left._storage == right._storage
  }
}
