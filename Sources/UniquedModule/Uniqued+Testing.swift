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

extension _Bucket: CustomStringConvertible {
  public var description: String { "Bucket(@\(offset))"}
}

extension _UnsafeHashTable: CustomStringConvertible {
  public var description: String {
    var d = """
      _UnsafeHashTable\(_header.pointee._description)
        load factor: \(debugLoadFactor())
      """
    if bucketCount < 128 {
      d += "\n  "
      d += debugContents()
        .lazy
        .map { $0 == nil ? "_" : "\($0!)" }
        .joined(separator: " ")
    }
    return d
  }

  internal func debugOccupiedCount() -> Int {
    var count = 0
    var it = bucketIterator(startingAt: _Bucket(offset: 0))
    repeat {
      if it.isOccupied {
        count += 1
      }
      it.advance()
    } while it.currentBucket.offset != 0
    return count
  }

  internal func debugLoadFactor() -> Double {
    return Double(debugOccupiedCount()) / Double(bucketCount)
  }

  internal func debugContents() -> [Int?] {
    var result: [Int?] = []
    result.reserveCapacity(bucketCount)
    var it = bucketIterator(startingAt: _Bucket(offset: 0))
    repeat {
      result.append(it.currentValue)
      it.advance()
    } while it.currentBucket.offset != 0
    return result
  }
}

extension _UnsafeHashTable.BucketIterator: CustomStringConvertible {
  var description: String {
    func pad(_ s: String, to length: Int, by padding: Character = " ") -> String {
      let c = s.count
      guard c < length else { return s }
      return String(repeating: padding, count: length - c) + s
    }
    let offset = pad(String(_currentBucket.offset), to: 4)
    let value: String
    if let v = currentValue {
      value = pad(String(v), to: 4)
    } else {
      value = " nil"
    }
    let remainingBits = pad(String(_nextBits, radix: 2), to: _remainingBitCount, by: "0")
    return "BucketIterator(scale: \(_scale), bucket: \(offset), value: \(value), bits: \(remainingBits) (\(_remainingBitCount) bits))"
  }
}

extension Uniqued {
  @_spi(Testing) public var _hasHashTable: Bool { _storage != nil }

  @_spi(Testing) public var _hashTableIdentity: ObjectIdentifier? {
    guard let storage = _storage else { return nil }
    return ObjectIdentifier(storage)
  }

  @_spi(Testing) public var _hashTableContents: [Int?] {
    _storage!.read { hashTable in
      hashTable.debugContents()
    }
  }

  @_spi(Testing) mutating public func _regenerateHashTable(bias: Int) {
    _ensureUnique()
    let new = _storage!.copy()
    _storage!.read { source in
      new.update { target in
        target.bias = bias
        var it = source.bucketIterator(startingAt: _Bucket(offset: 0))
        repeat {
          target[it.currentBucket] = it.currentValue
          it.advance()
        } while it.currentBucket.offset != 0
      }
    }
    _storage = new
  }
}

extension Uniqued {
  @_spi(Testing) public init(
    _scale scale: Int,
    bias: Int,
    contents: Base
  ) {
    precondition(scale >= _UnsafeHashTable.scale(forCapacity: contents.count))
    precondition(scale <= _UnsafeHashTable.maximumScale)
    precondition(bias >= 0 && _UnsafeHashTable.biasRange(scale: scale).contains(bias))
    precondition(scale >= _UnsafeHashTable.minimumScale || bias == 0)
    let storage = _HashTableStorage.create(scale: Swift.max(scale, _UnsafeHashTable.minimumScale))
    storage.header.bias = bias
    let (success, index) = storage.update { hashTable in
      hashTable.fill(from: contents, stoppingOnFirstDuplicateValue: true)
    }
    precondition(success, "Duplicate element at index \(index)")
    _storage = scale < _UnsafeHashTable.minimumScale ? nil : storage
    _elements = contents
    precondition(self._scale == scale)
    precondition(self._bias == bias)
  }
}

extension Uniqued where Base: RangeReplaceableCollection {
  @_spi(Testing) public init<C: Collection>(
    _scale scale: Int,
    bias: Int,
    contents: C
  ) where C.Element == Element {
    self.init(_scale: scale, bias: bias, contents: Base(contents))
  }
}
