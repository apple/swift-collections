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

public struct PersistentDictionary<Key, Value> where Key: Hashable {
    var rootNode: BitmapIndexedDictionaryNode<Key, Value>

    fileprivate init(_ rootNode: BitmapIndexedDictionaryNode<Key, Value>) {
        self.rootNode = rootNode
    }

    public init() {
        self.init(BitmapIndexedDictionaryNode())
    }

    public init(_ map: PersistentDictionary<Key, Value>) {
        self.init(map.rootNode)
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
        var expectedCount = 0
        keysAndValues.forEach { key, value in
            builder.insert(key: key, value: value)
            expectedCount += 1

            guard expectedCount == builder.count else {
                preconditionFailure("Duplicate key: '\(key)'")
            }
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

    public var isEmpty: Bool { rootNode.count == 0 }

    public var count: Int { rootNode.count }

    public var underestimatedCount: Int { rootNode.count }

    public var capacity: Int { rootNode.count }

    ///
    /// Accessing Keys and Values
    ///

    public subscript(key: Key) -> Value? {
        get {
            return get(key)
        }
        mutating set(optionalValue) {
            if let value = optionalValue {
                let mutate = isKnownUniquelyReferenced(&self.rootNode)
                insert(mutate, key: key, value: value)
            } else {
                let mutate = isKnownUniquelyReferenced(&self.rootNode)
                delete(mutate, key: key)
            }
        }
    }

    public subscript(key: Key, default defaultValue: @autoclosure () -> Value) -> Value {
        get {
            return get(key) ?? defaultValue()
        }
        mutating set(value) {
            let mutate = isKnownUniquelyReferenced(&self.rootNode)
            insert(mutate, key: key, value: value)
        }
    }

    public func contains(_ key: Key) -> Bool {
        rootNode.containsKey(key, computeHash(key), 0)
    }

    func get(_ key: Key) -> Value? {
        rootNode.get(key, computeHash(key), 0)
    }

    public mutating func insert(key: Key, value: Value) {
        let mutate = isKnownUniquelyReferenced(&self.rootNode)
        insert(mutate, key: key, value: value)
    }

    // querying `isKnownUniquelyReferenced(&self.rootNode)` from within the body of the function always yields `false`
    mutating func insert(_ isStorageKnownUniquelyReferenced: Bool, key: Key, value: Value) {
        var effect = DictionaryEffect()
        let keyHash = computeHash(key)
        let newRootNode = rootNode.updateOrUpdating(isStorageKnownUniquelyReferenced, key, value, keyHash, 0, &effect)

        if effect.modified {
            self.rootNode = newRootNode
        }
    }

    // fluid/immutable API
    public func inserting(key: Key, value: Value) -> Self {
        var effect = DictionaryEffect()
        let keyHash = computeHash(key)
        let newRootNode = rootNode.updateOrUpdating(false, key, value, keyHash, 0, &effect)

        if effect.modified {
            return Self(newRootNode)
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
        var effect = DictionaryEffect()
        let keyHash = computeHash(key)
        let newRootNode = rootNode.removeOrRemoving(isStorageKnownUniquelyReferenced, key, keyHash, 0, &effect)

        if effect.modified {
            self.rootNode = newRootNode
        }
    }

    // fluid/immutable API
    public func deleting(key: Key) -> Self {
        var effect = DictionaryEffect()
        let keyHash = computeHash(key)
        let newRootNode = rootNode.removeOrRemoving(false, key, keyHash, 0, &effect)

        if effect.modified {
            return Self(newRootNode)
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

///
/// Fixed-stack iterator for traversing a hash-trie. The iterator performs a
/// depth-first pre-order traversal, which yields first all payload elements of the current
/// node before traversing sub-nodes (left to right).
///
public struct DictionaryKeyValueTupleIterator<Key: Hashable, Value>: IteratorProtocol {

    private var payloadIterator: UnsafeBufferPointer<(key: Key, value: Value)>.Iterator?

    private var trieIteratorStackTop: UnsafeBufferPointer<AnyObject>.Iterator?
    private var trieIteratorStackRemainder: [UnsafeBufferPointer<AnyObject>.Iterator]

    init(rootNode: BitmapIndexedDictionaryNode<Key, Value>) {
        trieIteratorStackRemainder = []
        trieIteratorStackRemainder.reserveCapacity(maxDepth)

        if rootNode.hasNodes   { trieIteratorStackTop = makeTrieIterator(rootNode) }
        if rootNode.hasPayload { payloadIterator = makePayloadIterator(rootNode) }
    }

    // TODO consider moving to `BitmapIndexedDictionaryNode<Key, Value>`
    private func makePayloadIterator(_ node: BitmapIndexedDictionaryNode<Key, Value>) -> UnsafeBufferPointer<(key: Key, value: Value)>.Iterator {
        UnsafeBufferPointer(start: node.dataBaseAddress, count: node.payloadArity).makeIterator()
    }

    // TODO consider moving to `BitmapIndexedDictionaryNode<Key, Value>`
    private func makeTrieIterator(_ node: BitmapIndexedDictionaryNode<Key, Value>) -> UnsafeBufferPointer<AnyObject>.Iterator {
        UnsafeBufferPointer(start: node.trieBaseAddress, count: node.nodeArity).makeIterator()
    }

    public mutating func next() -> (key: Key, value: Value)? {
        if let payload = payloadIterator?.next() {
            return payload
        }

        while trieIteratorStackTop != nil {
            if let nextAnyObject = trieIteratorStackTop!.next() {
                switch nextAnyObject {
                case let nextNode as BitmapIndexedDictionaryNode<Key, Value>:
                    if nextNode.hasNodes {
                        trieIteratorStackRemainder.append(trieIteratorStackTop!)
                        trieIteratorStackTop = makeTrieIterator(nextNode)
                    }
                    if nextNode.hasPayload {
                        payloadIterator = makePayloadIterator(nextNode)
                        return payloadIterator?.next()
                    }
                case let nextNode as HashCollisionDictionaryNode<Key, Value>:
                    payloadIterator = nextNode.content.withUnsafeBufferPointer { $0.makeIterator() }
                    return payloadIterator?.next()
                default:
                    fatalError("Should not reach here.") // TODO: rework to remove 'dummy' default clause
                }
            } else {
                trieIteratorStackTop = trieIteratorStackRemainder.popLast()
            }
        }

        // Clean-up state
        payloadIterator = nil

        assert(payloadIterator == nil)
        assert(trieIteratorStackTop == nil)
        assert(trieIteratorStackRemainder.isEmpty)

        return nil
    }
}

// TODO consider reworking similar to `DictionaryKeyValueTupleIterator`
// (would require a reversed variant of `UnsafeBufferPointer<(key: Key, value: Value)>.Iterator`)
public struct DictionaryKeyValueTupleReverseIterator<Key: Hashable, Value> {
    private var baseIterator: ChampBaseReverseIterator<BitmapIndexedDictionaryNode<Key, Value>, HashCollisionDictionaryNode<Key, Value>>

    init(rootNode: BitmapIndexedDictionaryNode<Key, Value>) {
        self.baseIterator = ChampBaseReverseIterator(rootNode: .bitmapIndexed(rootNode))
    }
}

extension DictionaryKeyValueTupleReverseIterator: IteratorProtocol {
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
