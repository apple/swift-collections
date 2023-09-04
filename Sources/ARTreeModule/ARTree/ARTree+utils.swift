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

extension ARTreeImpl {
  static func allocateLeaf(key: Key, value: Value) -> NodeStorage<NodeLeaf<Spec>> {
    return NodeLeaf<Spec>.allocate(key: key, value: value)
  }
}