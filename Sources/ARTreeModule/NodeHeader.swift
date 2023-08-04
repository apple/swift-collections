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

typealias PartialBytes = FixedSizedArray8<UInt8>

struct NodeHeader {
  var type: NodeType
  var count: UInt16 = 0  // TODO: Make it smaller. Node256 issue.
  var partialLength: UInt8 = 0
  var partialBytes: PartialBytes = PartialBytes(val: 0)

  init(_ type: NodeType) {
    self.type = type
  }
}
