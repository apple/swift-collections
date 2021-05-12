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

fileprivate var TupleLength: Int { 2 }

final class BitmapIndexedMapNode<Key, Value> : MapNode where Key : Hashable {
    let bitmap1: Bitmap
    let bitmap2: Bitmap
    var content: [Any]

    var dataMap: Bitmap { bitmap1 ^ collMap }

    var nodeMap: Bitmap { bitmap2 ^ collMap }

    var collMap: Bitmap { bitmap1 & bitmap2 }

    init(_ dataMap: Bitmap, _ nodeMap: Bitmap, _ collMap: Bitmap, _ content: [Any]) {
        self.bitmap1 = dataMap ^ collMap
        self.bitmap2 = nodeMap ^ collMap
        self.content = content
    }

    convenience init(dataMap: Bitmap = 0, nodeMap: Bitmap = 0, collMap: Bitmap = 0, arrayLiteral content: Any...) {
        self.init(dataMap, nodeMap, collMap, content)
    }

    // TODO improve performance of variadic implementation or consider specializing for two key-value tuples
    convenience init(dataMap: Bitmap, arrayLiteral elements: (Key, Value)...) {
        self.init(dataMap, 0, 0, elements.flatMap { [$0.0, $0.1] })
    }

    // TODO improve performance of variadic implementation or consider specializing for singleton nodes
    convenience init(nodeMap: Bitmap, arrayLiteral elements: BitmapIndexedMapNode<Key, Value>...) {
        self.init(0, nodeMap, 0, elements)
    }

    // TODO improve performance of variadic implementation or consider specializing for singleton nodes
    convenience init(collMap: Bitmap, arrayLiteral elements: HashCollisionMapNode<Key, Value>...) {
        self.init(0, 0, collMap, elements)
    }

    func get(_ key: Key, _ keyHash: Int, _ shift: Int) -> Value? {
        let mask = maskFrom(keyHash, shift)
        let bitpos = bitposFrom(mask)

        if ((dataMap & bitpos) != 0) {
            let index = indexFrom(dataMap, mask, bitpos)
            let payload = self.getPayload(index)
            if (key == payload.key) { return payload.value } else { return nil }
        }

        if ((nodeMap & bitpos) != 0) {
            let index = indexFrom(nodeMap, mask, bitpos)
            return self.getBitmapIndexedNode(index).get(key, keyHash, shift + BitPartitionSize)
        }

        if ((collMap & bitpos) != 0) {
            let index = indexFrom(collMap, mask, bitpos)
            return self.getHashCollisionNode(index).get(key, keyHash, shift + BitPartitionSize)
        }

        return nil
    }

    func containsKey(_ key: Key, _ keyHash: Int, _ shift: Int) -> Bool {
        let mask = maskFrom(keyHash, shift)
        let bitpos = bitposFrom(mask)

        if ((dataMap & bitpos) != 0) {
            let index = indexFrom(dataMap, mask, bitpos)
            let payload = self.getPayload(index)
            return key == payload.key
        }

        if ((nodeMap & bitpos) != 0) {
            let index = indexFrom(nodeMap, mask, bitpos)
            return self.getBitmapIndexedNode(index).containsKey(key, keyHash, shift + BitPartitionSize)
        }

        if ((collMap & bitpos) != 0) {
            let index = indexFrom(collMap, mask, bitpos)
            return self.getHashCollisionNode(index).containsKey(key, keyHash, shift + BitPartitionSize)
        }

        return false
    }

