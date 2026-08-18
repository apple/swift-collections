//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Collections open source project
//
// Copyright (c) 2021 - 2026 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
//
// SPDX-License-Identifier: Apache-2.0 WITH Swift-exception
//
//===----------------------------------------------------------------------===//

import CollectionsBenchmark
import BitCollections

extension Benchmark {

  public mutating func addBitArrayBenchmarks() {
    self.add(
      title: "BitArray fill(with: true)",
      input: Int.self
    ) { input in
      guard input > 0 else { return nil }
      return { timer in
        var a = BitArray(repeating: false, count: input)
        timer.measure {
          a.fill(with: true)
        }
        blackHole(a)
      }
    }

    self.add(
      title: "BitArray init(repeating: true, count:)",
      input: Int.self
    ) { input in
      guard input > 0 else { return nil }
      return { timer in
        timer.measure {
          blackHole(BitArray(repeating: true, count: input))
        }
      }
    }

    self.add(
      title: "BitArray append(repeating: true, count:)",
      input: Int.self
    ) { input in
      guard input > 0 else { return nil }
      return { timer in
        var a = BitArray()
        a.reserveCapacity(input)
        timer.measure {
          a.append(repeating: true, count: input)
        }
        blackHole(a)
      }
    }

    self.add(
      title: "BitArray insert(repeating: true, count:at:)",
      input: Int.self
    ) { input in
      guard input > 0 else { return nil }
      return { timer in
        var a = BitArray(repeating: false, count: 64)
        timer.measure {
          a.insert(repeating: true, count: input, at: 32)
        }
        blackHole(a)
      }
    }

    self.add(
      title: "BitArray truncateOrExtend(toCount:with: true)",
      input: Int.self
    ) { input in
      guard input > 0 else { return nil }
      return { timer in
        var a = BitArray()
        a.reserveCapacity(input)
        timer.measure {
          a.truncateOrExtend(toCount: input, with: true)
        }
        blackHole(a)
      }
    }
  }
}
