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
    var count: Int

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
    var trieMap: Bitmap {
        header.trieMap
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
        dst.count = src.count

        dst.dataBaseAddress.initialize(from: src.dataBaseAddress, count: src.header.dataCount)
        dst.trieBaseAddress.initialize(from: src.trieBaseAddress, count: src.header.trieCount)

        assert(src.invariant)
        assert(dst.invariant)
        return dst
    }

    var invariant: Bool {
        guard headerInvariant else {
            return false
        }

        let recursiveCount = self.reduce(0, { count, _ in count + 1 })

        guard recursiveCount == count else {
            return false
        }

        guard recursiveCount - payloadArity >= 2 * nodeArity else {
            return false
        }

        guard _trieSlice.allSatisfy({ _ in true /* TODO */ }) else {
            return false
        }

        return true
    }

    var headerInvariant: Bool {
        (header.dataMap & header.trieMap) == 0
    }

    // TODO: should not materialize as `Array` for performance reasons
    var _dataSlice: [DataBufferElement] {
        UnsafeMutableBufferPointer(start: dataBaseAddress, count: header.dataCount).map { $0 }
    }

    // TODO: should not materialize as `Array` for performance reasons
    var _trieSlice: [TrieBufferElement] {
        UnsafeMutableBufferPointer(start: trieBaseAddress, count: header.trieCount).map { $0 }
    }

    init(dataCapacity: Capacity, trieCapacity: Capacity) {
        let (dataBaseAddress, trieBaseAddress) = Self._allocate(dataCapacity: dataCapacity, trieCapacity: trieCapacity)

        self.header = Header(dataMap: 0, trieMap: 0)
        self.count = 0

        self.dataBaseAddress = dataBaseAddress
        self.trieBaseAddress = trieBaseAddress

        self.dataCapacity = dataCapacity
        self.trieCapacity = trieCapacity

        assert(self.invariant)
    }

    convenience init() {
        self.init(dataCapacity: initialDataCapacity, trieCapacity: initialTrieCapacity)

        self.header = Header(dataMap: 0, trieMap: 0)

        assert(self.invariant)
    }

    convenience init(dataMap: Bitmap, firstKey: Key, firstValue: Value) {
        self.init()

        self.header = Header(dataMap: dataMap, trieMap: 0)
        self.count = 1

        self.dataBaseAddress.initialize(to: (firstKey, firstValue))

        assert(self.invariant)
    }

    convenience init(dataMap: Bitmap, firstKey: Key, firstValue: Value, secondKey: Key, secondValue: Value) {
        self.init()

        self.header = Header(dataMap: dataMap, trieMap: 0)
        self.count = 2

        self.dataBaseAddress.initialize(to: (firstKey, firstValue))
        self.dataBaseAddress.successor().initialize(to: (secondKey, secondValue))

        assert(self.invariant)
    }

    convenience init(trieMap: Bitmap, firstNode: TrieNode<BitmapIndexedDictionaryNode<Key, Value>, HashCollisionDictionaryNode<Key, Value>>) {
        self.init()

        self.header = Header(dataMap: 0, trieMap: trieMap)
        self.count = firstNode.count

        self.trieBaseAddress.initialize(to: firstNode.object)

        assert(self.invariant)
    }

    convenience init(dataMap: Bitmap, trieMap: Bitmap, firstKey: Key, firstValue: Value, firstNode: TrieNode<BitmapIndexedDictionaryNode<Key, Value>, HashCollisionDictionaryNode<Key, Value>>) {
        self.init()

        self.header = Header(dataMap: dataMap, trieMap: trieMap)
        self.count = 1 + firstNode.count

        self.dataBaseAddress.initialize(to: (firstKey, firstValue))
        self.trieBaseAddress.initialize(to: firstNode.object)

        assert(self.invariant)
    }

    func get(_ key: Key, _ keyHash: Int, _ shift: Int) -> Value? {
        let mask = maskFrom(keyHash, shift)
        let bitpos = bitposFrom(mask)

        guard (dataMap & bitpos) == 0 else {
            let index = indexFrom(dataMap, mask, bitpos)
            let payload = self.getPayload(index)
            return key == payload.key ? payload.value : nil
        }

        guard (trieMap & bitpos) == 0 else {
            let index = indexFrom(trieMap, mask, bitpos)

            switch self.getNodeEnum(index) {
            case .bitmapIndexed(let node):
                return node.get(key, keyHash, shift + bitPartitionSize)
            case .hashCollision(let node):
                return node.get(key, keyHash, shift + bitPartitionSize)
            }
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

        guard (trieMap & bitpos) == 0 else {
            let index = indexFrom(trieMap, mask, bitpos)

            switch self.getNodeEnum(index) {
            case .bitmapIndexed(let node):
                return node.containsKey(key, keyHash, shift + bitPartitionSize)
            case .hashCollision(let node):
                return node.containsKey(key, keyHash, shift + bitPartitionSize)
            }
        }

        return false
    }

    func index(_ key: Key, _ keyHash: Int, _ shift: Int, _ skippedBefore: Int) -> PersistentDictionaryIndex? {
        let mask = maskFrom(keyHash, shift)
        let bitpos = bitposFrom(mask)

        let skipped = self.counts.prefix(upTo: mask).reduce(0, +)

        guard (dataMap & bitpos) == 0 else {
            let index = indexFrom(dataMap, mask, bitpos)
            let payload = self.getPayload(index)
            guard key == payload.key else { return nil }

            return PersistentDictionaryIndex(value: skippedBefore + skipped)
        }

        guard (trieMap & bitpos) == 0 else {
            let index = indexFrom(trieMap, mask, bitpos)

            switch self.getNodeEnum(index) {
            case .bitmapIndexed(let node):
                return node.index(key, keyHash, shift + bitPartitionSize, skippedBefore + skipped)
            case .hashCollision(let node):
                return node.index(key, keyHash, shift + bitPartitionSize, skippedBefore + skipped)
            }
        }

        return nil
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
                    return copyAndMigrateFromInlineToNode(isStorageKnownUniquelyReferenced, bitpos, subNodeNew)
                } else {
                    let subNodeNew = mergeTwoKeyValPairs(key0, value0, keyHash0, key, value, keyHash, shift + bitPartitionSize)
                    effect.setModified()
                    return copyAndMigrateFromInlineToNode(isStorageKnownUniquelyReferenced, bitpos, subNodeNew)
                }
            }
        }

        guard (trieMap & bitpos) == 0 else {
            let index = indexFrom(trieMap, mask, bitpos)
            let subNodeModifyInPlace = self.isTrieNodeKnownUniquelyReferenced(index, isStorageKnownUniquelyReferenced)

            switch self.getNodeEnum(index) {
            case .bitmapIndexed(let subNode):
                let subNodeNew = subNode.updateOrUpdating(subNodeModifyInPlace, key, value, keyHash, shift + bitPartitionSize, &effect)
                guard effect.modified && subNode !== subNodeNew else { if !effect.replacedValue { count += 1 } ; assert(self.invariant) ; return self }

                return copyAndSetTrieNode(isStorageKnownUniquelyReferenced, bitpos, index, subNodeNew, updateCount: { $0 -= subNode.count ; $0 += subNodeNew.count })
            case .hashCollision(let subNode):
                let collisionHash = subNode.hash

                if keyHash == collisionHash {
                    let subNodeNew = subNode.updateOrUpdating(subNodeModifyInPlace, key, value, keyHash, shift + bitPartitionSize, &effect)
                    guard effect.modified && subNode !== subNodeNew else { if !effect.replacedValue { count += 1 } ; assert(self.invariant) ; return self }

                    return copyAndSetTrieNode(isStorageKnownUniquelyReferenced, bitpos, index, subNodeNew, updateCount: { $0 += 1 })
                } else {
                    let subNodeNew = mergeKeyValPairAndCollisionNode(key, value, keyHash, subNode, collisionHash, shift + bitPartitionSize)
                    effect.setModified()
                    return copyAndSetTrieNode(isStorageKnownUniquelyReferenced, bitpos, index, subNodeNew, updateCount: { $0 += 1 })
                }
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
            guard key0 == key else { assert(self.invariant) ; return self }

            effect.setModified()
            // TODO check globally usage of `bitmapIndexedNodeArity` and `hashCollisionNodeArity`
            if self.payloadArity == 2 && self.nodeArity == 0 /* rename */ {
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
            } else if self.payloadArity == 1 && self.nodeArity /* rename */ == 1, case .hashCollision(let __node) = self.getNodeEnum(0) { /* TODO: is similar to `isWrappingSingleHashCollisionNode`? */
                // create potential new root: will a) become new root, or b) unwrapped on another level
                let newCollMap: Bitmap = bitposFrom(maskFrom(__node.hash, 0))
                return Self(trieMap: newCollMap, firstNode: getNodeEnum(0))
            } else { return copyAndRemoveValue(isStorageKnownUniquelyReferenced, bitpos) }
        }

        guard (trieMap & bitpos) == 0 else {
            let index = indexFrom(trieMap, mask, bitpos)
            let subNodeModifyInPlace = self.isTrieNodeKnownUniquelyReferenced(index, isStorageKnownUniquelyReferenced)

            switch self.getNodeEnum(index) {
            case .bitmapIndexed(let subNode):
                let subNodeNew = subNode.removeOrRemoving(subNodeModifyInPlace, key, keyHash, shift + bitPartitionSize, &effect)
                guard effect.modified && subNode !== subNodeNew else { if effect.modified { count -= 1 } ; assert(self.invariant) ; return self }

                switch subNodeNew.count {
                case 0:
                    preconditionFailure("Sub-node must have at least one element.")

                case 1:
                    assert(self.nodeArity /*bitmapIndexedNodeArity???*/ >= 1)

                    if self.isCandiateForCompaction {
                        // escalate singleton
                        return subNodeNew
                    } else {
                        // inline singleton
                        return copyAndMigrateFromNodeToInline(isStorageKnownUniquelyReferenced, bitpos, subNodeNew.getPayload(0))
                    }

                case _:
                    assert(self.nodeArity /*bitmapIndexedNodeArity???*/ >= 1)

                    if (subNodeNew.isWrappingSingleHashCollisionNode) {
                        if self.isCandiateForCompaction {
                            // escalate node that has only a single hash-collision sub-node
                            return subNodeNew
                        } else {
                            // unwrap hash-collision sub-node
                            return copyAndSetTrieNode(isStorageKnownUniquelyReferenced, bitpos, index, subNodeNew.getNode(0), updateCount: { $0 -= 1 })
                        }
                    }

                    // modify current node (set replacement node)
                    return copyAndSetTrieNode(isStorageKnownUniquelyReferenced, bitpos, index, subNodeNew, updateCount: { $0 -= 1 })
                }
            case .hashCollision(let subNode):
                let subNodeNew = subNode.removeOrRemoving(subNodeModifyInPlace, key, keyHash, shift + bitPartitionSize, &effect)
                guard effect.modified && subNode !== subNodeNew else { if effect.modified { count -= 1 } ; assert(self.invariant) ; return self }

                switch subNodeNew.count {
                case 0:
                    preconditionFailure("Sub-node must have at least one element.")

                case 1:
                    // TODO simplify hash-collision compaction (if feasible)
                    if self.isCandiateForCompaction {
                        // escalate singleton
                        // convert `HashCollisionDictionaryNode` to `BitmapIndexedDictionaryNode` (logic moved/inlined from `HashCollisionDictionaryNode`)
                        let newDataMap: Bitmap = bitposFrom(maskFrom(subNodeNew.hash, 0))
                        let (remainingKey, remainingValue) = subNodeNew.getPayload(0)
                        return Self(dataMap: newDataMap, firstKey: remainingKey, firstValue: remainingValue)
                    } else {
                        // inline value
                        return copyAndMigrateFromNodeToInline(isStorageKnownUniquelyReferenced, bitpos, subNodeNew.getPayload(0))
                    }

                case _:
                    // modify current node (set replacement node)
                    return copyAndSetTrieNode(isStorageKnownUniquelyReferenced, bitpos, index, subNodeNew, updateCount: { $0 -= 1 })
                }
            }
        }

        return self
    }

    var isCandiateForCompaction: Bool { payloadArity == 0 && nodeArity == 1 }

    var isWrappingSingleHashCollisionNode: Bool { if payloadArity == 0 && self.nodeArity /* rename */ == 1, case .hashCollision(_) = self.getNodeEnum(0) { return true } else { return false } }

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

            return Self(trieMap: bitposFrom(mask0), firstNode: .bitmapIndexed(node))
        }
    }

    func mergeKeyValPairAndCollisionNode(_ key0: Key, _ value0: Value, _ keyHash0: Int, _ node1: HashCollisionDictionaryNode<Key, Value>, _ nodeHash1: Int, _ shift: Int) -> BitmapIndexedDictionaryNode<Key, Value> {
        assert(keyHash0 != nodeHash1)

        let mask0 = maskFrom(keyHash0, shift)
        let mask1 = maskFrom(nodeHash1, shift)

        if mask0 != mask1 {
            // unique prefixes, payload and collision node fit on same level
            return Self(dataMap: bitposFrom(mask0), trieMap: bitposFrom(mask1), firstKey: key0, firstValue: value0, firstNode: .hashCollision(node1))
        } else {
            // recurse: identical prefixes, payload must be disambiguated deeper in the trie
            let node = mergeKeyValPairAndCollisionNode(key0, value0, keyHash0, node1, nodeHash1, shift + bitPartitionSize)

            return Self(trieMap: bitposFrom(mask0), firstNode: .bitmapIndexed(node))
        }
    }

    private func isTrieNodeKnownUniquelyReferenced(_ slotIndex: Int, _ isParentNodeKnownUniquelyReferenced: Bool) -> Bool {
        let isKnownUniquelyReferenced = Swift.isKnownUniquelyReferenced(&trieBaseAddress[slotIndex])

        return isParentNodeKnownUniquelyReferenced && isKnownUniquelyReferenced
    }

    // TODO rename, not accurate any more
    var hasNodes: Bool { header.trieMap != 0 }

    // TODO rename, not accurate any more
    var nodeArity: Int { header.trieCount }

    // TODO rename, not accurate any more
    func getNode(_ index: Int) -> AnyObject {
        return trieBaseAddress[index]
    }

    final func getNodeEnum(_ index: Int) -> TrieNode<BitmapIndexedDictionaryNode<Key, Value>, HashCollisionDictionaryNode<Key, Value>> {
        switch trieBaseAddress[index] {
        case let node as BitmapIndexedDictionaryNode<Key, Value>:
            return .bitmapIndexed(node)
        case let node as HashCollisionDictionaryNode<Key, Value>:
            return .hashCollision(node)
        default:
            fatalError("Should not reach here.") // TODO: rework to remove 'dummy' default clause
        }
    }

    var hasPayload: Bool { header.dataMap != 0 }

    var payloadArity: Int { header.dataCount }

    func getPayload(_ index: Int) -> (key: Key, value: Value) {
        dataBaseAddress[index]
    }

    private final var counts: [Int] {
        var counts = Array(repeating: 0, count: Bitmap.bitWidth)

        zip(header.dataMap.nonzeroBits(), _dataSlice).forEach { (index, _) in
            counts[index] = 1
        }

        zip(header.trieMap.nonzeroBits(), _trieSlice).forEach { (index, trieNode) in
            switch trieNode {
            case let trieNode as BitmapIndexedDictionaryNode<Key, Value>:
                counts[index] = trieNode.count
            case let trieNode as HashCollisionDictionaryNode<Key, Value>:
                counts[index] = trieNode.count
            default:
                fatalError("Should not reach here.") // TODO: rework to remove 'dummy' default clause
            }
        }

        return counts
    }

    private final func count(upTo mask: Int) -> Int {
        let bitpos = bitposFrom(mask)

        let dataIndex = indexFrom(dataMap, mask, bitpos)
        let trieIndex = indexFrom(trieMap, mask, bitpos)

        let count = dataIndex + UnsafeMutableBufferPointer(start: trieBaseAddress, count: header.trieCount).prefix(upTo: trieIndex).map {
            switch $0 {
            case let trieNode as BitmapIndexedDictionaryNode<Key, Value>:
                return trieNode.count
            case let trieNode as BitmapIndexedDictionaryNode<Key, Value>:
                return trieNode.count
            default:
                fatalError("Should not reach here.") // TODO: rework to remove 'dummy' default clause
            }
        }.reduce(0, +)

        assert(count == counts.prefix(upTo: mask).reduce(0, +))
        return count
    }

    func dataIndex(_ bitpos: Bitmap) -> Int { (dataMap & (bitpos &- 1)).nonzeroBitCount }

    func trieIndex(_ bitpos: Bitmap) -> Int { (trieMap & (bitpos &- 1)).nonzeroBitCount }

    func copyAndSetValue(_ isStorageKnownUniquelyReferenced: Bool, _ bitpos: Bitmap, _ newValue: Value) -> BitmapIndexedDictionaryNode<Key, Value> {
        let src: ReturnBitmapIndexedNode = self
        let dst: ReturnBitmapIndexedNode

        if isStorageKnownUniquelyReferenced {
            dst = src
        } else {
            dst = src.copy()
        }

        let idx = dataIndex(bitpos)

        dst.dataBaseAddress[idx].value = newValue

        assert(src.invariant)
        assert(dst.invariant)
        return dst
    }

    private func copyAndSetTrieNode(_ isStorageKnownUniquelyReferenced: Bool, _ bitpos: Bitmap, _ idx: Int, _ newNode: TrieBufferElement, updateCount: (inout Int) -> Void) -> BitmapIndexedDictionaryNode<Key, Value> {
        let src: ReturnBitmapIndexedNode = self
        let dst: ReturnBitmapIndexedNode

        if isStorageKnownUniquelyReferenced {
            dst = src
        } else {
            dst = src.copy()
        }

        dst.trieBaseAddress[idx] = newNode // as TrieBufferElement

        // update metadata: `dataMap, nodeMap, collMap`
        updateCount(&dst.count)

        assert(src.invariant)
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
        dst.header.dataMap |= bitpos
        dst.count += 1

        assert(src.invariant)
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
        dst.header.dataMap ^= bitpos
        dst.count -= 1

        assert(src.invariant)
        assert(dst.invariant)
        return dst
    }

    func copyAndMigrateFromInlineToNode(_ isStorageKnownUniquelyReferenced: Bool, _ bitpos: Bitmap, _ node: TrieBufferElement) -> BitmapIndexedDictionaryNode<Key, Value> {
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

        let trieIdx = indexFrom(trieMap, bitpos)
        rangeInsert(node, at: trieIdx, into: dst.trieBaseAddress, count: dst.header.trieCount)

        // update metadata: `dataMap ^ bitpos, nodeMap | bitpos, collMap`
        dst.header.dataMap ^= bitpos
        dst.header.trieMap |= bitpos
        dst.count += 1 // assuming that `node.count == 2`

        assert(src.invariant)
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

        let nodeIdx = indexFrom(trieMap, bitpos)
        rangeRemove(at: nodeIdx, from: dst.trieBaseAddress, count: dst.header.trieCount)

        let dataIdx = indexFrom(dataMap, bitpos)
        rangeInsert(tuple, at: dataIdx, into: dst.dataBaseAddress, count: dst.header.dataCount)

        // update metadata: `dataMap | bitpos, nodeMap ^ bitpos, collMap`
        dst.header.dataMap |= bitpos
        dst.header.trieMap ^= bitpos
        dst.count -= 1 // assuming that updated `node.count == 1`

        assert(src.invariant)
        assert(dst.invariant)
        return dst
    }
}

