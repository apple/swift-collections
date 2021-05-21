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
@_spi(Testing) @testable import SortedCollections

final class SortedDictionaryTests: CollectionTestCase {
  func test_uniqueKeysAndValues() {
    withEvery("count", in: [0, 1, 2, 4, 8, 16, 32, 64, 128]) { count in
      let kvs = (0..<count).map { (key: $0, value: $0) }
      let sortedDictionary = SortedDictionary<Int, Int>(uniqueKeysWithValues: kvs)
      expectEqual(sortedDictionary.count, count)
    }
  }
  
  func test_orderedInsertion() {
    withEvery("count", in: [0, 1, 2, 3, 4, 8, 16, 64]) { count in
      var sortedDictionary: SortedDictionary<Int, Int> = [:]
      
      for i in 0..<count {
        sortedDictionary[i] = i * 2
      }
      
      expectEqual(sortedDictionary.count, count)
      expectEqual(sortedDictionary.underestimatedCount, count)
      expectEqual(sortedDictionary.isEmpty, count == 0)
      
      for i in 0..<count {
        expectEqual(sortedDictionary[i], i * 2)
      }
    }
  }
  
  func test_reversedInsertion() {
    withEvery("count", in: [0, 1, 2, 3, 4, 8, 16, 64]) { count in
      var sortedDictionary: SortedDictionary<Int, Int> = [:]
      
      for i in (0..<count).reversed() {
        sortedDictionary[i] = i * 2
      }
      
      expectEqual(sortedDictionary.count, count)
      expectEqual(sortedDictionary.underestimatedCount, count)
      expectEqual(sortedDictionary.isEmpty, count == 0)
      
      for i in 0..<count {
        expectEqual(sortedDictionary[i], i * 2)
      }
    }
  }
  
  func test_arbitraryInsertion() {
    withEvery("count", in: [0, 1, 2, 3, 4, 8, 16, 64]) { count in
      for i in 0...count {
        let kvs = (0..<count).map { (key: $0 * 2 + 1, value: $0) }
        var sortedDictionary = SortedDictionary<Int, Int>(uniqueKeysWithValues: kvs)
        sortedDictionary[i * 2] = -i
        
        var comparison = Array(kvs)
        comparison.insert((key: i * 2, value: -i), at: i)
        
        expectEqualElements(comparison, sortedDictionary)
      }
    }
  }
  
  func test_updateValue() {
    withEvery("count", in: [1, 2, 4, 8, 16, 32, 64]) { count in
      var sortedDictionary: SortedDictionary<Int, Int> = [:]
      
      for i in 0..<count {
        sortedDictionary[i] = i
        sortedDictionary[i] = -sortedDictionary[i]!
      }
      
      for i in 0..<count {
        expectEqual(sortedDictionary[i], -i)
      }
    }
  }
}
