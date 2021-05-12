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

final class HashCollisionMapNode<Key, Value>: MapNode where Key: Hashable {
    let hash: Int
    let content: [(key: Key, value: Value)]

    init(_ hash: Int, _ content: [(key: Key, value: Value)]) {
        // precondition(content.count >= 2)
        precondition(content.map { $0.key }.allSatisfy {$0.hashValue == hash})

        self.hash = hash
        self.content = content
    }

    func get(_ key: Key, _ hash: Int, _ shift: Int) -> Value? {
        if self.hash == hash {
            return content.first(where: { key == $0.key }).map { $0.value }
        } else { return nil }
    }

    func containsKey(_ key: Key, _ hash: Int, _ shift: Int) -> Bool {
        return self.hash == hash && content.contains(where: { key == $0.key })
    }

//    // TODO requires Value to be Equatable
//    func contains(_ key: Key, _ value: Value, _ hash: Int, _ shift: Int) -> Bool {
//        return self.hash == hash && content.contains(where: { key == $0.key && value == $0.value })
//    }

    func updateOrUpdating(_ isStorageKnownUniquelyReferenced: Bool, _ key: Key, _ value: Value, _ hash: Int, _ shift: Int, _ effect: inout MapEffect) -> HashCollisionMapNode<Key, Value> {

        // TODO check if key/value-pair check should be added (requires value to be Equitable)
        if self.containsKey(key, hash, shift) {
            let index = content.firstIndex(where: { key == $0.key })!
            let updatedContent = content[0..<index] + [(key, value)] + content[index+1..<content.count]

            effect.setReplacedValue()
            // TODO check (performance of) slicing and materialization of array content
            return HashCollisionMapNode(hash, Array(updatedContent))
        } else {
            effect.setModified()
            return HashCollisionMapNode(hash, content + [(key, value)])
        }
    }

    // TODO rethink such that `precondition(content.count >= 2)` holds
    // TODO consider returning either type of `BitmapIndexedMapNode` and `HashCollisionMapNode`
    func removeOrRemoving(_ isStorageKnownUniquelyReferenced: Bool, _ key: Key, _ hash: Int, _ shift: Int, _ effect: inout MapEffect) -> HashCollisionMapNode<Key, Value> {
        if !self.containsKey(key, hash, shift) {
            return self
        } else {
            effect.setModified()
            let updatedContent = content.filter { $0.key != key }
            assert(updatedContent.count == content.count - 1)

//            switch updatedContent.count {
//            case 1:
//                let (k, v) = updatedContent[0].self
//                return BitmapIndexedMapNode<Key, Value>(bitposFrom(maskFrom(hash, 0)), 0, Array(arrayLiteral: k, v))
//            default:
            return HashCollisionMapNode(hash, updatedContent)
//            }
        }
    }

    var hasBitmapIndexedNodes: Bool { false }

    var bitmapIndexedNodeArity: Int { 0 }

    func getBitmapIndexedNode(_ index: Int) -> HashCollisionMapNode<Key, Value> {
        preconditionFailure("No sub-nodes present in hash-collision leaf node")
    }

    var hasHashCollisionNodes: Bool { false }

    var hashCollisionNodeArity: Int { 0 }

    func getHashCollisionNode(_ index: Int) -> HashCollisionMapNode<Key, Value> {
        preconditionFailure("No sub-nodes present in hash-collision leaf node")
    }

    var hasNodes: Bool { false }

    var nodeArity: Int { 0 }

    func getNode(_ index: Int) -> TrieNode<HashCollisionMapNode<Key, Value>, HashCollisionMapNode<Key, Value>> {
        preconditionFailure("No sub-nodes present in hash-collision leaf node")
    }

    var hasPayload: Bool { true }

    var payloadArity: Int { content.count }

    func getPayload(_ index: Int) -> (key: Key, value: Value) { content[index] }

    var sizePredicate: SizePredicate { SizePredicate(self) }
}

extension HashCollisionMapNode: Equatable where Value: Equatable {
    static func == (lhs: HashCollisionMapNode<Key, Value>, rhs: HashCollisionMapNode<Key, Value>) -> Bool {
        Dictionary.init(uniqueKeysWithValues: lhs.content) == Dictionary.init(uniqueKeysWithValues: rhs.content)
    }
}
