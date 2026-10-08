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

extension _HashTable.Bucket: CustomStringConvertible {
  // A textual representation of this instance.
  public var description: String { "Bucket(@\(offset))"}
}

extension _UnsafeHashTable {
  package func debugOccupiedCount() -> Int {
    var count = 0
    var it = unsafe bucketIterator(startingAt: Bucket(offset: 0))
    repeat {
      if it.isOccupied {
        count += 1
      }
      unsafe it.advance()
    } while it.currentBucket.offset != 0
    return count
  }

  package func debugLoadFactor() -> Double {
    return unsafe Double(debugOccupiedCount()) / Double(bucketCount)
  }

  package func debugContents() -> [Int?] {
    var result: [Int?] = []
    result.reserveCapacity(unsafe bucketCount)
    var it = unsafe bucketIterator(startingAt: Bucket(offset: 0))
    repeat {
      unsafe result.append(it.currentValue)
      unsafe it.advance()
    } while  it.currentBucket.offset != 0
    return result
  }
}

extension _UnsafeHashTable.BucketIterator: CustomStringConvertible {
  @usableFromInline
  package var description: String {
    func pad(_ s: String, to length: Int, by padding: Character = " ") -> String {
      let c = s.count
      guard c < length else { return s }
      return String(repeating: padding, count: length - c) + s
    }
    let offset = pad(String(_currentBucket.offset), to: 4)
    let value: String
    if let v = unsafe currentValue {
      value = pad(String(v), to: 4)
    } else {
      value = " nil"
    }
    let remainingBits = pad(String(_nextBits, radix: 2), to: _remainingBitCount, by: "0")
    return "BucketIterator(scale: \(unsafe _scale), bucket: \(offset), value: \(value), bits: \(remainingBits) (\(_remainingBitCount) bits))"
  }
}