    func updated(_ isStorageKnownUniquelyReferenced: Bool, _ key: Key, _ value: Value, _ keyHash: Int, _ shift: Int, _ effect: inout MapEffect) -> BitmapIndexedMapNode<Key, Value> {
        let mask = maskFrom(keyHash, shift)
        let bitpos = bitposFrom(mask)

        if ((dataMap & bitpos) != 0) {
            let index = indexFrom(dataMap, mask, bitpos)
            let (key0, value0) = self.getPayload(index)

            if (key0 == key) {
                effect.setReplacedValue()
                return copyAndSetValue(isStorageKnownUniquelyReferenced, bitpos, value)
            } else {
                let keyHash0 = computeHash(key0)

                if (keyHash0 == keyHash) {
                    let subNodeNew = HashCollisionMapNode(keyHash0, [(key0, value0), (key, value)])
                    effect.setModified()
                    return copyAndMigrateFromInlineToCollisionNode(bitpos, subNodeNew)
                } else {
                    let subNodeNew = mergeTwoKeyValPairs(key0, value0, keyHash0, key, value, keyHash, shift + BitPartitionSize)
                    effect.setModified()
                    return copyAndMigrateFromInlineToNode(bitpos, subNodeNew)
                }
            }
        }

        if ((nodeMap & bitpos) != 0) {
            let index = indexFrom(nodeMap, mask, bitpos)
            let subNodeModifyInPlace = self.isBitmapIndexedNodeKnownUniquelyReferenced(index, isStorageKnownUniquelyReferenced)
            let subNode = self.getBitmapIndexedNode(index)

            let subNodeNew = subNode.updated(subNodeModifyInPlace, key, value, keyHash, shift + BitPartitionSize, &effect)
            if (!effect.modified) {
                return self
            } else {
                return copyAndSetBitmapIndexedNode(isStorageKnownUniquelyReferenced, bitpos, subNodeNew)
            }
        }

        if ((collMap & bitpos) != 0) {
            let index = indexFrom(collMap, mask, bitpos)
            let subNodeModifyInPlace = self.isHashCollisionNodeKnownUniquelyReferenced(index, isStorageKnownUniquelyReferenced)
            let subNode = self.getHashCollisionNode(index)

            let collisionHash = subNode.hash

            if (keyHash == collisionHash) {
                let subNodeNew = subNode.updated(subNodeModifyInPlace, key, value, keyHash, shift + BitPartitionSize, &effect)
                if (!effect.modified) {
                    return self
                } else {
                    return copyAndSetHashCollisionNode(isStorageKnownUniquelyReferenced, bitpos, subNodeNew)
                }
            } else {
                let subNodeNew = mergeKeyValPairAndCollisionNode(key, value, keyHash, subNode, collisionHash, shift + BitPartitionSize)
                effect.setModified()
                return copyAndMigrateFromCollisionNodeToNode(bitpos, subNodeNew)
            }
        }

        effect.setModified()
        return copyAndInsertValue(bitpos, key, value)
    }

