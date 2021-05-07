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
    var rootNode: BitmapIndexedMapNode<Key, Value>
    var cachedKeySetHashCode: Int
    var cachedSize: Int
    
    fileprivate init(_ rootNode: BitmapIndexedMapNode<Key, Value>, _ cachedKeySetHashCode: Int, _ cachedSize: Int) {
        self.rootNode = rootNode
        self.cachedKeySetHashCode = cachedKeySetHashCode
        self.cachedSize = cachedSize
    }
    
    public init() {
        self.init(BitmapIndexedMapNode(0, 0, 0, Array()), 0, 0)
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
                insert(isKnownUniquelyReferenced(&self.rootNode), key: key, value: value)
            } else {
                delete(isKnownUniquelyReferenced(&self.rootNode), key: key)
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

    public mutating func insert(key: Key, value: Value) {
        let mutate = isKnownUniquelyReferenced(&self.rootNode)
        insert(mutate, key: key, value: value)
    }

    // querying `isKnownUniquelyReferenced(&self.rootNode)` from within the body of the function always yields `false`
    mutating func insert(_ isStorageKnownUniquelyReferenced: Bool, key: Key, value: Value) {
        var effect = MapEffect()
        let keyHash = computeHash(key)
        let newRootNode = rootNode.updated(isStorageKnownUniquelyReferenced, key, value, keyHash, 0, &effect)

        if (effect.modified) {
            if (effect.replacedValue) {
                self.rootNode = newRootNode
                // self.cachedKeySetHashCode = cachedKeySetHashCode
                // self.cachedSize = cachedSize
            } else {
                self.rootNode = newRootNode
                self.cachedKeySetHashCode = cachedKeySetHashCode ^ keyHash
                self.cachedSize = cachedSize + 1
            }
        }
    }

    // fluid/immutable API
    public func with(key: Key, value: Value) -> Self {
        var effect = MapEffect()
        let keyHash = computeHash(key)
        let newRootNode = rootNode.updated(false, key, value, keyHash, 0, &effect)

        if (effect.modified) {
            if (effect.replacedValue) {
                return Self(newRootNode, cachedKeySetHashCode, cachedSize)
            } else {
                return Self(newRootNode, cachedKeySetHashCode ^ keyHash, cachedSize + 1)
            }
        } else { return self }
    }

    public mutating func delete(_ key: Key) {
        let mutate = isKnownUniquelyReferenced(&self.rootNode)
        delete(mutate, key: key)
    }

    // querying `isKnownUniquelyReferenced(&self.rootNode)` from within the body of the function always yields `false`
    mutating func delete(_ isStorageKnownUniquelyReferenced: Bool, key: Key) {
        var effect = MapEffect()
        let keyHash = computeHash(key)
        let newRootNode = rootNode.removed(isStorageKnownUniquelyReferenced, key, keyHash, 0, &effect)

        if (effect.modified) {
            self.rootNode = newRootNode
            self.cachedKeySetHashCode = cachedKeySetHashCode ^ keyHash
            self.cachedSize = cachedSize - 1
        }
    }

    // fluid/immutable API
    public func without(key: Key) -> Self {
        var effect = MapEffect()
        let keyHash = computeHash(key)
        let newRootNode = rootNode.removed(false, key, keyHash, 0, &effect)

        if (effect.modified) {
            return Self(newRootNode, cachedKeySetHashCode ^ keyHash, cachedSize - 1)
        } else { return self }
    }
}

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
