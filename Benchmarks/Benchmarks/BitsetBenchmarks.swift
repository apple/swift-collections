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

import CollectionsBenchmark
import BitArrayModule

extension Benchmark {
  
  public mutating func addBitSetBenchmarks() {
    self.addSimple(
      title: "BitSet init from buffer",
      input: [Int].self
    ) { input in
      blackHole(BitSet(input))
    }
    
    self.add(
      title: "BitSet init from BitArray",
      input: [Int].self
    ) { input in
      let boolInput = input.toBoolArrayByEvens()
      let bitArray = BitArray(boolInput)
      return { timer in
        blackHole(BitSet(bitArray))
      }
    }
    
    self.add(
      title: "BitSet contains",
      input: [Int].self
    ) { input in
      let set = BitSet(input[0 ..< input.count / 2])
      return { timer in
        for value in 0 ..< input.count {
          blackHole(set.contains(value))
        }
      }
    }
    
    self.add(
      title: "BitSet contains (out of bounds)",
      input: [Int].self
    ) { input in
      let set = BitSet(input[0 ..< input.count / 2])
      return { timer in
        for value in input.count ..< input.count * 2 {
          precondition(!set.contains(value))
        }
      }
    }
    
    self.add(
      title: "BitSet insert",
      input: [Int].self
    ) { input in
      var set = BitSet(input[0 ..< input.count / 2])
      let insertVal = Int.random(in: 0...input.count)
      return { timer in
        blackHole(set.insert(insertVal))
      }
    }
    //NOTE TO SELF: do compare inserts
    self.add(
      title: "BitSet forceInsert",
      input: [Int].self
    ) { input in
      var set = BitSet(input[0 ..< input.count / 2])
      let insertVal = Int.random(in: 0...input.count)
      return { timer in
        blackHole(set.forceInsert(insertVal))
      }
    }
    
  }
}

extension Collection where Element == Int {
  fileprivate func toBoolArrayByEvens() -> [Bool] {
    var boolArray: [Bool] = []
    for element in self {
      if(element%2 == 0) {
        boolArray.append(true)
      } else {
        boolArray.append(false)
      }
    }
    return boolArray
  }
}