    func removed(_ isStorageKnownUniquelyReferenced: Bool, _ key: Key, _ keyHash: Int, _ shift: Int, _ effect: inout MapEffect) -> BitmapIndexedMapNode<Key, Value> {
        let mask = maskFrom(keyHash, shift)
        let bitpos = bitposFrom(mask)

        if ((dataMap & bitpos) != 0) {
            let index = indexFrom(dataMap, mask, bitpos)
            let (key0, _) = self.getPayload(index)

            if (key0 == key) {
                effect.setModified()
                // TODO check globally usage of `bitmapIndexedNodeArity` and `hashCollisionNodeArity`
                if (self.payloadArity == 2 && self.bitmapIndexedNodeArity == 0 && self.hashCollisionNodeArity == 0) {
                    /*
                     * Create new node with remaining pair. The new node will a) either become the new root
                     * returned, or b) unwrapped and inlined during returning.
                     */
                    let newDataMap: Bitmap
                    if (shift == 0) { newDataMap = (dataMap ^ bitpos) } else { newDataMap = bitposFrom(maskFrom(keyHash, 0)) }
                    if (index == 0) {
                        return BitmapIndexedMapNode(dataMap: newDataMap, arrayLiteral: getPayload(1))
                    } else {
                        return BitmapIndexedMapNode(dataMap: newDataMap, arrayLiteral: getPayload(0))
                    }
                } else if (self.payloadArity == 1 && self.bitmapIndexedNodeArity == 0 && self.hashCollisionNodeArity == 1) {
                    /*
                     * Create new node with collision node. The new node will a) either become the new root
                     * returned, or b) unwrapped and inlined during returning.
                     */
                    let newCollMap: Bitmap = bitposFrom(maskFrom(getHashCollisionNode(0).hash, 0))
                    return BitmapIndexedMapNode(collMap: newCollMap, arrayLiteral: getHashCollisionNode(0))
                } else { return copyAndRemoveValue(bitpos) }
            } else { return self }
        }

        if ((nodeMap & bitpos) != 0) {
            let index = indexFrom(nodeMap, mask, bitpos)
            let subNodeModifyInPlace = self.isBitmapIndexedNodeKnownUniquelyReferenced(index, isStorageKnownUniquelyReferenced)
            let subNode = self.getBitmapIndexedNode(index)

            let subNodeNew = subNode.removed(subNodeModifyInPlace, key, keyHash, shift + BitPartitionSize, &effect)

            if (!effect.modified) { return self }
            switch subNodeNew.sizePredicate {
            case .sizeEmpty:
                preconditionFailure("Sub-node must have at least one element.")
            case .sizeOne:
                if (self.payloadArity == 0 && self.bitmapIndexedNodeArity == 1) { // escalate (singleton or empty) result
                    return subNodeNew
                }
                else { // inline value (move to front)
                    return copyAndMigrateFromNodeToInline(bitpos, subNodeNew.getPayload(0))
                }

            case .sizeMoreThanOne:
                // TODO simplify hash-collision compaction (if feasible)
                if (subNodeNew.payloadArity == 0 && subNodeNew.bitmapIndexedNodeArity == 0 && subNodeNew.hashCollisionNodeArity == 1) {
                    if (self.payloadArity == 0 && (self.bitmapIndexedNodeArity + self.hashCollisionNodeArity) == 1) { // escalate (singleton or empty) result
                        return subNodeNew
                    } else { // inline value (move to front)
                        assertionFailure()
                        // return copyAndMigrateFromNodeToCollisionNode(bitpos, subNodeNew.getHashCollisionNode(0))
                    }
                }

                // modify current node (set replacement node)
                return copyAndSetBitmapIndexedNode(isStorageKnownUniquelyReferenced, bitpos, subNodeNew)
            }
        }

        if ((collMap & bitpos) != 0) {
            let index = indexFrom(collMap, mask, bitpos)
            let subNodeModifyInPlace = self.isHashCollisionNodeKnownUniquelyReferenced(index, isStorageKnownUniquelyReferenced)
            let subNode = self.getHashCollisionNode(index)

            let subNodeNew = subNode.removed(subNodeModifyInPlace, key, keyHash, shift + BitPartitionSize, &effect)

            if (!effect.modified) { return self }
            switch subNodeNew.sizePredicate {
            case .sizeEmpty:
                preconditionFailure("Sub-node must have at least one element.")
            case .sizeOne:
                // TODO simplify hash-collision compaction (if feasible)
                if (self.payloadArity == 0 && (self.bitmapIndexedNodeArity + self.hashCollisionNodeArity) == 1) { // escalate (singleton or empty) result
                    // convert `HashCollisionMapNode` to `BitmapIndexedMapNode` (logic moved/inlined from `HashCollisionMapNode`)
                    let newDataMap: Bitmap = bitposFrom(maskFrom(subNodeNew.hash, 0))
                    return BitmapIndexedMapNode(dataMap: newDataMap, arrayLiteral: subNodeNew.getPayload(0))
                }
                else { // inline value (move to front)
                    return copyAndMigrateFromCollisionNodeToInline(bitpos, subNodeNew.getPayload(0))
                }

            case .sizeMoreThanOne:
                // modify current node (set replacement node)
                return copyAndSetHashCollisionNode(isStorageKnownUniquelyReferenced, bitpos, subNodeNew)
            }
       }

        return self
    }

    func mergeTwoKeyValPairs(_ key0: Key, _ value0: Value, _ keyHash0: Int, _ key1: Key, _ value1: Value, _ keyHash1: Int, _ shift: Int) -> BitmapIndexedMapNode<Key, Value> {
        precondition(keyHash0 != keyHash1)

        let mask0 = maskFrom(keyHash0, shift)
        let mask1 = maskFrom(keyHash1, shift)

        if mask0 != mask1 {
            // unique prefixes, payload fits on same level
            if mask0 < mask1 {
                return BitmapIndexedMapNode(dataMap: bitposFrom(mask0) | bitposFrom(mask1), arrayLiteral: (key0, value0), (key1, value1))
            } else {
                return BitmapIndexedMapNode(dataMap: bitposFrom(mask1) | bitposFrom(mask0), arrayLiteral: (key1, value1), (key0, value0))
            }
        } else {
            // recurse: identical prefixes, payload must be disambiguated deeper in the trie
            let node = mergeTwoKeyValPairs(key0, value0, keyHash0, key1, value1, keyHash1, shift + BitPartitionSize)

            return BitmapIndexedMapNode(nodeMap: bitposFrom(mask0), arrayLiteral: node)
        }
    }

