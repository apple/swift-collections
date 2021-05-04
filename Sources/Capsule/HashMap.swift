//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Collections open source project
//
// Copyright (c) 2019 - 2021 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
//
//===----------------------------------------------------------------------===//

public struct HashMap<Key, Value> where Key : Hashable {
    let rootNode: BitmapIndexedMapNode<Key, Value>
    let cachedKeySetHashCode: Int
    let cachedSize: Int
    
    fileprivate init(_ rootNode: BitmapIndexedMapNode<Key, Value>, _ cachedKeySetHashCode: Int, _ cachedSize: Int) {
        self.rootNode = rootNode
        self.cachedKeySetHashCode = cachedKeySetHashCode
        self.cachedSize = cachedSize
    }
    
    public init() {
        self.init(BitmapIndexedMapNode(0, 0, Array()), 0, 0)
    }
    
    public init(_ map: HashMap<Key, Value>) {
        self.init(map.rootNode, map.cachedKeySetHashCode, map.cachedSize)
    }

    ///
    /// Inspecting a Dictionary
    ///
    
    var isEmpty: Bool { cachedSize == 0 }
    
    public var count: Int { cachedSize }
    
    var capacity: Int { count }
    
    ///
    /// Accessing Keys and Values
    ///

    public subscript(_ key: Key) -> Value? {
        get {
            return get(key)
        }
        mutating set(optionalValue) {
            if let value = optionalValue {
                self = insert(key: key, value: value)
            } else {
                self = delete(key)
            }
        }
    }
    
    public subscript(_ key: Key, default: () -> Value) -> Value {
        return get(key) ?? `default`()
    }
    
    public func contains(_ key: Key) -> Bool {
        rootNode.containsKey(key, computeHash(key), 0)
    }
    
    public func get(_ key: Key) -> Value? {
        rootNode.get(key, computeHash(key), 0)
    }
    
    public func insert(key: Key, value: Value) -> Self {
        var effect = MapEffect()
        let keyHash = computeHash(key)
        let newRootNode = rootNode.updated(key, value, keyHash, 0, &effect)

        if (effect.modified) {
            if (effect.replacedValue) {
                return Self(newRootNode, cachedKeySetHashCode, cachedSize)
            } else {
                return Self(newRootNode, cachedKeySetHashCode ^ keyHash, cachedSize + 1)
            }
        } else { return self }
    }

    public func delete(_ key: Key) -> Self {
        var effect = MapEffect()
        let keyHash = computeHash(key)
        let newRootNode = rootNode.removed(key, keyHash, 0, &effect)

        if (effect.modified) {
            return Self(newRootNode, cachedKeySetHashCode ^ keyHash, cachedSize - 1)
        } else { return self }
    }
}

fileprivate let EmptyMapNode = BitmapIndexedMapNode<AnyHashable, Any>(0, 0, Array())

public struct MapKeyValueTupleIterator<Key : Hashable, Value> {
    private var baseIterator: ChampBaseIterator<BitmapIndexedMapNode<Key, Value>>
    
    init(rootNode: BitmapIndexedMapNode<Key, Value>) {
        self.baseIterator = ChampBaseIterator(rootNode: rootNode)
    }
}

extension MapKeyValueTupleIterator : IteratorProtocol {
    public mutating func next() -> (Key, Value)? {
        guard baseIterator.hasNext() else { return nil }

        let payload = baseIterator.currentValueNode?.getPayload(baseIterator.currentValueCursor)
        baseIterator.currentValueCursor += 1

        return payload
    }
}

public struct MapKeyValueTupleReverseIterator<Key : Hashable, Value> {
    private var baseIterator: ChampBaseReverseIterator<BitmapIndexedMapNode<Key, Value>>
    
    init(rootNode: BitmapIndexedMapNode<Key, Value>) {
        self.baseIterator = ChampBaseReverseIterator(rootNode: rootNode)
    }
}

extension MapKeyValueTupleReverseIterator : IteratorProtocol {
    public mutating func next() -> (Key, Value)? {
        guard baseIterator.hasNext() else { return nil }

        let payload = baseIterator.currentValueNode?.getPayload(baseIterator.currentValueCursor)
        baseIterator.currentValueCursor -= 1

        return payload
    }
}
