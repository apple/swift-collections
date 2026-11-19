//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Collections open source project
//
// Copyright (c) 2026 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
//
// SPDX-License-Identifier: Apache-2.0 WITH Swift-exception
//
//===----------------------------------------------------------------------===//

import CollectionsBenchmark
import BasicContainers

extension Benchmark {
  public mutating func addUniqueDictionaryBenchmarks() {
#if compiler(>=6.4) && UnstableHashedContainers
    guard #available(SwiftStdlib 6.4, *) else { return }

    self.add(
      title: "UniqueDictionary<Int, Int> value(forKey:), successful lookups",
      input: ([Int], [Int]).self
    ) { input, lookups in
      var d = UniqueDictionary<Int, Int>(minimumCapacity: input.count)
      for i in input {
        d.insertValue(2 * i, forKey: i)
      }
      return { timer in
        for i in lookups {
          precondition(d.value(forKey: i)?.value == 2 * i)
        }
      }
    }

    self.add(
      title: "UniqueDictionary<Int, Int> value(forKey:), unsuccessful lookups",
      input: ([Int], [Int]).self
    ) { input, lookups in
      var d = UniqueDictionary<Int, Int>(minimumCapacity: input.count)
      for i in input {
        d.insertValue(2 * i, forKey: i)
      }
      let c = input.count
      return { timer in
        for i in lookups {
          precondition(d.value(forKey: i + c) == nil)
        }
      }
    }
#endif
  }
}