    func mergeKeyValPairAndCollisionNode(_ key0: Key, _ value0: Value, _ keyHash0: Int, _ node1: HashCollisionMapNode<Key, Value>, _ nodeHash1: Int, _ shift: Int) -> BitmapIndexedMapNode<Key, Value> {
        precondition(keyHash0 != nodeHash1)

        let mask0 = maskFrom(keyHash0, shift)
        let mask1 = maskFrom(nodeHash1, shift)

        if mask0 != mask1 {
            // unique prefixes, payload and collision node fit on same level
            return BitmapIndexedMapNode(dataMap: bitposFrom(mask0), collMap: bitposFrom(mask1), arrayLiteral: key0, value0, node1)
        } else {
            // recurse: identical prefixes, payload must be disambiguated deeper in the trie
            let node = mergeKeyValPairAndCollisionNode(key0, value0, keyHash0, node1, nodeHash1, shift + BitPartitionSize)

            return BitmapIndexedMapNode(nodeMap: bitposFrom(mask0), arrayLiteral: node)
        }
    }

    var hasBitmapIndexedNodes: Bool { nodeMap != 0 }

    var bitmapIndexedNodeArity: Int { nodeMap.nonzeroBitCount }

    func getBitmapIndexedNode(_ index: Int) -> BitmapIndexedMapNode<Key, Value> {
        content[content.count - 1 - index] as! BitmapIndexedMapNode<Key, Value>
    }

    private func isBitmapIndexedNodeKnownUniquelyReferenced(_ index: Int, _ isParentNodeKnownUniquelyReferenced: Bool) -> Bool {
        let slotIndex = content.count - 1 - index
        return isTrieNodeKnownUniquelyReferenced(slotIndex, isParentNodeKnownUniquelyReferenced)
    }

    private func isHashCollisionNodeKnownUniquelyReferenced(_ index: Int, _ isParentNodeKnownUniquelyReferenced: Bool) -> Bool {
        let slotIndex = content.count - 1 - bitmapIndexedNodeArity - index
        return isTrieNodeKnownUniquelyReferenced(slotIndex, isParentNodeKnownUniquelyReferenced)
    }

    // TODO replace 'manual' move semantics with pointer arithmetic for obtaining reference
    // to pass into `isKnownUniquelyReferenced`
    private func isTrieNodeKnownUniquelyReferenced(_ slotIndex: Int, _ isParentNodeKnownUniquelyReferenced: Bool) -> Bool {
        let fakeNode = BitmapIndexedMapNode()

        var realNode = content[slotIndex] as AnyObject
        content[slotIndex] = fakeNode

        let isKnownUniquelyReferenced = isKnownUniquelyReferenced(&realNode)
        content[slotIndex] = realNode

        return isParentNodeKnownUniquelyReferenced && isKnownUniquelyReferenced
    }

    var hasHashCollisionNodes: Bool { collMap != 0 }

    var hashCollisionNodeArity: Int { collMap.nonzeroBitCount }

    func getHashCollisionNode(_ index: Int) -> HashCollisionMapNode<Key, Value> {
        return content[content.count - 1 - bitmapIndexedNodeArity - index] as! HashCollisionMapNode<Key, Value>
    }

    var hasNodes: Bool { (nodeMap | collMap) != 0 }

    var nodeArity: Int { (nodeMap | collMap).nonzeroBitCount }

    func getNode(_ index: Int) -> TrieNode<BitmapIndexedMapNode<Key, Value>, HashCollisionMapNode<Key, Value>> {
        if index < bitmapIndexedNodeArity {
            return .bitmapIndexed(getBitmapIndexedNode(index))
        } else {
            return .hashCollision(getHashCollisionNode(index))
        }
    }

    var hasPayload: Bool { dataMap != 0 }

