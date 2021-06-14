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

typealias Header = (bitmap1: Bitmap, bitmap2: Bitmap)
typealias Element = Any

fileprivate let fixedCapacity = Bitmap.bitWidth

final class BitmapIndexedMapNode<Key, Value>: ManagedBuffer<Header, Element>, MapNode where Key: Hashable {

    var dataMap: Bitmap {
        get {
            self.withUnsafeMutablePointerToHeader {
                let (bitmap1, bitmap2) = $0.pointee
                return bitmap1 ^ (bitmap1 & bitmap2)
            }
        }
        set(dataMap) {
            self.withUnsafeMutablePointerToHeader {
                let (_, bitmap2) = $0.pointee
                $0.initialize(to: (dataMap ^ collMap, bitmap2))
           }
        }
    }

    var nodeMap: Bitmap {
        get {
            self.withUnsafeMutablePointerToHeader {
                let (bitmap1, bitmap2) = $0.pointee
                return bitmap2 ^ (bitmap1 & bitmap2)
            }
        }
        set(nodeMap) {
            self.withUnsafeMutablePointerToHeader {
                let (bitmap1, _) = $0.pointee
                $0.initialize(to: (bitmap1, nodeMap ^ collMap))
           }
        }
    }

    var collMap: Bitmap {
        get {
            self.withUnsafeMutablePointerToHeader {
                let (bitmap1, bitmap2) = $0.pointee
                return bitmap1 & bitmap2
            }
        }
        set(collMap) {
            // be careful when referencing `dataMap` or `nodeMap`, since both have a dependency on `collMap`

            self.withUnsafeMutablePointerToHeader {
                var (bitmap1, bitmap2) = $0.pointee

                bitmap1 ^= self.collMap
                bitmap2 ^= self.collMap

                bitmap1 ^= collMap
                bitmap2 ^= collMap

                $0.initialize(to: (bitmap1, bitmap2))
           }
        }
    }

//    static func create(_ dataMap: Bitmap, _ nodeMap: Bitmap, _ collMap: Bitmap, _ content: Storage) -> Self {
//        self.bitmap1 = dataMap ^ collMap
//        self.bitmap2 = nodeMap ^ collMap
//        self.content = content
//
////        assert(contentInvariant)
////        assert(count - payloadArity >= 2 * nodeArity)
//    }


    func clone() -> Self {
//        Self.create(minimumCapacity: capacity).
//
//
//        return Self.create(minimumCapacity: capacity) { newBuffer in
//            newBuffer.withUnsafeMutablePointerToElements { newElements -> Void in
//                newElements.initialize(from: elements, count: capacity)
//            }
//        } as! Self

//        return self.withUnsafeMutablePointerToElements { elements in
//            return Self.create(minimumCapacity: capacity) { newBuffer in
//                newBuffer.withUnsafeMutablePointerToElements { newElements -> Void in
//                    newElements.initialize(from: elements, count: capacity)
//                }
//            } as! Self
//        }
        return self
    }

    var content: UnsafeMutablePointer<Element> {
        self.withUnsafeMutablePointerToElements { return $0 }
    }

    var contentInvariant: Bool {
        dataSliceInvariant && nodeSliceInvariant && collSliceInvariant
    }

    var dataSliceInvariant: Bool {
        (0 ..< payloadArity).allSatisfy { index in content[index] is ReturnPayload }
    }

    var nodeSliceInvariant: Bool {
        (0 ..< bitmapIndexedNodeArity).allSatisfy { index in content[capacity - 1 - index] is ReturnBitmapIndexedNode }
    }

    var collSliceInvariant: Bool {
        (0 ..< hashCollisionNodeArity).allSatisfy { index in content[capacity - 1 - bitmapIndexedNodeArity - index] is ReturnHashCollisionNode }
    }

    // func capacity() -> Int { fixedCapacity }

    static func create() -> Self {
        Self.create(minimumCapacity: fixedCapacity) { _ in (0, 0) } as! Self
    }

    static func create(dataMap: Bitmap, firstKey: Key, firstValue: Value) -> Self {
        let result = Self.create(minimumCapacity: fixedCapacity) { _ in (dataMap, 0) }
        result.withUnsafeMutablePointerToElements {
            $0.initialize(to: (firstKey, firstValue))
        }
        return result as! Self
    }

