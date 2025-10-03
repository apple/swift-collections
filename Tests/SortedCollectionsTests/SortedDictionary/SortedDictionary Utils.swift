//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Collections open source project
//
// Copyright (c) 2021 - 2025 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
//
//===----------------------------------------------------------------------===//

#if COLLECTIONS_UNSTABLE_SORTED_COLLECTIONS

import _CollectionsTestSupport
import SortedCollections

extension LifetimeTracker {
  func sortedDictionary<Keys: Sequence>(
    keys: Keys
  ) -> (
    dictionary: SortedDictionary<LifetimeTracked<Int>, LifetimeTracked<Int>>,
    kvs: [(LifetimeTracked<Int>, LifetimeTracked<Int>)]
  )
  where Keys.Element == Int
  {
    let k = Array(keys)
    let keys = self.instances(for: k)
    let values = self.instances(for: k.map { -($0 + 1) })
    
    let kvs = Array(zip(keys, values))
    
    let dictionary = SortedDictionary(keysWithValues: kvs)
    
    return (dictionary, kvs)
  }
}

#endif
