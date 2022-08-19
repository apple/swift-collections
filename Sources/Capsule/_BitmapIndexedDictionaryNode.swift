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

fileprivate let initialDataCapacity: Capacity = 4
fileprivate let initialTrieCapacity: Capacity = 1

final class BitmapIndexedDictionaryNode<Key, Value>: DictionaryNode where Key: Hashable {

    typealias ReturnPayload = (key: Key, value: Value)

    typealias DataBufferElement = ReturnPayload // `ReturnPayload` or `Any`
    typealias TrieBufferElement = AnyObject

    var header: Header

    let dataCapacity: Capacity
    let trieCapacity: Capacity

    let dataBaseAddress: UnsafeMutablePointer<DataBufferElement>
    let trieBaseAddress: UnsafeMutablePointer<TrieBufferElement>

    private var rootBaseAddress: UnsafeMutableRawPointer { UnsafeMutableRawPointer(trieBaseAddress) }

    deinit {
        dataBaseAddress.deinitialize(count: header.dataCount)
        trieBaseAddress.deinitialize(count: header.trieCount)

        rootBaseAddress.deallocate()
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

    @inlinable
    static func _allocate(dataCapacity: Capacity, trieCapacity: Capacity) -> (dataBaseAddress: UnsafeMutablePointer<DataBufferElement>, trieBaseAddress: UnsafeMutablePointer<TrieBufferElement>) {
        let dataCapacityInBytes = Int(dataCapacity) * MemoryLayout<DataBufferElement>.stride
        let trieCapacityInBytes = Int(trieCapacity) * MemoryLayout<TrieBufferElement>.stride

        let memory = UnsafeMutableRawPointer.allocate(
            byteCount: dataCapacityInBytes + trieCapacityInBytes,
            alignment: Swift.max(MemoryLayout<DataBufferElement>.alignment, MemoryLayout<TrieBufferElement>.alignment))

        let dataBaseAddress = memory.advanced(by: trieCapacityInBytes).bindMemory(to: DataBufferElement.self, capacity: Int(dataCapacity))
        let trieBaseAddress = memory.bindMemory(to: TrieBufferElement.self, capacity: Int(trieCapacity))

        return (dataBaseAddress, trieBaseAddress)
    }

    func copy(withDataCapacityFactor dataCapacityFactor: Capacity = 1,
              withDataCapacityShrinkFactor dataCapacityShrinkFactor: Capacity = 1,
              withTrieCapacityFactor trieCapacityFactor: Capacity = 1,
              withTrieCapacityShrinkFactor trieCapacityShrinkFactor: Capacity = 1) -> Self {
        let src = self
        let dst = Self(dataCapacity: src.dataCapacity &* dataCapacityFactor / dataCapacityShrinkFactor, trieCapacity: src.trieCapacity &* trieCapacityFactor / trieCapacityShrinkFactor)

        dst.header = src.header
        dst.dataBaseAddress.initialize(from: src.dataBaseAddress, count: src.header.dataCount)
        dst.trieBaseAddress.initialize(from: src.trieBaseAddress, count: src.header.trieCount)

        assert(dst.invariant)
        return dst
    }

    var invariant: Bool {
        guard contentInvariant else {
            return false
        }

        guard recursiveCount - payloadArity >= 2 * nodeArity else {
            return false
        }

        return true
    }

    var contentInvariant: Bool {
        nodeSliceInvariant && collSliceInvariant
    }

    var nodeSliceInvariant: Bool {
        UnsafeMutableBufferPointer(start: trieBaseAddress, count: header.trieCount).prefix(header.nodeCount).allSatisfy { $0 is ReturnBitmapIndexedNode }
    }

    var collSliceInvariant: Bool {
        UnsafeMutableBufferPointer(start: trieBaseAddress, count: header.trieCount).suffix(header.collCount).allSatisfy { $0 is ReturnHashCollisionNode }
    }

    // TODO: should not materialize as `Array` for performance reasons
    var _dataSlice: [ReturnPayload] {
        UnsafeMutableBufferPointer(start: dataBaseAddress, count: header.dataCount).map { $0 }
    }

    // TODO: should not materialize as `Array` for performance reasons
    var _nodeSlice: [ReturnBitmapIndexedNode] {
        UnsafeMutableBufferPointer(start: trieBaseAddress, count: header.trieCount).prefix(header.nodeCount).map { $0 as! ReturnBitmapIndexedNode }
    }

    // TODO: should not materialize as `Array` for performance reasons
    var _collSlice: [ReturnHashCollisionNode] {
        UnsafeMutableBufferPointer(start: trieBaseAddress, count: header.trieCount).suffix(header.collCount).map { $0 as! ReturnHashCollisionNode }
    }

    init(dataCapacity: Capacity, trieCapacity: Capacity) {
        let (dataBaseAddress, trieBaseAddress) = Self._allocate(dataCapacity: dataCapacity, trieCapacity: trieCapacity)

        self.header = Header(bitmap1: 0, bitmap2: 0)
        self.dataBaseAddress = dataBaseAddress
        self.trieBaseAddress = trieBaseAddress

        self.dataCapacity = dataCapacity
        self.trieCapacity = trieCapacity

        assert(self.invariant)
    }

    convenience init() {
        self.init(dataCapacity: initialDataCapacity, trieCapacity: initialTrieCapacity)

        self.header = Header(bitmap1: 0, bitmap2: 0)

        assert(self.invariant)
    }

    convenience init(dataMap: Bitmap, firstKey: Key, firstValue: Value) {
        self.init()

        self.header = Header(bitmap1: dataMap, bitmap2: 0)

        self.dataBaseAddress.initialize(to: (firstKey, firstValue))

        assert(self.invariant)
    }

    convenience init(dataMap: Bitmap, firstKey: Key, firstValue: Value, secondKey: Key, secondValue: Value) {
        self.init()

        self.header = Header(bitmap1: dataMap, bitmap2: 0)

        self.dataBaseAddress.initialize(to: (firstKey, firstValue))
        self.dataBaseAddress.successor().initialize(to: (secondKey, secondValue))

        assert(self.invariant)
    }

    convenience init(nodeMap: Bitmap, firstNode: BitmapIndexedDictionaryNode<Key, Value>) {
        self.init()

        self.header = Header(bitmap1: 0, bitmap2: nodeMap)

        self.trieBaseAddress.initialize(to: firstNode)

        assert(self.invariant)
    }

    convenience init(collMap: Bitmap, firstNode: HashCollisionDictionaryNode<Key, Value>) {
        self.init()

        self.header = Header(bitmap1: collMap, bitmap2: collMap)

        self.trieBaseAddress.initialize(to: firstNode)

        assert(self.invariant)
    }

    convenience init(dataMap: Bitmap, collMap: Bitmap, firstKey: Key, firstValue: Value, firstNode: HashCollisionDictionaryNode<Key, Value>) {
        self.init()

        self.header = Header(bitmap1: dataMap | collMap, bitmap2: collMap)

        self.dataBaseAddress.initialize(to: (firstKey, firstValue))
        self.trieBaseAddress.initialize(to: firstNode)

        assert(self.invariant)
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

    func updateOrUpdating(_ isStorageKnownUniquelyReferenced: Bool, _ key: Key, _ value: Value, _ keyHash: Int, _ shift: Int, _ effect: inout DictionaryEffect) -> BitmapIndexedDictionaryNode<Key, Value> {
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
                    let subNodeNew = HashCollisionDictionaryNode(keyHash0, [(key0, value0), (key, value)])
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

    func removeOrRemoving(_ isStorageKnownUniquelyReferenced: Bool, _ key: Key, _ keyHash: Int, _ shift: Int, _ effect: inout DictionaryEffect) -> BitmapIndexedDictionaryNode<Key, Value> {
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
                    return Self(dataMap: newDataMap, firstKey: remainingKey, firstValue: remainingValue)
                } else {
                    // create potential new root: will a) become new root, or b) inlined on another level
                    let newDataMap = bitposFrom(maskFrom(keyHash, 0))
                    let (remainingKey, remainingValue) = getPayload(1 - index)
                    return Self(dataMap: newDataMap, firstKey: remainingKey, firstValue: remainingValue)
                }
            } else if self.payloadArity == 1 && self.bitmapIndexedNodeArity == 0 && self.hashCollisionNodeArity == 1 {
                // create potential new root: will a) become new root, or b) unwrapped on another level
                let newCollMap: Bitmap = bitposFrom(maskFrom(getHashCollisionNode(0).hash, 0))
                return Self(collMap: newCollMap, firstNode: getHashCollisionNode(0))
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
                    // convert `HashCollisionDictionaryNode` to `BitmapIndexedDictionaryNode` (logic moved/inlined from `HashCollisionDictionaryNode`)
                    let newDataMap: Bitmap = bitposFrom(maskFrom(subNodeNew.hash, 0))
                    let (remainingKey, remainingValue) = subNodeNew.getPayload(0)
                    return Self(dataMap: newDataMap, firstKey: remainingKey, firstValue: remainingValue)
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

    func mergeTwoKeyValPairs(_ key0: Key, _ value0: Value, _ keyHash0: Int, _ key1: Key, _ value1: Value, _ keyHash1: Int, _ shift: Int) -> BitmapIndexedDictionaryNode<Key, Value> {
        assert(keyHash0 != keyHash1)

        let mask0 = maskFrom(keyHash0, shift)
        let mask1 = maskFrom(keyHash1, shift)

        if mask0 != mask1 {
            // unique prefixes, payload fits on same level
            if mask0 < mask1 {
                return Self(dataMap: bitposFrom(mask0) | bitposFrom(mask1), firstKey: key0, firstValue: value0, secondKey: key1, secondValue: value1)
            } else {
                return Self(dataMap: bitposFrom(mask1) | bitposFrom(mask0), firstKey: key1, firstValue: value1, secondKey: key0, secondValue: value0)
            }
        } else {
            // recurse: identical prefixes, payload must be disambiguated deeper in the trie
            let node = mergeTwoKeyValPairs(key0, value0, keyHash0, key1, value1, keyHash1, shift + bitPartitionSize)

            return Self(nodeMap: bitposFrom(mask0), firstNode: node)
        }
    }

    func mergeKeyValPairAndCollisionNode(_ key0: Key, _ value0: Value, _ keyHash0: Int, _ node1: HashCollisionDictionaryNode<Key, Value>, _ nodeHash1: Int, _ shift: Int) -> BitmapIndexedDictionaryNode<Key, Value> {
        assert(keyHash0 != nodeHash1)

        let mask0 = maskFrom(keyHash0, shift)
        let mask1 = maskFrom(nodeHash1, shift)

        if mask0 != mask1 {
            // unique prefixes, payload and collision node fit on same level
            return Self(dataMap: bitposFrom(mask0), collMap: bitposFrom(mask1), firstKey: key0, firstValue: value0, firstNode: node1)
        } else {
            // recurse: identical prefixes, payload must be disambiguated deeper in the trie
            let node = mergeKeyValPairAndCollisionNode(key0, value0, keyHash0, node1, nodeHash1, shift + bitPartitionSize)

            return Self(nodeMap: bitposFrom(mask0), firstNode: node)
        }
    }

    var hasBitmapIndexedNodes: Bool { header.nodeMap != 0 }

    var bitmapIndexedNodeArity: Int { header.nodeCount }

    func getBitmapIndexedNode(_ index: Int) -> BitmapIndexedDictionaryNode<Key, Value> {
        trieBaseAddress[index] as! BitmapIndexedDictionaryNode<Key, Value>
    }

    private func isBitmapIndexedNodeKnownUniquelyReferenced(_ index: Int, _ isParentNodeKnownUniquelyReferenced: Bool) -> Bool {
        let slotIndex = index
        return isTrieNodeKnownUniquelyReferenced(slotIndex, isParentNodeKnownUniquelyReferenced)
    }

    private func isHashCollisionNodeKnownUniquelyReferenced(_ index: Int, _ isParentNodeKnownUniquelyReferenced: Bool) -> Bool {
        let slotIndex = bitmapIndexedNodeArity + index
        return isTrieNodeKnownUniquelyReferenced(slotIndex, isParentNodeKnownUniquelyReferenced)
    }

    private func isTrieNodeKnownUniquelyReferenced(_ slotIndex: Int, _ isParentNodeKnownUniquelyReferenced: Bool) -> Bool {
        let isKnownUniquelyReferenced = Swift.isKnownUniquelyReferenced(&trieBaseAddress[slotIndex])

        return isParentNodeKnownUniquelyReferenced && isKnownUniquelyReferenced
    }

    var hasHashCollisionNodes: Bool { header.collMap != 0 }

    var hashCollisionNodeArity: Int { header.collCount }

    func getHashCollisionNode(_ index: Int) -> HashCollisionDictionaryNode<Key, Value> {
        trieBaseAddress[bitmapIndexedNodeArity + index] as! HashCollisionDictionaryNode<Key, Value>
    }

    // TODO rename, not accurate any more
    var hasNodes: Bool { header.trieMap != 0 }

    // TODO rename, not accurate any more
    var nodeArity: Int { header.trieCount }

    func getNode(_ index: Int) -> TrieNode<BitmapIndexedDictionaryNode<Key, Value>, HashCollisionDictionaryNode<Key, Value>> {
        if index < bitmapIndexedNodeArity {
            return .bitmapIndexed(getBitmapIndexedNode(index))
        } else {
            return .hashCollision(getHashCollisionNode(index))
        }
    }

    var hasPayload: Bool { header.dataMap != 0 }

    var payloadArity: Int { header.dataCount }

    func getPayload(_ index: Int) -> (key: Key, value: Value) {
        dataBaseAddress[index] // as! ReturnPayload
    }

    var sizePredicate: SizePredicate { SizePredicate(self) }

    func dataIndex(_ bitpos: Bitmap) -> Int { (dataMap & (bitpos &- 1)).nonzeroBitCount }

    func nodeIndex(_ bitpos: Bitmap) -> Int { (nodeMap & (bitpos &- 1)).nonzeroBitCount }

    func collIndex(_ bitpos: Bitmap) -> Int { (collMap & (bitpos &- 1)).nonzeroBitCount }

    func copyAndSetValue(_ isStorageKnownUniquelyReferenced: Bool, _ bitpos: Bitmap, _ newValue: Value) -> BitmapIndexedDictionaryNode<Key, Value> {
        let src: ReturnBitmapIndexedNode = self
        let dst: ReturnBitmapIndexedNode

        if isStorageKnownUniquelyReferenced {
            dst = src
        } else {
            dst = src.copy()
        }

        let idx = dataIndex(bitpos)

//        let (key, _) = dst.dataBuffer[idx] // as! ReturnPayload
//        dst.dataBuffer[idx] = (key, newValue)

        dst.dataBaseAddress[idx].value = newValue

        assert(dst.invariant)
        return dst
    }

    func copyAndSetBitmapIndexedNode(_ isStorageKnownUniquelyReferenced: Bool, _ bitpos: Bitmap, _ newNode: BitmapIndexedDictionaryNode<Key, Value>) -> BitmapIndexedDictionaryNode<Key, Value> {
        let idx = self.nodeIndex(bitpos)
        return copyAndSetTrieNode(isStorageKnownUniquelyReferenced, bitpos, idx, newNode)
    }

    func copyAndSetHashCollisionNode(_ isStorageKnownUniquelyReferenced: Bool, _ bitpos: Bitmap, _ newNode: HashCollisionDictionaryNode<Key, Value>) -> BitmapIndexedDictionaryNode<Key, Value> {
        let idx = bitmapIndexedNodeArity + self.collIndex(bitpos)
        return copyAndSetTrieNode(isStorageKnownUniquelyReferenced, bitpos, idx, newNode)
    }

    private func copyAndSetTrieNode<T: DictionaryNode>(_ isStorageKnownUniquelyReferenced: Bool, _ bitpos: Bitmap, _ idx: Int, _ newNode: T) -> BitmapIndexedDictionaryNode<Key, Value> {
        let src: ReturnBitmapIndexedNode = self
        let dst: ReturnBitmapIndexedNode

        if isStorageKnownUniquelyReferenced {
            dst = src
        } else {
            dst = src.copy()
        }

        dst.trieBaseAddress[idx] = newNode as TrieBufferElement

        assert(dst.invariant)
        return dst
    }

    func copyAndInsertValue(_ isStorageKnownUniquelyReferenced: Bool, _ bitpos: Bitmap, _ key: Key, _ value: Value) -> BitmapIndexedDictionaryNode<Key, Value> {
        let src: ReturnBitmapIndexedNode = self
        let dst: ReturnBitmapIndexedNode

        let hasRoomForData = header.dataCount < dataCapacity

        if isStorageKnownUniquelyReferenced && hasRoomForData {
            dst = src
        } else {
            dst = src.copy(withDataCapacityFactor: hasRoomForData ? 1 : 2)
        }

        let dataIdx = indexFrom(dataMap, bitpos)
        rangeInsert((key, value), at: dataIdx, into: dst.dataBaseAddress, count: dst.header.dataCount)

        // update metadata: `dataMap | bitpos, nodeMap, collMap`
        dst.header.bitmap1 |= bitpos

        assert(dst.invariant)
        return dst
    }

    func copyAndRemoveValue(_ isStorageKnownUniquelyReferenced: Bool, _ bitpos: Bitmap) -> BitmapIndexedDictionaryNode<Key, Value> {
        let src: ReturnBitmapIndexedNode = self
        let dst: ReturnBitmapIndexedNode

        if isStorageKnownUniquelyReferenced {
            dst = src
        } else {
            dst = src.copy()
        }

        let dataIdx = indexFrom(dataMap, bitpos)
        rangeRemove(at: dataIdx, from: dst.dataBaseAddress, count: dst.header.dataCount)

        // update metadata: `dataMap ^ bitpos, nodeMap, collMap`
        dst.header.bitmap1 ^= bitpos

        assert(dst.invariant)
        return dst
    }

    func copyAndMigrateFromInlineToNode(_ isStorageKnownUniquelyReferenced: Bool, _ bitpos: Bitmap, _ node: BitmapIndexedDictionaryNode<Key, Value>) -> BitmapIndexedDictionaryNode<Key, Value> {
        let src: ReturnBitmapIndexedNode = self
        let dst: ReturnBitmapIndexedNode

        let hasRoomForTrie = header.trieCount < trieCapacity

        if isStorageKnownUniquelyReferenced && hasRoomForTrie {
            dst = src
        } else {
            // TODO reconsider the details of the heuristic
            //
            // Since copying is necessary, check if the data section can be reduced.
            // Keep at mininum the initial capacity.
            //
            // Notes currently can grow to a maximum size of 48 (tuple and sub-node) slots.
            let tooMuchForData = Swift.max(header.dataCount * 2 - 1, 4) < dataCapacity
            
            dst = src.copy(withDataCapacityShrinkFactor: tooMuchForData ? 2 : 1, withTrieCapacityFactor: hasRoomForTrie ? 1 : 2)
        }

        let dataIdx = indexFrom(dataMap, bitpos)
        rangeRemove(at: dataIdx, from: dst.dataBaseAddress, count: dst.header.dataCount)

        let nodeIdx = indexFrom(nodeMap, bitpos)
        rangeInsert(node, at: nodeIdx, into: dst.trieBaseAddress, count: dst.header.trieCount)

        // update metadata: `dataMap ^ bitpos, nodeMap | bitpos, collMap`
        dst.header.bitmap1 ^= bitpos
        dst.header.bitmap2 |= bitpos

        assert(dst.invariant)
        return dst
    }

    func copyAndMigrateFromInlineToCollisionNode(_ isStorageKnownUniquelyReferenced: Bool, _ bitpos: Bitmap, _ node: HashCollisionDictionaryNode<Key, Value>) -> BitmapIndexedDictionaryNode<Key, Value> {
        let src: ReturnBitmapIndexedNode = self
        let dst: ReturnBitmapIndexedNode

        let hasRoomForTrie = header.trieCount < trieCapacity

        if isStorageKnownUniquelyReferenced && hasRoomForTrie {
            dst = src
        } else {
            dst = src.copy(withTrieCapacityFactor: hasRoomForTrie ? 1 : 2)
        }

        let dataIdx = indexFrom(dataMap, bitpos)
        rangeRemove(at: dataIdx, from: dst.dataBaseAddress, count: dst.header.dataCount)

        let collIdx = nodeMap.nonzeroBitCount + indexFrom(collMap, bitpos)
        rangeInsert(node, at: collIdx, into: dst.trieBaseAddress, count: dst.header.trieCount)

        // update metadata: `dataMap ^ bitpos, nodeMap, collMap | bitpos`
        dst.header.bitmap2 |= bitpos

        assert(dst.invariant)
        return dst
    }

    func copyAndMigrateFromNodeToInline(_ isStorageKnownUniquelyReferenced: Bool, _ bitpos: Bitmap, _ tuple: (key: Key, value: Value)) -> BitmapIndexedDictionaryNode<Key, Value> {
        let src: ReturnBitmapIndexedNode = self
        let dst: ReturnBitmapIndexedNode

        let hasRoomForData = header.dataCount < dataCapacity

        if isStorageKnownUniquelyReferenced && hasRoomForData {
            dst = src
        } else {
            dst = src.copy(withDataCapacityFactor: hasRoomForData ? 1 : 2)
        }

        let nodeIdx = indexFrom(nodeMap, bitpos)
        rangeRemove(at: nodeIdx, from: dst.trieBaseAddress, count: dst.header.trieCount)

        let dataIdx = indexFrom(dataMap, bitpos)
        rangeInsert(tuple, at: dataIdx, into: dst.dataBaseAddress, count: dst.header.dataCount)

        // update metadata: `dataMap | bitpos, nodeMap ^ bitpos, collMap`
        dst.header.bitmap1 |= bitpos
        dst.header.bitmap2 ^= bitpos

        assert(dst.invariant)
        return dst
    }

    func copyAndMigrateFromCollisionNodeToInline(_ isStorageKnownUniquelyReferenced: Bool, _ bitpos: Bitmap, _ tuple: (key: Key, value: Value)) -> BitmapIndexedDictionaryNode<Key, Value> {
        let src: ReturnBitmapIndexedNode = self
        let dst: ReturnBitmapIndexedNode

        let hasRoomForData = header.dataCount < dataCapacity

        if isStorageKnownUniquelyReferenced && hasRoomForData {
            dst = src
        } else {
            dst = src.copy(withDataCapacityFactor: hasRoomForData ? 1 : 2)
        }

        let collIdx = nodeMap.nonzeroBitCount + indexFrom(collMap, bitpos)
        rangeRemove(at: collIdx, from: dst.trieBaseAddress, count: dst.header.trieCount)

        let dataIdx = indexFrom(dataMap, bitpos)
        rangeInsert(tuple, at: dataIdx, into: dst.dataBaseAddress, count: dst.header.dataCount)

        // update metadata: `dataMap | bitpos, nodeMap, collMap ^ bitpos`
        dst.header.bitmap2 ^= bitpos

        assert(dst.invariant)
        return dst
    }

    func copyAndMigrateFromCollisionNodeToNode(_ isStorageKnownUniquelyReferenced: Bool, _ bitpos: Bitmap, _ node: BitmapIndexedDictionaryNode<Key, Value>) -> BitmapIndexedDictionaryNode<Key, Value> {
        let src: ReturnBitmapIndexedNode = self
        let dst: ReturnBitmapIndexedNode

        if isStorageKnownUniquelyReferenced {
            dst = src
        } else {
            dst = src.copy()
        }

        let collIdx = nodeMap.nonzeroBitCount + collIndex(bitpos)
        let nodeIdx = nodeIndex(bitpos)

        rangeRemove(at: collIdx, from: dst.trieBaseAddress, count: dst.header.trieCount)
        rangeInsert(node, at: nodeIdx, into: dst.trieBaseAddress, count: dst.header.trieCount - 1) // TODO check, but moving one less should be accurate

        // update metadata: `dataMap, nodeMap | bitpos, collMap ^ bitpos`
        dst.header.bitmap1 ^= bitpos

        assert(dst.invariant)
        return dst
    }

    func copyAndMigrateFromNodeToCollisionNode(_ isStorageKnownUniquelyReferenced: Bool, _ bitpos: Bitmap, _ node: HashCollisionDictionaryNode<Key, Value>) -> BitmapIndexedDictionaryNode<Key, Value> {
        let src: ReturnBitmapIndexedNode = self
        let dst: ReturnBitmapIndexedNode

        if isStorageKnownUniquelyReferenced {
            dst = src
        } else {
            dst = src.copy()
        }

        let nodeIdx = nodeIndex(bitpos)
        let collIdx = nodeMap.nonzeroBitCount - 1 + collIndex(bitpos)

        rangeRemove(at: nodeIdx, from: dst.trieBaseAddress, count: dst.header.trieCount)
        rangeInsert(node, at: collIdx, into: dst.trieBaseAddress, count: dst.header.trieCount - 1) // TODO check, but moving one less should be accurate

        // update metadata: `dataMap, nodeMap ^ bitpos, collMap | bitpos`
        dst.header.bitmap1 |= bitpos

        assert(dst.invariant)
        return dst
    }
}

extension BitmapIndexedDictionaryNode: Equatable where Value: Equatable {
    static func == (lhs: BitmapIndexedDictionaryNode<Key, Value>, rhs: BitmapIndexedDictionaryNode<Key, Value>) -> Bool {
        lhs === rhs ||
            lhs.nodeMap == rhs.nodeMap &&
            lhs.dataMap == rhs.dataMap &&
            lhs.collMap == rhs.collMap &&
            deepContentEquality(lhs, rhs)
    }

    private static func deepContentEquality(_ lhs: BitmapIndexedDictionaryNode<Key, Value>, _ rhs: BitmapIndexedDictionaryNode<Key, Value>) -> Bool {
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

extension BitmapIndexedDictionaryNode: Sequence {
    public __consuming func makeIterator() -> DictionaryKeyValueTupleIterator<Key, Value> {
        return DictionaryKeyValueTupleIterator(rootNode: self)
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

    var dataCount: Int { dataMap.nonzeroBitCount }

    var nodeCount: Int { nodeMap.nonzeroBitCount }

    var collCount: Int { collMap.nonzeroBitCount }

    var trieCount: Int { trieMap.nonzeroBitCount }
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
