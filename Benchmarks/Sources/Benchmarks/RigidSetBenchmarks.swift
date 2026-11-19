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
  public mutating func addRigidSetBenchmarks() {
#if compiler(>=6.4) && UnstableHashedContainers
    self.add(
      title: "RigidSet<Int> successful contains",
      input: ([Int], [Int]).self
    ) { input, lookups in
      var set = RigidSet<Int>(capacity: input.count)
      for i in input {
        set.insert(i)
      }
      return { timer in
        for i in lookups {
          precondition(set.contains(i))
        }
      }
    }

    self.add(
      title: "RigidSet<Int> unsuccessful contains",
      input: ([Int], [Int]).self
    ) { input, lookups in
      var set = RigidSet<Int>(capacity: input.count)
      for i in input {
        set.insert(i)
      }
      let lookups = lookups.map { $0 + input.count }
      return { timer in
        for i in lookups {
          precondition(!set.contains(i))
        }
      }
    }
#endif
  }
}
