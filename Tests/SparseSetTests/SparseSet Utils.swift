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

import CollectionsTestSupport
import SparseSetModule

extension LifetimeTracker {
  func sparseSet<Keys: Sequence>(
    keys: Keys
  ) -> (
    sparseSet: SparseSet<Int, LifetimeTracked<Int>>,
    keys: [Int],
    values: [LifetimeTracked<Int>]
  )
  where Keys.Element == Int
  {
    let k = Array(keys)
    let values = self.instances(for: k)
    let sparseSet = SparseSet(uniqueKeys: k, values: values)
    return (sparseSet, k, values)
  }
}
