//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Collections open source project
//
// Copyright (c) 2026 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
//
//===----------------------------------------------------------------------===//

#if COLLECTIONS_SINGLE_MODULE
import Collections
#else
import _CollectionsTestSupport
import ContainersPreview
import SpanPreview
#endif

#if compiler(>=6.4) && UnstableContainersPreview

import Testing

struct E: Error {}
nonisolated(unsafe) var issue770Inits = 0
nonisolated(unsafe) var issue770Deinits = 0
nonisolated(unsafe) var issue770PerValue = [Int](repeating: 0, count: 10)

struct Issue770Tok: ~Copyable {
  let v: Int
  init(_ v: Int) { issue770Inits += 1 }
  deinit { issue770Deinits += 1; issue770PerValue[v] += 1 }
}

@Suite("Issue 770 Double Destroy")
struct Issue770DoubleDestroyTests {
  @Test("Reduce throws: elements destroyed exactly once")
  func reduceThrowsDestroysOnce() throws {
    issue770Inits = 0; issue770Deinits = 0
    issue770PerValue = [Int](repeating: 0, count: 10)

    do {
      _ = try producer(state: 0) { (s: inout Int) throws(E) -> Issue770Tok? in
        guard s < 10 else { return nil }; defer { s += 1 }; return Issue770Tok(s)
      }.reduce(0) { (acc: consuming Int, x: consuming Issue770Tok) throws(E) -> Int in
        if x.v == 2 { throw E() }
        return acc + x.v
      }
    } catch {}

    #expect(issue770Inits == 8)
    #expect(issue770Deinits == 8)
    #expect(issue770PerValue == [1, 1, 1, 1, 1, 1, 1, 1, 0, 0])
  }
}

#endif
