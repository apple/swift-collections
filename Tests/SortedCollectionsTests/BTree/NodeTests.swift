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

#if DEBUG
import _CollectionsTestSupport
@_spi(Testing) @testable import SortedCollections

func nodeFromKeys(_ keys: [Int], capacity: Int) -> _Node<Int, Int> {
  let kvPairs = keys.map { (key: $0, value: $0 * 2) }
  return _Node<Int, Int>(_keyValuePairs: kvPairs, capacity: capacity)
}

func insertSortedValue(_ value: Int, into array: inout [Int]) {
  var insertionIndex = 0
  while insertionIndex < array.count {
    if array[insertionIndex] > value {
      break
    }
    insertionIndex += 1
  }
  array.insert(value, at: insertionIndex)
}

func findFirstIndexOf(_ value: Int, in array: [Int]) -> Int {
  var index = 0
  while index < array.count {
    if array[index] >= value {
      break
    }
    index += 1
  }
  return index
}

func findLastIndexOf(_ value: Int, in array: [Int]) -> Int {
  var index = 0
  while index < array.count {
    if array[index] > value {
      break
    }
    index += 1
  }
  return index
}

/// Generates all shifts of a duplicate run in a node of capacity N.
/// - Parameters:
///   - capacity: Total capacity of node.
///   - keys: The number filled keys in the node.
///   - duplicates: The number of duplicates. Must be greater than or equal to 1
/// - Returns: The duplicated key.
func withEveryNode(
  ofCapacity capacity: Int,
  keys: Int,
  duplicates: Int,
  _ body: (_Node<Int, Int>, [Int], Int) throws -> Void
) rethrows {
  let possibleShifts = keys - duplicates + 1
  try withEvery("shift", in: 0..<possibleShifts) { shift in
    let repeatedKey = shift
    
    var values = Array(0..<shift)
    values.append(contentsOf: repeatElement(repeatedKey, count: duplicates))
    values.append(contentsOf: (repeatedKey + 1)..<(repeatedKey + 1 + keys - values.count))
    
    
    let node = nodeFromKeys(values, capacity: capacity)
    
    try body(node, values, repeatedKey)
  }
}

final class NodeTests: CollectionTestCase {
  func test_singleNodeInsertion() {
    withEvery("capacity", in: 2..<10) { capacity in
      withEvery("count", in: 0..<capacity) { count in
        withEvery("position", in: 0...count) { position in
          
          let keys = (0..<count).map({ ($0 + 1) * 2 })
          
          var node = nodeFromKeys(keys, capacity: capacity)
          var array = Array(keys)
          
          let newKey = position * 2 + 1
          
          let splinter: _Node<Int, Int>.Splinter? = node.update { handle in
            let index = handle.endSlot(forKey: newKey)
            return handle.insertElement((newKey, newKey * 2), withRightChild: nil, atSlot: index)
          }
          insertSortedValue(newKey, into: &array)
          
          expectNil(splinter)
          node.read { handle in
            let keys = UnsafeBufferPointer(start: handle.keys, count: handle.elementCount)
            expectEqualElements(keys, array)
            expectEqual(handle.subtreeCount, count + 1)
          }
        }
      }
    }
  }
  
  func test_firstIndexOfDuplicates() {
    withEvery("capacity", in: 2..<10) { capacity in
      withEvery("keys", in: 0...capacity) { keys in
        withEvery("duplicates", in: 0...keys) { duplicates in
          withEveryNode(ofCapacity: capacity, keys: keys, duplicates: duplicates) { node, array, duplicatedKey  in
            node.read { handle in
              expectEqual(
                handle.startSlot(forKey: duplicatedKey),
                findFirstIndexOf(duplicatedKey, in: array)
              )
            }
          }
        }
      }
    }
  }
  
  func test_lastIndexOfDuplicates() {
    withEvery("capacity", in: 2..<10) { capacity in
      withEvery("keys", in: 0...capacity) { keys in
        withEvery("duplicates", in: 0...keys) { duplicates in
          withEveryNode(ofCapacity: capacity, keys: keys, duplicates: duplicates) { node, array, duplicatedKey  in
            node.read { handle in
              expectEqual(
                handle.endSlot(forKey: duplicatedKey),
                findLastIndexOf(duplicatedKey, in: array)
              )
            }
          }
        }
      }
    }
  }
}
#endif