    var payloadArity: Int { dataMap.nonzeroBitCount }

    func getPayload(_ index: Int) -> (key: Key, value: Value) {
        (content[TupleLength * index + 0] as! Key,
         content[TupleLength * index + 1] as! Value)
    }

    var sizePredicate: SizePredicate { SizePredicate(self) }

    func dataIndex(_ bitpos: Bitmap) -> Int { (dataMap & (bitpos &- 1)).nonzeroBitCount }

    func nodeIndex(_ bitpos: Bitmap) -> Int { (nodeMap & (bitpos &- 1)).nonzeroBitCount }

    func collIndex(_ bitpos: Bitmap) -> Int { (collMap & (bitpos &- 1)).nonzeroBitCount }

    func copyAndSetValue(_ isStorageKnownUniquelyReferenced: Bool, _ bitpos: Bitmap, _ newValue: Value) -> BitmapIndexedMapNode<Key, Value> {
        let idx = TupleLength * dataIndex(bitpos) + 1

        if (isStorageKnownUniquelyReferenced) {
            // no copying if already editable
            self.content[idx] = newValue

            return self
        } else {
            var dst = self.content
            dst[idx] = newValue

            return BitmapIndexedMapNode(dataMap, nodeMap, collMap, dst)
        }
    }

    func copyAndSetBitmapIndexedNode(_ isStorageKnownUniquelyReferenced: Bool, _ bitpos: Bitmap, _ newNode: BitmapIndexedMapNode<Key, Value>) -> BitmapIndexedMapNode<Key, Value> {
        let idx = self.content.count - 1 - self.nodeIndex(bitpos)
        return copyAndSetTrieNode(isStorageKnownUniquelyReferenced, bitpos, idx, newNode)    }

    func copyAndSetHashCollisionNode(_ isStorageKnownUniquelyReferenced: Bool, _ bitpos: Bitmap, _ newNode: HashCollisionMapNode<Key, Value>) -> BitmapIndexedMapNode<Key, Value> {
        let idx = self.content.count - 1 - bitmapIndexedNodeArity - self.collIndex(bitpos)
        return copyAndSetTrieNode(isStorageKnownUniquelyReferenced, bitpos, idx, newNode)
    }

    private func copyAndSetTrieNode<T: MapNode>(_ isStorageKnownUniquelyReferenced: Bool, _ bitpos: Bitmap, _ idx: Int, _ newNode: T) -> BitmapIndexedMapNode<Key, Value> {
        if (isStorageKnownUniquelyReferenced) {
            // no copying if already editable
            self.content[idx] = newNode

            return self
        } else {
            var dst = self.content
            dst[idx] = newNode

            return BitmapIndexedMapNode(dataMap, nodeMap, collMap, dst)
        }
    }

    func copyAndInsertValue(_ bitpos: Bitmap, _ key: Key, _ value: Value) -> BitmapIndexedMapNode<Key, Value> {
        let idx = TupleLength * dataIndex(bitpos)

        var dst = self.content
        dst.insert(contentsOf: [key, value], at: idx)

        return BitmapIndexedMapNode(dataMap | bitpos, nodeMap, collMap, dst)
    }

    func copyAndRemoveValue(_ bitpos: Bitmap) -> BitmapIndexedMapNode<Key, Value> {
        let idx = TupleLength * dataIndex(bitpos)

        var dst = self.content
        dst.removeSubrange(idx..<idx+TupleLength)

        return BitmapIndexedMapNode(dataMap ^ bitpos, nodeMap, collMap, dst)
    }

    func copyAndMigrateFromInlineToNode(_ bitpos: Bitmap, _ node: BitmapIndexedMapNode<Key, Value>) -> BitmapIndexedMapNode<Key, Value> {
        let idxOld = TupleLength * dataIndex(bitpos)
        let idxNew = self.content.count - TupleLength - nodeIndex(bitpos)

        var dst = self.content
        dst.removeSubrange(idxOld..<idxOld+TupleLength)
        dst.insert(node, at: idxNew)

        return BitmapIndexedMapNode(dataMap ^ bitpos, nodeMap | bitpos, collMap, dst)
    }

