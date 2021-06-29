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

import Collections
import CollectionsBenchmark

let bigString = String(repeating: "aksldf👩‍👩‍👧‍👧zxcv👩‍👩‍👧‍👦", count: 40_000)
let bigArray = Array(bigString)

extension Benchmark {
  public mutating func addZipBenchmarks() {
    self.addSimple(
      title: "ZipCollection<Range<Int>, String>",
      input: Int.self
    ) { size in
      let z = zipC(0..<size, bigString)
      let c = z.suffix(2).lazy.map(\.0).reduce(0, +)
      blackHole(c)
    }

    self.addSimple(
      title: "ZipDispatch<Range<Int>, String>",
      input: Int.self
    ) { size in
      let z = zipDispatch(0..<size, bigString)
      let c = z.suffix(2).lazy.map(\.0).reduce(0, +)
      blackHole(c)
    }
    
    self.addSimple(
      title: "ZipCollection<Range<Int>, String> (Nested x4)",
      input: Int.self
    ) { size in
      let z = zipC(0..<size,
                   zipC(0..<size,
                        zipC(0..<size,
                             zipC(0..<size, bigString))))
      let c = z.suffix(2).lazy.map(\.0).reduce(0, +)
      blackHole(c)
    }
    
    self.addSimple(
      title: "ZipDispatch<Range<Int>, String> (Nested x4)",
      input: Int.self
    ) { size in
      let z = zipDispatch(0..<size,
                         zipDispatch(0..<size,
                                    zipDispatch(0..<size,
                                               zipDispatch(0..<size, bigString))))
      let c = z.suffix(2).lazy.map(\.0).reduce(0, +)
      blackHole(c)
    }

    self.addSimple(
      title: "ZipRAC<Range<Int>, Array<Character>>",
      input: Int.self
    ) { size in
      let z = zipRAC(0..<size, bigArray)
      let c = z.suffix(2).lazy.map(\.0).reduce(0, +)
      blackHole(c)
    }

    self.addSimple(
      title: "ZipRAC<Range<Int>, String> (bad case)",
      input: Int.self
    ) { size in
      let z = zipRAC(0..<size, bigString)
      let c = z.suffix(2).lazy.map(\.0).reduce(0, +)
      blackHole(c)
    }

    self.addSimple(
      title: "ZipDispatch<Range<Int>, Array<Character>>",
      input: Int.self
    ) { size in
      let z = zipDispatch(0..<size, bigArray)
      let c = z.suffix(2).lazy.map(\.0).reduce(0, +)
      blackHole(c)
    }

    self.addSimple(
      title: "ZipRAC<Range<Int>, Array<Character>> (Nested x4)",
      input: Int.self
    ) { size in
      let z = zipRAC(0..<size,
                     zipRAC(0..<size,
                            zipRAC(0..<size,
                                   zipRAC(0..<size, bigArray))))
      let c = z.suffix(2).lazy.map(\.0).reduce(0, +)
      blackHole(c)
    }

    self.addSimple(
      title: "ZipDispatch<Range<Int>, Array<Character>> (Nested x4)",
      input: Int.self
    ) { size in
      let z = zipDispatch(0..<size,
                          zipDispatch(0..<size,
                                      zipDispatch(0..<size,
                                                  zipDispatch(0..<size, bigArray))))
      let c = z.suffix(2).lazy.map(\.0).reduce(0, +)
      blackHole(c)
    }

  }
}