    static func create(dataMap: Bitmap, firstKey: Key, firstValue: Value, secondKey: Key, secondValue: Value) -> Self {
        let result = Self.create(minimumCapacity: fixedCapacity) { _ in (dataMap, 0) }
        result.withUnsafeMutablePointerToElements {
            $0.initialize(to: (firstKey, firstValue))
            $0.successor().initialize(to: (secondKey, secondValue))
        }
        return result as! Self
    }

    static func create(nodeMap: Bitmap, firstNode: BitmapIndexedMapNode<Key, Value>) -> Self {
        let result = Self.create(minimumCapacity: fixedCapacity) { _ in (0, nodeMap) }
        result.withUnsafeMutablePointerToElements {
            $0.advanced(by: result.capacity - 1).initialize(to: firstNode)
        }
        return result as! Self
    }

    static func create(collMap: Bitmap, firstNode: HashCollisionMapNode<Key, Value>) -> Self {
        let result = Self.create(minimumCapacity: fixedCapacity) { _ in (collMap, collMap) }
        result.withUnsafeMutablePointerToElements {
            $0.advanced(by: result.capacity - 1).initialize(to: firstNode)
        }
        return result as! Self
    }

    static func create(dataMap: Bitmap, collMap: Bitmap, firstKey: Key, firstValue: Value, firstNode: HashCollisionMapNode<Key, Value>) -> Self {
        let result = Self.create(minimumCapacity: fixedCapacity) { _ in (dataMap | collMap, collMap) }
        result.withUnsafeMutablePointerToElements {
            $0.initialize(to: (firstKey, firstValue))
            $0.advanced(by: result.capacity - 1).initialize(to: firstNode)
        }
        return result as! Self
    }

    var count: Int {
        self.reduce(0, { count, _ in count + 1 })
    }

    func get(_ key: Key, _ keyHash: Int, _ shift: Int) -> Value? {
        let mask = maskFrom(keyHash, shift)
        let bitpos = bitposFrom(mask)

        guard (dataMap & bitpos) == 0 else {
            let index = indexFrom(dataMap, mask, bitpos)
            let payload = self.getPayload(index)
            return key == payload.key ? payload.value : nil
        }

        guard (nodeMap & bitpos) == 0 else {
            let index = indexFrom(nodeMap, mask, bitpos)
            return self.getBitmapIndexedNode(index).get(key, keyHash, shift + bitPartitionSize)
        }

        guard (collMap & bitpos) == 0 else {
            let index = indexFrom(collMap, mask, bitpos)
            return self.getHashCollisionNode(index).get(key, keyHash, shift + bitPartitionSize)
        }

        return nil
    }

    func containsKey(_ key: Key, _ keyHash: Int, _ shift: Int) -> Bool {
        let mask = maskFrom(keyHash, shift)
        let bitpos = bitposFrom(mask)

        guard (dataMap & bitpos) == 0 else {
            let index = indexFrom(dataMap, mask, bitpos)
            let payload = self.getPayload(index)
            return key == payload.key
        }

        guard (nodeMap & bitpos) == 0 else {
            let index = indexFrom(nodeMap, mask, bitpos)
            return self.getBitmapIndexedNode(index).containsKey(key, keyHash, shift + bitPartitionSize)
        }

        guard (collMap & bitpos) == 0 else {
            let index = indexFrom(collMap, mask, bitpos)
            return self.getHashCollisionNode(index).containsKey(key, keyHash, shift + bitPartitionSize)
        }

        return false
    }

