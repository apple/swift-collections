//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Collections open source project
//
// Copyright (c) 2022 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
//
//===----------------------------------------------------------------------===//

#if false
extension PersistentDictionary {
  // TODO consider reworking similar to `PersistentDictionary.Iterator`
  // (would require a reversed variant of `KeyValueBuffer.Iterator`)
  public struct ReverseIterator {
    typealias DictionaryNode = BitmapIndexedDictionaryNode<Key, Value>
    private var baseIterator: _BaseReverseIterator<DictionaryNode>

    init(rootNode: DictionaryNode) {
      self.baseIterator = _BaseReverseIterator(rootNode: rootNode)
    }
  }
}

extension PersistentDictionary.ReverseIterator: IteratorProtocol {
  public mutating func next() -> (key: Key, value: Value)? {
    guard baseIterator.hasNext() else { return nil }

    let payload = baseIterator
      .currentValueNode!
      .getPayload(baseIterator.currentValueCursor)
    baseIterator.currentValueCursor -= 1

    return payload
  }
}
#endif