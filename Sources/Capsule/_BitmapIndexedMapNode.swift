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

typealias Element = Any

fileprivate let initialMinimumCapacity = 4

final class BitmapIndexedMapNode<Key, Value>: ManagedBuffer<Header, Element>, MapNode where Key: Hashable {

    deinit {
        self.withUnsafeMutablePointerRanges { dataRange, trieRange in
            dataRange.startIndex.deinitialize(count: dataRange.count)
            trieRange.startIndex.deinitialize(count: trieRange.count)
        }
    }

    @inline(__always)
    var dataMap: Bitmap {
        header.dataMap
    }

    @inline(__always)
    var nodeMap: Bitmap {
        header.nodeMap
    }

    @inline(__always)
    var collMap: Bitmap {
        header.collMap
    }

    @inline(__always)
    func withUnsafeMutablePointerRanges<R>(transformRanges transform: (Range<UnsafeMutablePointer<Element>>, Range<UnsafeMutablePointer<Element>>) -> R) -> R {
        self.withUnsafeMutablePointerToElements { elements in
            let(dataCnt, trieCnt) = header.explodedMap { bitmap in bitmap.nonzeroBitCount }

            let range = elements ..< elements.advanced(by: capacity)

            let dataRange = range.prefix(dataCnt)
            let trieRange = range.suffix(trieCnt)

            return transform(dataRange, trieRange)
        }
    }

    func copy(withCapacityFactor factor: Int = 1) -> Self {
        let src = self
        let dst = Self.create(minimumCapacity: capacity * factor) { _ in header } as! Self

        src.withUnsafeMutablePointerRanges { srcDataRange, srcTrieRange in
            dst.withUnsafeMutablePointerRanges { dstDataRange, dstTrieRange in
                dstDataRange.startIndex.initialize(from: srcDataRange.startIndex, count: srcDataRange.count)
                dstTrieRange.startIndex.initialize(from: srcTrieRange.startIndex, count: srcTrieRange.count)
            }
        }

        return dst
    }

    var invariant: Bool {
        guard contentInvariant else {
            return false
        }

        guard recursiveCount - payloadArity >= 2 * nodeArity else {
            return false
        }

        guard count <= capacity else {
            return false
        }

        return true
    }

    var contentInvariant: Bool {
        dataSliceInvariant && nodeSliceInvariant && collSliceInvariant
    }

    var dataSliceInvariant: Bool {
        (0 ..< payloadArity).allSatisfy { index in getElement(index) is ReturnPayload }
    }

    var nodeSliceInvariant: Bool {
        (0 ..< bitmapIndexedNodeArity).allSatisfy { index in getElement(capacity - 1 - index) is ReturnBitmapIndexedNode }
    }

    var collSliceInvariant: Bool {
        (0 ..< hashCollisionNodeArity).allSatisfy { index in getElement(capacity - 1 - bitmapIndexedNodeArity - index) is ReturnHashCollisionNode }
    }

    static func create() -> Self {
        Self.create(minimumCapacity: initialMinimumCapacity) { _ in Header(bitmap1: 0, bitmap2: 0) } as! Self
    }

    static func create(dataMap: Bitmap, firstKey: Key, firstValue: Value) -> Self {
        let result = Self.create(minimumCapacity: initialMinimumCapacity) { _ in Header(bitmap1: dataMap, bitmap2: 0) }
        result.withUnsafeMutablePointerToElements {
            $0.initialize(to: (firstKey, firstValue))
        }
        return result as! Self
    }

    static func create(dataMap: Bitmap, firstKey: Key, firstValue: Value, secondKey: Key, secondValue: Value) -> Self {
        let result = Self.create(minimumCapacity: initialMinimumCapacity) { _ in Header(bitmap1: dataMap, bitmap2: 0) }
        result.withUnsafeMutablePointerToElements {
            $0.initialize(to: (firstKey, firstValue))
            $0.successor().initialize(to: (secondKey, secondValue))
        }
        return result as! Self
    }

    static func create(nodeMap: Bitmap, firstNode: BitmapIndexedMapNode<Key, Value>) -> Self {
        let result = Self.create(minimumCapacity: initialMinimumCapacity) { _ in Header(bitmap1: 0, bitmap2: nodeMap) }
        result.withUnsafeMutablePointerToElements {
            $0.advanced(by: result.capacity - 1).initialize(to: firstNode)
        }
        return result as! Self
    }

    static func create(collMap: Bitmap, firstNode: HashCollisionMapNode<Key, Value>) -> Self {
        let result = Self.create(minimumCapacity: initialMinimumCapacity) { _ in Header(bitmap1: collMap, bitmap2: collMap) }
        result.withUnsafeMutablePointerToElements {
            $0.advanced(by: result.capacity - 1).initialize(to: firstNode)
        }
        return result as! Self
    }