// TODO: `Equatable` needs more test coverage, apart from hash-collision smoke test
extension BitmapIndexedDictionaryNode: Equatable where Value: Equatable {
    static func == (lhs: BitmapIndexedDictionaryNode<Key, Value>, rhs: BitmapIndexedDictionaryNode<Key, Value>) -> Bool {
        lhs === rhs ||
            lhs.header == rhs.header &&
            lhs.count == rhs.count &&
            deepContentEquality(lhs, rhs)
    }

    private static func deepContentEquality(_ lhs: BitmapIndexedDictionaryNode<Key, Value>, _ rhs: BitmapIndexedDictionaryNode<Key, Value>) -> Bool {
        guard lhs.header == rhs.header else { return false }

        for index in 0..<lhs.payloadArity {
            if lhs.getPayload(index) != rhs.getPayload(index) {
                return false
            }
        }

        for index in 0..<lhs.nodeArity {
            switch (lhs.getNodeEnum(index), rhs.getNodeEnum(index)) {
            case (.bitmapIndexed(let lhs), .bitmapIndexed(let rhs)):
                if !(lhs === rhs || lhs == rhs) { return false }
            case (.hashCollision(let lhs), .hashCollision(let rhs)):
                if !(lhs === rhs || lhs == rhs) { return false }
            default:
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

struct Header: Equatable {
    var dataMap: Bitmap
    var trieMap: Bitmap

    var dataCount: Int { dataMap.nonzeroBitCount }
    var trieCount: Int { trieMap.nonzeroBitCount }

    static func == (lhs: Header, rhs: Header) -> Bool {
        lhs.dataMap == rhs.dataMap && lhs.trieMap == rhs.trieMap
    }
}
