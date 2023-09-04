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

typealias PartialBytes = FixedArray8<UInt8>

struct InternalNodeHeader {
  var count: UInt16 = 0
  var partialLength: UInt8 = 0
  var partialBytes: PartialBytes = PartialBytes(repeating: 0)
}