    func updateOrUpdating(_ isStorageKnownUniquelyReferenced: Bool, _ key: Key, _ value: Value, _ keyHash: Int, _ shift: Int, _ effect: inout MapEffect) -> BitmapIndexedMapNode<Key, Value> {
        let mask = maskFrom(keyHash, shift)
        let bitpos = bitposFrom(mask)

        let dataMap = self.dataMap
        guard (dataMap & bitpos) == 0 else {
            let index = indexFrom(dataMap, mask, bitpos)
            let (key0, value0) = self.getPayload(index)

            if key0 == key {
                effect.setReplacedValue()
                return copyAndSetValue(isStorageKnownUniquelyReferenced, bitpos, value)
            } else {
                let keyHash0 = computeHash(key0)

                if keyHash0 == keyHash {
                    let subNodeNew = HashCollisionMapNode(keyHash0, [(key0, value0), (key, value)])
                    effect.setModified()
                    return copyAndMigrateFromInlineToCollisionNode(isStorageKnownUniquelyReferenced, bitpos, subNodeNew)
                } else {
                    let subNodeNew = mergeTwoKeyValPairs(key0, value0, keyHash0, key, value, keyHash, shift + bitPartitionSize)
                    effect.setModified()
                    return copyAndMigrateFromInlineToNode(isStorageKnownUniquelyReferenced, bitpos, subNodeNew)
                }
            }
        }

        let nodeMap = self.nodeMap
        guard (nodeMap & bitpos) == 0 else {
            let index = indexFrom(nodeMap, mask, bitpos)
            let subNodeModifyInPlace = self.isBitmapIndexedNodeKnownUniquelyReferenced(index, isStorageKnownUniquelyReferenced)
            let subNode = self.getBitmapIndexedNode(index)

            let subNodeNew = subNode.updateOrUpdating(subNodeModifyInPlace, key, value, keyHash, shift + bitPartitionSize, &effect)
            guard effect.modified && subNode !== subNodeNew else { return self }

            return copyAndSetBitmapIndexedNode(isStorageKnownUniquelyReferenced, bitpos, subNodeNew)
        }

        let collMap = self.collMap
        guard (collMap & bitpos) == 0 else {
            let index = indexFrom(collMap, mask, bitpos)
            let subNodeModifyInPlace = self.isHashCollisionNodeKnownUniquelyReferenced(index, isStorageKnownUniquelyReferenced)
            let subNode = self.getHashCollisionNode(index)

            let collisionHash = subNode.hash

            if keyHash == collisionHash {
                let subNodeNew = subNode.updateOrUpdating(subNodeModifyInPlace, key, value, keyHash, shift + bitPartitionSize, &effect)
                guard effect.modified && subNode !== subNodeNew else { return self }

                return copyAndSetHashCollisionNode(isStorageKnownUniquelyReferenced, bitpos, subNodeNew)
            } else {
                let subNodeNew = mergeKeyValPairAndCollisionNode(key, value, keyHash, subNode, collisionHash, shift + bitPartitionSize)
                effect.setModified()
                return copyAndMigrateFromCollisionNodeToNode(isStorageKnownUniquelyReferenced, bitpos, subNodeNew)
            }
        }

        effect.setModified()
        return copyAndInsertValue(isStorageKnownUniquelyReferenced, bitpos, key, value)
    }

