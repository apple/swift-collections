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

public struct HashMap<Key, Value> where Key: Hashable {
    var rootNode: BitmapIndexedMapNode<Key, Value>
    var cachedKeySetHashCode: Int
    var cachedSize: Int

    fileprivate init(_ rootNode: BitmapIndexedMapNode<Key, Value>, _ cachedKeySetHashCode: Int, _ cachedSize: Int) {
        self.rootNode = rootNode
        self.cachedKeySetHashCode = cachedKeySetHashCode
        self.cachedSize = cachedSize
    }

    public init() {
        self.init(BitmapIndexedMapNode(), 0, 0)
    }

    public init(_ map: HashMap<Key, Value>) {
        self.init(map.rootNode, map.cachedKeySetHashCode, map.cachedSize)
    }

    // TODO consider removing `unchecked` version, since it's only referenced from within the test suite
    @inlinable
    @inline(__always)
    public init<S>(uncheckedUniqueKeysWithValues keysAndValues: S) where S : Sequence, S.Element == (Key, Value) {
        var builder = Self()
        keysAndValues.forEach { key, value in
            builder.insert(key: key, value: value)
        }
        self.init(builder)
    }

    @inlinable
    @inline(__always)
    public init<S>(uniqueKeysWithValues keysAndValues: S) where S : Sequence, S.Element == (Key, Value) {
        var builder = Self()
        keysAndValues.forEach { key, value in
            guard !builder.contains(key) else {
                preconditionFailure("Duplicate key: '\(key)'")
            }
            builder.insert(key: key, value: value)
        }
        self.init(builder)
    }

    // TODO consider removing `unchecked` version, since it's only referenced from within the test suite
    @inlinable
    @inline(__always)
    public init<Keys: Sequence, Values: Sequence>(uncheckedUniqueKeys keys: Keys, values: Values) where Keys.Element == Key, Values.Element == Value {
        self.init(uncheckedUniqueKeysWithValues: zip(keys, values))
    }

    @inlinable
    @inline(__always)
    public init<Keys: Sequence, Values: Sequence>(uniqueKeys keys: Keys, values: Values) where Keys.Element == Key, Values.Element == Value {
        self.init(uniqueKeysWithValues: zip(keys, values))
    }

    ///
    /// Inspecting a Dictionary
    ///

    public var isEmpty: Bool { cachedSize == 0 }

    public var count: Int { cachedSize }

    public var underestimatedCount: Int { cachedSize }

    public var capacity: Int { count }

    ///
    /// Accessing Keys and Values
    ///

    public subscript(key: Key) -> Value? {
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

    public subscript(key: Key, default defaultValue: @autoclosure () -> Value) -> Value {
        get {
            return get(key) ?? defaultValue()
        }
        mutating set(value) {
            insert(isKnownUniquelyReferenced(&self.rootNode), key: key, value: value)
        }
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
        let newRootNode = rootNode.updateOrUpdating(isStorageKnownUniquelyReferenced, key, value, keyHash, 0, &effect)

        if effect.modified {
            if effect.replacedValue {
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
    public func inserting(key: Key, value: Value) -> Self {
        var effect = MapEffect()
        let keyHash = computeHash(key)
        let newRootNode = rootNode.updateOrUpdating(false, key, value, keyHash, 0, &effect)

        if effect.modified {
            if effect.replacedValue {
                return Self(newRootNode, cachedKeySetHashCode, cachedSize)
            } else {
                return Self(newRootNode, cachedKeySetHashCode ^ keyHash, cachedSize + 1)
            }
        } else { return self }
    }

    // TODO signature adopted from `Dictionary`, unify with API
    @discardableResult
    public mutating func updateValue(_ value: Value, forKey key: Key) -> Value? {
        let oldValue = get(key)
        insert(key: key, value: value)
        return oldValue
    }

    public mutating func delete(_ key: Key) {
        let mutate = isKnownUniquelyReferenced(&self.rootNode)
        delete(mutate, key: key)
    }

    // querying `isKnownUniquelyReferenced(&self.rootNode)` from within the body of the function always yields `false`
    mutating func delete(_ isStorageKnownUniquelyReferenced: Bool, key: Key) {
        var effect = MapEffect()
        let keyHash = computeHash(key)
        let newRootNode = rootNode.removeOrRemoving(isStorageKnownUniquelyReferenced, key, keyHash, 0, &effect)

        if effect.modified {
            self.rootNode = newRootNode
            self.cachedKeySetHashCode = cachedKeySetHashCode ^ keyHash
            self.cachedSize = cachedSize - 1
        }
    }

    // fluid/immutable API
    public func deleting(key: Key) -> Self {
        var effect = MapEffect()
        let keyHash = computeHash(key)
        let newRootNode = rootNode.removeOrRemoving(false, key, keyHash, 0, &effect)

        if effect.modified {
            return Self(newRootNode, cachedKeySetHashCode ^ keyHash, cachedSize - 1)
        } else { return self }
    }

    // TODO signature adopted from `Dictionary`, unify with API
    @discardableResult
    public mutating func removeValue(forKey key: Key) -> Value? {
        if let value = get(key) {
            delete(key)
            return value
        }
        return nil
    }
}

public struct MapKeyValueTupleIterator<Key: Hashable, Value> {
    private var baseIterator: ChampBaseIterator<BitmapIndexedMapNode<Key, Value>, HashCollisionMapNode<Key, Value>>

    init(rootNode: BitmapIndexedMapNode<Key, Value>) {
        self.baseIterator = ChampBaseIterator(rootNode: .bitmapIndexed(rootNode))
    }
}

extension MapKeyValueTupleIterator: IteratorProtocol {
    public mutating func next() -> (key: Key, value: Value)? {
        guard baseIterator.hasNext() else { return nil }

        let payload: (Key, Value)

        // TODO remove duplication in specialization
        switch baseIterator.currentValueNode! {
        case .bitmapIndexed(let node):
            payload = node.getPayload(baseIterator.currentValueCursor)
        case .hashCollision(let node):
            payload = node.getPayload(baseIterator.currentValueCursor)
        }
        baseIterator.currentValueCursor += 1

        return payload
    }
}

public struct MapKeyValueTupleReverseIterator<Key: Hashable, Value> {
    private var baseIterator: ChampBaseReverseIterator<BitmapIndexedMapNode<Key, Value>, HashCollisionMapNode<Key, Value>>

    init(rootNode: BitmapIndexedMapNode<Key, Value>) {
        self.baseIterator = ChampBaseReverseIterator(rootNode: .bitmapIndexed(rootNode))
    }
}

extension MapKeyValueTupleReverseIterator: IteratorProtocol {
    public mutating func next() -> (key: Key, value: Value)? {
        guard baseIterator.hasNext() else { return nil }

        let payload: (Key, Value)

        // TODO remove duplication in specialization
        switch baseIterator.currentValueNode! {
        case .bitmapIndexed(let node):
            payload = node.getPayload(baseIterator.currentValueCursor)
        case .hashCollision(let node):
            payload = node.getPayload(baseIterator.currentValueCursor)
        }
        baseIterator.currentValueCursor -= 1

        return payload
    }
}
