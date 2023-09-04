//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Collections open source project
//
// Copyright (c) 2023 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
//
//===----------------------------------------------------------------------===//

public struct RadixTree<Key: ConvertibleToOrderedBytes, Value> {
  var _tree: ARTree<Value>

  public init() {
    self._tree = ARTree<Value>()
  }
}

@available(macOS 13.3, iOS 16.4, watchOS 9.4, tvOS 16.4, *)
extension RadixTree {
  public mutating func insert(_ key: Key, _ value: Value) -> Bool {
    let k = key.toOrderedBytes()
    return _tree.insert(key: k, value: value)
  }

  public mutating func getValue(_ key: Key) -> Value? {
    let k = key.toOrderedBytes()
    return _tree.getValue(key: k)
  }

  public mutating func delete(_ key: Key) {
    let k = key.toOrderedBytes()
    _tree.delete(key: k)
  }
}

@available(macOS 13.3, iOS 16.4, watchOS 9.4, tvOS 16.4, *)
extension RadixTree: Sequence {
  public struct Iterator: IteratorProtocol {
    public typealias Element = (Key, Value)

    var _iter: ARTree<Value>.Iterator

    mutating public func next() -> Element? {
      guard let (k, v) = _iter.next() else { return nil }
      return (Key.fromOrderedBytes(k), v)
    }
  }

  public func makeIterator() -> Iterator {
    return Iterator(_iter: _tree.makeIterator())
  }
}