    func removeOrRemoving(_ isStorageKnownUniquelyReferenced: Bool, _ key: Key, _ keyHash: Int, _ shift: Int, _ effect: inout MapEffect) -> BitmapIndexedMapNode<Key, Value> {
        let mask = maskFrom(keyHash, shift)
        let bitpos = bitposFrom(mask)

        guard (dataMap & bitpos) == 0 else {
            let index = indexFrom(dataMap, mask, bitpos)
            let (key0, _) = self.getPayload(index)
            guard key0 == key else { return self }

            effect.setModified()
            // TODO check globally usage of `bitmapIndexedNodeArity` and `hashCollisionNodeArity`
            if self.payloadArity == 2 && self.bitmapIndexedNodeArity == 0 && self.hashCollisionNodeArity == 0 {
                if shift == 0 {
                    // keep remaining pair on root level
                    let newDataMap = (dataMap ^ bitpos)
                    let (remainingKey, remainingValue) = getPayload(1 - index)
                    return Self.create(dataMap: newDataMap, firstKey: remainingKey, firstValue: remainingValue)
                } else {
                    // create potential new root: will a) become new root, or b) inlined on another level
                    let newDataMap = bitposFrom(maskFrom(keyHash, 0))
                    let (remainingKey, remainingValue) = getPayload(1 - index)
                    return Self.create(dataMap: newDataMap, firstKey: remainingKey, firstValue: remainingValue)
                }
            } else if self.payloadArity == 1 && self.bitmapIndexedNodeArity == 0 && self.hashCollisionNodeArity == 1 {
                // create potential new root: will a) become new root, or b) unwrapped on another level
                let newCollMap: Bitmap = bitposFrom(maskFrom(getHashCollisionNode(0).hash, 0))
                return Self.create(collMap: newCollMap, firstNode: getHashCollisionNode(0))
            } else { return copyAndRemoveValue(isStorageKnownUniquelyReferenced, bitpos) }
        }

        guard (nodeMap & bitpos) == 0 else {
            let index = indexFrom(nodeMap, mask, bitpos)
            let subNodeModifyInPlace = self.isBitmapIndexedNodeKnownUniquelyReferenced(index, isStorageKnownUniquelyReferenced)
            let subNode = self.getBitmapIndexedNode(index)

            let subNodeNew = subNode.removeOrRemoving(subNodeModifyInPlace, key, keyHash, shift + bitPartitionSize, &effect)
            guard effect.modified else { return self }

            switch subNodeNew.sizePredicate {
            case .sizeEmpty:
                preconditionFailure("Sub-node must have at least one element.")

            case .sizeOne:
                assert(self.bitmapIndexedNodeArity >= 1)

                if self.isCandiateForCompaction {
                    // escalate singleton
                    return subNodeNew
                } else {
                    // inline singleton
                    return copyAndMigrateFromNodeToInline(isStorageKnownUniquelyReferenced, bitpos, subNodeNew.getPayload(0))
                }

            case .sizeMoreThanOne:
                assert(self.bitmapIndexedNodeArity >= 1)

                if (subNodeNew.isWrappingSingleHashCollisionNode) {
                    if self.isCandiateForCompaction {
                        // escalate node that has only a single hash-collision sub-node
                        return subNodeNew
                    } else {
                        // unwrap hash-collision sub-node
                        return copyAndMigrateFromNodeToCollisionNode(isStorageKnownUniquelyReferenced, bitpos, subNodeNew.getHashCollisionNode(0))
                    }
                }

                // modify current node (set replacement node)
                return copyAndSetBitmapIndexedNode(isStorageKnownUniquelyReferenced, bitpos, subNodeNew)
            }
        }

        guard (collMap & bitpos) == 0 else {
            let index = indexFrom(collMap, mask, bitpos)
            let subNodeModifyInPlace = self.isHashCollisionNodeKnownUniquelyReferenced(index, isStorageKnownUniquelyReferenced)
            let subNode = self.getHashCollisionNode(index)

            let subNodeNew = subNode.removeOrRemoving(subNodeModifyInPlace, key, keyHash, shift + bitPartitionSize, &effect)
            guard effect.modified else { return self }

            switch subNodeNew.sizePredicate {
            case .sizeEmpty:
                preconditionFailure("Sub-node must have at least one element.")

            case .sizeOne:
                // TODO simplify hash-collision compaction (if feasible)
                if self.isCandiateForCompaction {
                    // escalate singleton
                    // convert `HashCollisionMapNode` to `BitmapIndexedMapNode` (logic moved/inlined from `HashCollisionMapNode`)
                    let newDataMap: Bitmap = bitposFrom(maskFrom(subNodeNew.hash, 0))
                    let (remainingKey, remainingValue) = subNodeNew.getPayload(0)
                    return Self.create(dataMap: newDataMap, firstKey: remainingKey, firstValue: remainingValue)
                } else {
                    // inline value
                    return copyAndMigrateFromCollisionNodeToInline(isStorageKnownUniquelyReferenced, bitpos, subNodeNew.getPayload(0))
                }

            case .sizeMoreThanOne:
                // modify current node (set replacement node)
                return copyAndSetHashCollisionNode(isStorageKnownUniquelyReferenced, bitpos, subNodeNew)
            }
        }

        return self
    }

    var isCandiateForCompaction: Bool { payloadArity == 0 && nodeArity == 1 }

    var isWrappingSingleHashCollisionNode: Bool { payloadArity == 0 && bitmapIndexedNodeArity == 0 && hashCollisionNodeArity == 1 }

