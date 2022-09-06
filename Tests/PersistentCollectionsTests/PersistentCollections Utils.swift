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

import _CollectionsTestSupport
import PersistentCollections

extension LifetimeTracker {
  func persistentDictionary<Keys: Sequence>(
    keys: Keys
  ) -> (
    dictionary: PersistentDictionary<LifetimeTracked<Int>, LifetimeTracked<Int>>,
    keys: [LifetimeTracked<Int>],
    values: [LifetimeTracked<Int>]
  )
  where Keys.Element == Int
  {
    let k = Array(keys)
    let keys = self.instances(for: k)
    let values = self.instances(for: k.map { $0 + 100 })
    let dictionary = PersistentDictionary(uniqueKeys: keys, values: values)
    return (dictionary, keys, values)
  }
}
