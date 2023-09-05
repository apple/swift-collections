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

public struct RadixTree<Key: ConvertibleToBinaryComparableBytes, Value> {
  var _tree: ARTree<Value>

  public init() {
    self._tree = ARTree<Value>()
  }
}

@available(macOS 13.3, iOS 16.4, watchOS 9.4, tvOS 16.4, *)
extension RadixTree {
  /// Creates a Radix Tree collection from a sequence of key-value pairs.
  ///
  /// If duplicates are encountered the last instance of the key-value pair is the one
  /// that is kept.
  ///
  /// - Parameter keysAndValues: A sequence of key-value pairs to use
  ///     for the new Radix Tree.
  /// - Complexity: O(?)
  @inlinable
  @inline(__always)
  public init<S>(
    keysWithValues keysAndValues: S
  ) where S: Sequence, S.Element == (key: Key, value: Value) {
    self.init()

    for (key, value) in keysAndValues {
      _ = self.insert(key, value)
    }
  }
}

@available(macOS 13.3, iOS 16.4, watchOS 9.4, tvOS 16.4, *)
extension RadixTree {
  public mutating func insert(_ key: Key, _ value: Value) -> Bool {
    let k = key.toBinaryComparableBytes()
    return _tree.insert(key: k, value: value)
  }

  public func getValue(_ key: Key) -> Value? {
    let k = key.toBinaryComparableBytes()
    return _tree.getValue(key: k)
  }

  public mutating func delete(_ key: Key) {
    let k = key.toBinaryComparableBytes()
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
      return (Key.fromBinaryComparableBytes(k), v)
    }
  }

  public func makeIterator() -> Iterator {
    return Iterator(_iter: _tree.makeIterator())
  }
}