    func mergeTwoKeyValPairs(_ key0: Key, _ value0: Value, _ keyHash0: Int, _ key1: Key, _ value1: Value, _ keyHash1: Int, _ shift: Int) -> BitmapIndexedMapNode<Key, Value> {
        assert(keyHash0 != keyHash1)

        let mask0 = maskFrom(keyHash0, shift)
        let mask1 = maskFrom(keyHash1, shift)

        if mask0 != mask1 {
            // unique prefixes, payload fits on same level
            if mask0 < mask1 {
                return Self.create(dataMap: bitposFrom(mask0) | bitposFrom(mask1), firstKey: key0, firstValue: value0, secondKey: key1, secondValue: value1)
            } else {
                return Self.create(dataMap: bitposFrom(mask1) | bitposFrom(mask0), firstKey: key1, firstValue: value1, secondKey: key0, secondValue: value0)
            }
        } else {
            // recurse: identical prefixes, payload must be disambiguated deeper in the trie
            let node = mergeTwoKeyValPairs(key0, value0, keyHash0, key1, value1, keyHash1, shift + bitPartitionSize)

            return Self.create(nodeMap: bitposFrom(mask0), firstNode: node)
        }
    }

    func mergeKeyValPairAndCollisionNode(_ key0: Key, _ value0: Value, _ keyHash0: Int, _ node1: HashCollisionMapNode<Key, Value>, _ nodeHash1: Int, _ shift: Int) -> BitmapIndexedMapNode<Key, Value> {
        assert(keyHash0 != nodeHash1)

        let mask0 = maskFrom(keyHash0, shift)
        let mask1 = maskFrom(nodeHash1, shift)

        if mask0 != mask1 {
            // unique prefixes, payload and collision node fit on same level
            return Self.create(dataMap: bitposFrom(mask0), collMap: bitposFrom(mask1), firstKey: key0, firstValue: value0, firstNode: node1)
        } else {
            // recurse: identical prefixes, payload must be disambiguated deeper in the trie
            let node = mergeKeyValPairAndCollisionNode(key0, value0, keyHash0, node1, nodeHash1, shift + bitPartitionSize)

            return Self.create(nodeMap: bitposFrom(mask0), firstNode: node)
        }
    }

    var hasBitmapIndexedNodes: Bool { nodeMap != 0 }

    var bitmapIndexedNodeArity: Int { nodeMap.nonzeroBitCount }

    func getBitmapIndexedNode(_ index: Int) -> BitmapIndexedMapNode<Key, Value> {
        content[capacity - 1 - index] as! BitmapIndexedMapNode<Key, Value>
    }

    private func isBitmapIndexedNodeKnownUniquelyReferenced(_ index: Int, _ isParentNodeKnownUniquelyReferenced: Bool) -> Bool {
        let slotIndex = capacity - 1 - index
        return isTrieNodeKnownUniquelyReferenced(slotIndex, isParentNodeKnownUniquelyReferenced)
    }

    private func isHashCollisionNodeKnownUniquelyReferenced(_ index: Int, _ isParentNodeKnownUniquelyReferenced: Bool) -> Bool {
        let slotIndex = capacity - 1 - bitmapIndexedNodeArity - index
        return isTrieNodeKnownUniquelyReferenced(slotIndex, isParentNodeKnownUniquelyReferenced)
    }

    private func isTrieNodeKnownUniquelyReferenced(_ slotIndex: Int, _ isParentNodeKnownUniquelyReferenced: Bool) -> Bool {
        let isKnownUniquelyReferenced = self.withUnsafeMutablePointerToElements { elements in
            elements.advanced(by: slotIndex).withMemoryRebound(to: AnyObject.self, capacity: 1) { pointer in
                Swift.isKnownUniquelyReferenced(&pointer.pointee)
            }
        }

        return isParentNodeKnownUniquelyReferenced && isKnownUniquelyReferenced
    }

    var hasHashCollisionNodes: Bool { collMap != 0 }

    var hashCollisionNodeArity: Int { collMap.nonzeroBitCount }