    static func create(dataMap: Bitmap, collMap: Bitmap, firstKey: Key, firstValue: Value, firstNode: HashCollisionMapNode<Key, Value>) -> Self {
        let result = Self.create(minimumCapacity: initialMinimumCapacity) { _ in Header(bitmap1: dataMap | collMap, bitmap2: collMap) }
        result.withUnsafeMutablePointerToElements {
            $0.initialize(to: (firstKey, firstValue))
            $0.advanced(by: result.capacity - 1).initialize(to: firstNode)
        }
        return result as! Self
    }

    var recursiveCount: Int {
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

        guard (nodeMap & bitpos) == 0 else {
            let index = indexFrom(nodeMap, mask, bitpos)
            let subNodeModifyInPlace = self.isBitmapIndexedNodeKnownUniquelyReferenced(index, isStorageKnownUniquelyReferenced)
            let subNode = self.getBitmapIndexedNode(index)

            let subNodeNew = subNode.updateOrUpdating(subNodeModifyInPlace, key, value, keyHash, shift + bitPartitionSize, &effect)
            guard effect.modified && subNode !== subNodeNew else { return self }

            return copyAndSetBitmapIndexedNode(isStorageKnownUniquelyReferenced, bitpos, subNodeNew)
        }

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
        getElement(capacity - 1 - index) as! BitmapIndexedMapNode<Key, Value>
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

    func getElement(_ index: Int) -> Element {
        self.withUnsafeMutablePointerToElements { elements in elements[index] }
    }

    var hasHashCollisionNodes: Bool { collMap != 0 }

    var hashCollisionNodeArity: Int { collMap.nonzeroBitCount }

    func getHashCollisionNode(_ index: Int) -> HashCollisionMapNode<Key, Value> {
        return getElement(capacity - 1 - bitmapIndexedNodeArity - index) as! HashCollisionMapNode<Key, Value>
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

    func getPayload(_ index: Int) -> (key: Key, value: Value) { getElement(index) as! ReturnPayload }

    var sizePredicate: SizePredicate { SizePredicate(self) }

    func dataIndex(_ bitpos: Bitmap) -> Int { (dataMap & (bitpos &- 1)).nonzeroBitCount }

    func nodeIndex(_ bitpos: Bitmap) -> Int { (nodeMap & (bitpos &- 1)).nonzeroBitCount }

    func collIndex(_ bitpos: Bitmap) -> Int { (collMap & (bitpos &- 1)).nonzeroBitCount }

    /// The number of (non-contiguous) occupied buffer cells.
    final var count: Int { (header.bitmap1 | header.bitmap2).nonzeroBitCount }

    func copyAndSetValue(_ isStorageKnownUniquelyReferenced: Bool, _ bitpos: Bitmap, _ newValue: Value) -> BitmapIndexedMapNode<Key, Value> {
        let src: ReturnBitmapIndexedNode = self
        let dst: ReturnBitmapIndexedNode

        if isStorageKnownUniquelyReferenced {
            dst = src
        } else {
            dst = src.copy()
        }

        let idx = dataIndex(bitpos)

        dst.withUnsafeMutablePointerToElements { elements in
            let (key, _) = elements[idx] as! ReturnPayload
            elements[idx] = (key, newValue)
        }

        assert(dst.invariant)
        return dst
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
        let src: ReturnBitmapIndexedNode = self
        let dst: ReturnBitmapIndexedNode

        if isStorageKnownUniquelyReferenced {
            dst = src
        } else {
            dst = src.copy()
        }

        dst.withUnsafeMutablePointerToElements { elements in
            elements[idx] = newNode
        }

        assert(dst.invariant)
        return dst
    }

    func copyAndInsertValue(_ isStorageKnownUniquelyReferenced: Bool, _ bitpos: Bitmap, _ key: Key, _ value: Value) -> BitmapIndexedMapNode<Key, Value> {
        let src: ReturnBitmapIndexedNode = self
        let dst: ReturnBitmapIndexedNode

        if isStorageKnownUniquelyReferenced && count < capacity {
            dst = src
        } else {
            dst = src.copy(withCapacityFactor: count < capacity ? 1 : 2)
        }

        dst.withUnsafeMutablePointerRanges { dataRange, _ in
            let dataIdx = indexFrom(dataMap, bitpos)
            rangeInsert((key, value), at: dataIdx, intoRange: dataRange)
        }

        // update metadata: `dataMap | bitpos, nodeMap, collMap`
        dst.header.bitmap1 |= bitpos

        assert(dst.invariant)
        return dst
    }

    func copyAndRemoveValue(_ isStorageKnownUniquelyReferenced: Bool, _ bitpos: Bitmap) -> BitmapIndexedMapNode<Key, Value> {
        let src: ReturnBitmapIndexedNode = self
        let dst: ReturnBitmapIndexedNode

        if isStorageKnownUniquelyReferenced {
            dst = src
        } else {
            dst = src.copy()
        }

        dst.withUnsafeMutablePointerRanges { dataRange, _ in
            let dataIdx = indexFrom(dataMap, bitpos)
            rangeRemove(at: dataIdx, fromRange: dataRange)
        }

        // update metadata: `dataMap ^ bitpos, nodeMap, collMap`
        dst.header.bitmap1 ^= bitpos

        assert(dst.invariant)
        return dst
    }

    func copyAndMigrateFromInlineToNode(_ isStorageKnownUniquelyReferenced: Bool, _ bitpos: Bitmap, _ node: BitmapIndexedMapNode<Key, Value>) -> BitmapIndexedMapNode<Key, Value> {
        let src: ReturnBitmapIndexedNode = self
        let dst: ReturnBitmapIndexedNode

        if isStorageKnownUniquelyReferenced {
            dst = src
        } else {
            dst = src.copy()
        }

        dst.withUnsafeMutablePointerRanges { dataRange, trieRange in
            let dataIdx = indexFrom(dataMap, bitpos)
            rangeRemove(at: dataIdx, fromRange: dataRange)

            let nodeIdx = indexFrom(nodeMap, bitpos)
            rangeInsertReversed(node, at: nodeIdx, intoRange: trieRange)
        }

        // update metadata: `dataMap ^ bitpos, nodeMap | bitpos, collMap`
        dst.header.bitmap1 ^= bitpos
        dst.header.bitmap2 |= bitpos

        assert(dst.invariant)
        return dst
    }

    func copyAndMigrateFromInlineToCollisionNode(_ isStorageKnownUniquelyReferenced: Bool, _ bitpos: Bitmap, _ node: HashCollisionMapNode<Key, Value>) -> BitmapIndexedMapNode<Key, Value> {
        let src: ReturnBitmapIndexedNode = self
        let dst: ReturnBitmapIndexedNode

        if isStorageKnownUniquelyReferenced {
            dst = src
        } else {
            dst = src.copy()
        }

        dst.withUnsafeMutablePointerRanges { dataRange, trieRange in
            let dataIdx = indexFrom(dataMap, bitpos)
            rangeRemove(at: dataIdx, fromRange: dataRange)

            let collIdx = nodeMap.nonzeroBitCount + indexFrom(collMap, bitpos)
            rangeInsertReversed(node, at: collIdx, intoRange: trieRange)
        }

        // update metadata: `dataMap ^ bitpos, nodeMap, collMap | bitpos`
        dst.header.bitmap2 |= bitpos

        assert(dst.invariant)
        return dst
    }

    func copyAndMigrateFromNodeToInline(_ isStorageKnownUniquelyReferenced: Bool, _ bitpos: Bitmap, _ tuple: (key: Key, value: Value)) -> BitmapIndexedMapNode<Key, Value> {
        let src: ReturnBitmapIndexedNode = self
        let dst: ReturnBitmapIndexedNode

        if isStorageKnownUniquelyReferenced {
            dst = src
        } else {
            dst = src.copy()
        }

        dst.withUnsafeMutablePointerRanges { dataRange, trieRange in
            let nodeIdx = indexFrom(nodeMap, bitpos)
            rangeRemoveReversed(at: nodeIdx, fromRange: trieRange)

            let dataIdx = indexFrom(dataMap, bitpos)
            rangeInsert(tuple, at: dataIdx, intoRange: dataRange)
        }

        // update metadata: `dataMap | bitpos, nodeMap ^ bitpos, collMap`
        dst.header.bitmap1 |= bitpos
        dst.header.bitmap2 ^= bitpos

        assert(dst.invariant)
        return dst
    }

    func copyAndMigrateFromCollisionNodeToInline(_ isStorageKnownUniquelyReferenced: Bool, _ bitpos: Bitmap, _ tuple: (key: Key, value: Value)) -> BitmapIndexedMapNode<Key, Value> {
        let src: ReturnBitmapIndexedNode = self
        let dst: ReturnBitmapIndexedNode

        if isStorageKnownUniquelyReferenced {
            dst = src
        } else {
            dst = src.copy()
        }

        dst.withUnsafeMutablePointerRanges { dataRange, trieRange in
            let collIdx = nodeMap.nonzeroBitCount + indexFrom(collMap, bitpos)
            rangeRemoveReversed(at: collIdx, fromRange: trieRange)

            let dataIdx = indexFrom(dataMap, bitpos)
            rangeInsert(tuple, at: dataIdx, intoRange: dataRange)
        }

        // update metadata: `dataMap | bitpos, nodeMap, collMap ^ bitpos`
        dst.header.bitmap2 ^= bitpos

        assert(dst.invariant)
        return dst
    }

    func copyAndMigrateFromCollisionNodeToNode(_ isStorageKnownUniquelyReferenced: Bool, _ bitpos: Bitmap, _ node: BitmapIndexedMapNode<Key, Value>) -> BitmapIndexedMapNode<Key, Value> {
        let src: ReturnBitmapIndexedNode = self
        let dst: ReturnBitmapIndexedNode

        if isStorageKnownUniquelyReferenced {
            dst = src
        } else {
            dst = src.copy()
        }

        dst.withUnsafeMutablePointerRanges { _, trieRange in
            let collIdx = nodeMap.nonzeroBitCount + collIndex(bitpos)
            let nodeIdx = nodeIndex(bitpos)

            rangeRemoveReversed(at: collIdx, fromRange: trieRange)
            rangeInsertReversed(node, at: nodeIdx, intoRange: trieRange)
        }

        // update metadata: `dataMap, nodeMap | bitpos, collMap ^ bitpos`
        dst.header.bitmap1 ^= bitpos

        assert(dst.invariant)
        return dst
    }

    func copyAndMigrateFromNodeToCollisionNode(_ isStorageKnownUniquelyReferenced: Bool, _ bitpos: Bitmap, _ node: HashCollisionMapNode<Key, Value>) -> BitmapIndexedMapNode<Key, Value> {
        let src: ReturnBitmapIndexedNode = self
        let dst: ReturnBitmapIndexedNode

        if isStorageKnownUniquelyReferenced {
            dst = src
        } else {
            dst = src.copy()
        }

        dst.withUnsafeMutablePointerRanges { _, trieRange in
            let nodeIdx = nodeIndex(bitpos)
            let collIdx = nodeMap.nonzeroBitCount - 1 + collIndex(bitpos)

            rangeRemoveReversed(at: nodeIdx, fromRange: trieRange)
            rangeInsertReversed(node, at: collIdx, intoRange: trieRange)
        }

        // update metadata: `dataMap, nodeMap ^ bitpos, collMap | bitpos`
        dst.header.bitmap1 |= bitpos

        assert(dst.invariant)
        return dst
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

struct Header {
    var bitmap1: Bitmap
    var bitmap2: Bitmap

    @inline(__always)
    var dataMap: Bitmap {
        bitmap1 & ~bitmap2
    }

    @inline(__always)
    var nodeMap: Bitmap {
        bitmap2 & ~bitmap1
    }

    @inline(__always)
    var collMap: Bitmap {
        bitmap1 & bitmap2
    }

    @inline(__always)
    var trieMap: Bitmap {
        bitmap2
    }
}

extension Header {
    @inline(__always)
    func exploded() -> (dataMap: Bitmap, nodeMap: Bitmap, collMap: Bitmap) {
        assert((dataMap | nodeMap | collMap).nonzeroBitCount == dataMap.nonzeroBitCount + nodeMap.nonzeroBitCount + collMap.nonzeroBitCount)

        return (dataMap, nodeMap, collMap)
    }

    @inline(__always)
    func exploded() -> (dataMap: Bitmap, trieMap: Bitmap) {
        assert((dataMap | trieMap).nonzeroBitCount == dataMap.nonzeroBitCount + trieMap.nonzeroBitCount)

        return (dataMap, trieMap)
    }

    @inline(__always)
    fileprivate func imploded(dataMap: Bitmap, nodeMap: Bitmap, collMap: Bitmap) -> Self {
        assert((dataMap | nodeMap | collMap).nonzeroBitCount == dataMap.nonzeroBitCount + nodeMap.nonzeroBitCount + collMap.nonzeroBitCount)

        return Self(bitmap1: dataMap ^ collMap, bitmap2: nodeMap ^ collMap)
    }

    @inline(__always)
    func map<T>(_ transform: (Self) -> T) -> T {
        return transform(self)
    }

    @inline(__always)
    func explodedMap<T>(_ transform: (Bitmap) -> T) -> (T, T) {
        return (transform(dataMap), transform(trieMap))
    }

    @inline(__always)
    func explodedMap<T>(_ transform: (Bitmap) -> T) -> (T, T, T) {
        return (transform(dataMap), transform(nodeMap), transform(collMap))
    }
}