    func copyAndMigrateFromInlineToCollisionNode(_ bitpos: Bitmap, _ node: HashCollisionMapNode<Key, Value>) -> BitmapIndexedMapNode<Key, Value> {
        let idxOld = TupleLength * dataIndex(bitpos)
        let idxNew = self.content.count - TupleLength - bitmapIndexedNodeArity - collIndex(bitpos)

        var dst = self.content
        dst.removeSubrange(idxOld..<idxOld+TupleLength)
        dst.insert(node, at: idxNew)

        return BitmapIndexedMapNode(dataMap ^ bitpos, nodeMap, collMap | bitpos, dst)
    }

    func copyAndMigrateFromNodeToInline(_ bitpos: Bitmap, _ tuple: (key: Key, value: Value)) -> BitmapIndexedMapNode<Key, Value> {
        let idxOld = self.content.count - 1 - nodeIndex(bitpos)
        let idxNew = TupleLength * dataIndex(bitpos)

        var dst = self.content
        dst.remove(at: idxOld)
        dst.insert(contentsOf: [tuple.key, tuple.value], at: idxNew)

        return BitmapIndexedMapNode(dataMap | bitpos, nodeMap ^ bitpos, collMap, dst)
    }

    func copyAndMigrateFromCollisionNodeToInline(_ bitpos: Bitmap, _ tuple: (key: Key, value: Value)) -> BitmapIndexedMapNode<Key, Value> {
        let idxOld = self.content.count - 1 - bitmapIndexedNodeArity - collIndex(bitpos)
        let idxNew = TupleLength * dataIndex(bitpos)

        var dst = self.content
        dst.remove(at: idxOld)
        dst.insert(contentsOf: [tuple.key, tuple.value], at: idxNew)

        return BitmapIndexedMapNode(dataMap | bitpos, nodeMap, collMap ^ bitpos, dst)
    }

    func copyAndMigrateFromCollisionNodeToNode(_ bitpos: Bitmap, _ node: BitmapIndexedMapNode<Key, Value>) -> BitmapIndexedMapNode<Key, Value> {
        let idxOld = self.content.count - 1 - bitmapIndexedNodeArity - collIndex(bitpos)
        let idxNew = self.content.count - 1 - nodeIndex(bitpos)

        var dst = self.content
        dst.remove(at: idxOld)
        dst.insert(node, at: idxNew)

        return BitmapIndexedMapNode(dataMap, nodeMap | bitpos, collMap ^ bitpos, dst)
    }

//    func copyAndMigrateFromNodeToCollisionNode(_ bitpos: Bitmap, _ node: HashCollisionMapNode<Key, Value>) -> BitmapIndexedMapNode<Key, Value> {
//        let idxOld = self.content.count - 1 - nodeIndex(bitpos)
//        let idxNew = self.content.count - 1 - bitmapIndexedNodeArity - 1 - collIndex(bitpos)
//
//        var dst = self.content
//        dst.remove(at: idxOld)
//        dst.insert(node, at: idxNew)
//
//        return BitmapIndexedMapNode(dataMap, nodeMap ^ bitpos, collMap | bitpos, dst)
//    }
}

extension BitmapIndexedMapNode : Equatable where Value : Equatable {
    static func == (lhs: BitmapIndexedMapNode<Key, Value>, rhs: BitmapIndexedMapNode<Key, Value>) -> Bool {
        lhs === rhs ||
            lhs.nodeMap == rhs.nodeMap &&
            lhs.dataMap == rhs.dataMap &&
            lhs.collMap == rhs.collMap &&
            deepContentEquality(lhs, rhs)
    }

    private static func deepContentEquality(_ lhs: BitmapIndexedMapNode<Key, Value>, _ rhs: BitmapIndexedMapNode<Key, Value>) -> Bool {
        for index in 0..<lhs.payloadArity {
            if (lhs.getPayload(index) != rhs.getPayload(index)) {
                return false
            }
        }

        for index in 0..<lhs.bitmapIndexedNodeArity {
            if (lhs.getBitmapIndexedNode(index) != rhs.getBitmapIndexedNode(index)) {
                return false
            }
        }

        for index in 0..<lhs.hashCollisionNodeArity {
            if (lhs.getHashCollisionNode(index) != rhs.getHashCollisionNode(index)) {
                return false
            }
        }

        return true
    }
}