    func getHashCollisionNode(_ index: Int) -> HashCollisionMapNode<Key, Value> {
        return content[capacity - 1 - bitmapIndexedNodeArity - index] as! HashCollisionMapNode<Key, Value>
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

    func getPayload(_ index: Int) -> (key: Key, value: Value) { content[index] as! ReturnPayload }

    var sizePredicate: SizePredicate { SizePredicate(self) }

    func dataIndex(_ bitpos: Bitmap) -> Int { (dataMap & (bitpos &- 1)).nonzeroBitCount }

    func nodeIndex(_ bitpos: Bitmap) -> Int { (nodeMap & (bitpos &- 1)).nonzeroBitCount }

    func collIndex(_ bitpos: Bitmap) -> Int { (collMap & (bitpos &- 1)).nonzeroBitCount }

    func copyAndSetValue(_ isStorageKnownUniquelyReferenced: Bool, _ bitpos: Bitmap, _ newValue: Value) -> BitmapIndexedMapNode<Key, Value> {
        let idx = dataIndex(bitpos)
        let (key, _) = self.content[idx] as! ReturnPayload

//        if isStorageKnownUniquelyReferenced {
            // no copying if already editable
            self.content[idx] = (key, newValue)

            assert(contentInvariant)
            return self
//        } else {
//            var dst = self.content
//            dst[idx] = (key, newValue)
//
//            return BitmapIndexedMapNode(dataMap, nodeMap, collMap, dst)
//        }
    }

    func copyAndSetBitmapIndexedNode(_ isStorageKnownUniquelyReferenced: Bool, _ bitpos: Bitmap, _ newNode: BitmapIndexedMapNode<Key, Value>) -> BitmapIndexedMapNode<Key, Value> {
        let idx = capacity - 1 - self.nodeIndex(bitpos)
        return copyAndSetTrieNode(isStorageKnownUniquelyReferenced, bitpos, idx, newNode)
    }

    func copyAndSetHashCollisionNode(_ isStorageKnownUniquelyReferenced: Bool, _ bitpos: Bitmap, _ newNode: HashCollisionMapNode<Key, Value>) -> BitmapIndexedMapNode<Key, Value> {
        let idx = capacity - 1 - bitmapIndexedNodeArity - self.collIndex(bitpos)
        return copyAndSetTrieNode(isStorageKnownUniquelyReferenced, bitpos, idx, newNode)
    }

    private func copyAndSetTrieNode<T: MapNode>(_ isStorageKnownUniquelyReferenced: Bool, _ bitpos: Bitmap, _ idx: Int, _ newNode: T) -> BitmapIndexedMapNode<Key, Value> {
//        if isStorageKnownUniquelyReferenced {
            // no copying if already editable
            self.content[idx] = newNode

            assert(contentInvariant)
            return self
//        } else {
//            var dst = self.content
//            dst[idx] = newNode
//
//            return BitmapIndexedMapNode(dataMap, nodeMap, collMap, dst)
//        }
    }

    func copyAndInsertValue(_ isStorageKnownUniquelyReferenced: Bool, _ bitpos: Bitmap, _ key: Key, _ value: Value) -> BitmapIndexedMapNode<Key, Value> {
//        if isStorageKnownUniquelyReferenced {
            self.withUnsafeMutablePointers { header, elements in
                let (bitmap1, bitmap2) = header.pointee
                let dataMap = bitmap1 ^ (bitmap1 & bitmap2)

                let idx = indexFrom(dataMap, bitpos)
                let cnt = dataMap.nonzeroBitCount

                let elementsAtIdx = elements.advanced(by: idx)

                // shift to right
                elementsAtIdx.successor().moveInitialize(from: elementsAtIdx, count: cnt - idx)

                // insert
                elementsAtIdx.initialize(to: (key, value))

                // update metadata
                header.initialize(to: (bitmap1 | bitpos, bitmap2))
            }

            assert(contentInvariant)
            return self
//        } else {
//            var dst = self.content
//            dst.insert((key, value), at: idx)
//
//            return BitmapIndexedMapNode(dataMap | bitpos, nodeMap, collMap, dst)
//        }
    }

    func copyAndRemoveValue(_ isStorageKnownUniquelyReferenced: Bool, _ bitpos: Bitmap) -> BitmapIndexedMapNode<Key, Value> {
//        let idx = dataIndex(bitpos)
//
//        if isStorageKnownUniquelyReferenced {
//            self.dataMap ^= bitpos
//            self.content.remove(at: idx)
//
//            assert(contentInvariant)
//            return self
//        } else {
//            var dst = self.content
//            dst.remove(at: idx)
//
//            return BitmapIndexedMapNode(dataMap ^ bitpos, nodeMap, collMap, dst)
//        }
        preconditionFailure()
    }

    func copyAndMigrateFromInlineToNode(_ isStorageKnownUniquelyReferenced: Bool, _ bitpos: Bitmap, _ node: BitmapIndexedMapNode<Key, Value>) -> BitmapIndexedMapNode<Key, Value> {
        // let idxOld = dataIndex(bitpos)
        // let idxNew = capacity - 1 /* tupleLength */ - nodeIndex(bitpos)

//        if isStorageKnownUniquelyReferenced {
            self.withUnsafeMutablePointers { header, elements in
                let (bitmap1, bitmap2) = header.pointee
                let dataMap = bitmap1 ^ (bitmap1 & bitmap2)
                let nodeMap = bitmap2 ^ (bitmap1 & bitmap2)

                let idxOld = indexFrom(dataMap, bitpos)
                let idxNew = capacity - 1 /* tupleLength */ - indexFrom(nodeMap, bitpos)

                let elementsAtIdx = elements.advanced(by: idxOld)

                // shift to left
                elementsAtIdx.moveInitialize(from: elementsAtIdx.successor(), count: idxNew - idxOld)

                // insert
                // elementsAtIdx.initialize(to: (key, value))
                elements.advanced(by: idxNew).initialize(to: node)

                // update metadata
                header.initialize(to: (bitmap1 ^ bitpos, bitmap2 | bitpos))
            }

            assert(contentInvariant)
            return self
//        } else {
//            var dst = self.content
//            dst.remove(at: idxOld)
//            dst.insert(node, at: idxNew)
//
//            return BitmapIndexedMapNode(dataMap ^ bitpos, nodeMap | bitpos, collMap, dst)
//        }
    }

    func copyAndMigrateFromInlineToCollisionNode(_ isStorageKnownUniquelyReferenced: Bool, _ bitpos: Bitmap, _ node: HashCollisionMapNode<Key, Value>) -> BitmapIndexedMapNode<Key, Value> {
//        let idxOld = dataIndex(bitpos)
//        let idxNew = capacity - 1 /* tupleLength */ - bitmapIndexedNodeArity - collIndex(bitpos)
//
//        if isStorageKnownUniquelyReferenced {
//            self.dataMap ^= bitpos
//            self.collMap |= bitpos
//
//            self.content.remove(at: idxOld)
//            self.content.insert(node, at: idxNew)
//
//            assert(contentInvariant)
//            return self
//        } else {
//            var dst = self.content
//            dst.remove(at: idxOld)
//            dst.insert(node, at: idxNew)
//
//            return BitmapIndexedMapNode(dataMap ^ bitpos, nodeMap, collMap | bitpos, dst)
//        }
        preconditionFailure()
    }

    func copyAndMigrateFromNodeToInline(_ isStorageKnownUniquelyReferenced: Bool, _ bitpos: Bitmap, _ tuple: (key: Key, value: Value)) -> BitmapIndexedMapNode<Key, Value> {
//        let idxOld = capacity - 1 - nodeIndex(bitpos)
//        let idxNew = dataIndex(bitpos)
//
//        if isStorageKnownUniquelyReferenced {
//            self.dataMap |= bitpos
//            self.nodeMap ^= bitpos
//
//            self.content.remove(at: idxOld)
//            self.content.insert(tuple, at: idxNew)
//
//            assert(contentInvariant)
//            return self
//        } else {
//            var dst = self.content
//            dst.remove(at: idxOld)
//            dst.insert(tuple, at: idxNew)
//
//            return BitmapIndexedMapNode(dataMap | bitpos, nodeMap ^ bitpos, collMap, dst)
//        }
        preconditionFailure()
    }

    func copyAndMigrateFromCollisionNodeToInline(_ isStorageKnownUniquelyReferenced: Bool, _ bitpos: Bitmap, _ tuple: (key: Key, value: Value)) -> BitmapIndexedMapNode<Key, Value> {
//        let idxOld = capacity - 1 - bitmapIndexedNodeArity - collIndex(bitpos)
//        let idxNew = dataIndex(bitpos)
//
//        if isStorageKnownUniquelyReferenced {
//            self.dataMap |= bitpos
//            self.collMap ^= bitpos
//
//            self.content.remove(at: idxOld)
//            self.content.insert(tuple, at: idxNew)
//
//            assert(contentInvariant)
//            return self
//        } else {
//            var dst = self.content
//            dst.remove(at: idxOld)
//            dst.insert(tuple, at: idxNew)
//
//            return BitmapIndexedMapNode(dataMap | bitpos, nodeMap, collMap ^ bitpos, dst)
//        }
        preconditionFailure()
    }

    func copyAndMigrateFromCollisionNodeToNode(_ isStorageKnownUniquelyReferenced: Bool, _ bitpos: Bitmap, _ node: BitmapIndexedMapNode<Key, Value>) -> BitmapIndexedMapNode<Key, Value> {
//        let idxOld = capacity - 1 - bitmapIndexedNodeArity - collIndex(bitpos)
//        let idxNew = capacity - 1 - nodeIndex(bitpos)
//
//        if isStorageKnownUniquelyReferenced {
//            self.nodeMap |= bitpos
//            self.collMap ^= bitpos
//
//            self.content.remove(at: idxOld)
//            self.content.insert(node, at: idxNew)
//
//            assert(contentInvariant)
//            return self
//        } else {
//            var dst = self.content
//            dst.remove(at: idxOld)
//            dst.insert(node, at: idxNew)
//
//            return BitmapIndexedMapNode(dataMap, nodeMap | bitpos, collMap ^ bitpos, dst)
//        }
        preconditionFailure()
    }

    func copyAndMigrateFromNodeToCollisionNode(_ isStorageKnownUniquelyReferenced: Bool, _ bitpos: Bitmap, _ node: HashCollisionMapNode<Key, Value>) -> BitmapIndexedMapNode<Key, Value> {
//        let idxOld = capacity - 1 - nodeIndex(bitpos)
//        let idxNew = capacity - 1 - (bitmapIndexedNodeArity - 1) - collIndex(bitpos)
//
//        if isStorageKnownUniquelyReferenced {
//            self.nodeMap ^= bitpos
//            self.collMap |= bitpos
//
//            self.content.remove(at: idxOld)
//            self.content.insert(node, at: idxNew)
//
//            assert(contentInvariant)
//            return self
//        } else {
//            var dst = self.content
//            dst.remove(at: idxOld)
//            dst.insert(node, at: idxNew)
//
//            return BitmapIndexedMapNode(dataMap, nodeMap ^ bitpos, collMap | bitpos, dst)
//        }
        preconditionFailure()
    }
}

extension BitmapIndexedMapNode: Equatable where Value: Equatable {
    static func == (lhs: BitmapIndexedMapNode<Key, Value>, rhs: BitmapIndexedMapNode<Key, Value>) -> Bool {
        lhs === rhs ||
            lhs.nodeMap == rhs.nodeMap &&
            lhs.dataMap == rhs.dataMap &&
            lhs.collMap == rhs.collMap &&
            deepContentEquality(lhs, rhs)
    }

    private static func deepContentEquality(_ lhs: BitmapIndexedMapNode<Key, Value>, _ rhs: BitmapIndexedMapNode<Key, Value>) -> Bool {
        for index in 0..<lhs.payloadArity {
            if lhs.getPayload(index) != rhs.getPayload(index) {
                return false
            }
        }

        for index in 0..<lhs.bitmapIndexedNodeArity {
            if lhs.getBitmapIndexedNode(index) != rhs.getBitmapIndexedNode(index) {
                return false
            }
        }

        for index in 0..<lhs.hashCollisionNodeArity {
            if lhs.getHashCollisionNode(index) != rhs.getHashCollisionNode(index) {
                return false
            }
        }

        return true
    }
}

extension BitmapIndexedMapNode: Sequence {
    public __consuming func makeIterator() -> MapKeyValueTupleIterator<Key, Value> {
        return MapKeyValueTupleIterator(rootNode: self)
    }
}
