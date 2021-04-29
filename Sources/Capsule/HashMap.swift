//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Collections open source project
//
// Copyright (c) 2019 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
//
//===----------------------------------------------------------------------===//

public struct HashMap<Key, Value> where Key : Hashable {
    let rootNode: MapNode<Key, Value>
    let cachedKeySetHashCode: Int
    let cachedSize: Int
    
    fileprivate init(_ rootNode: MapNode<Key, Value>, _ cachedKeySetHashCode: Int, _ cachedSize: Int) {
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

extension HashMap : ExpressibleByDictionaryLiteral {
    public init(dictionaryLiteral elements: (Key, Value)...) {
        let map = elements.reduce(Self()) { (map, element) in let (key, value) = element
            return map.insert(key: key, value: value)
        }
        self.init(map)
    }
}

extension HashMap : Equatable, Hashable {
    public static func == (lhs: HashMap<Key, Value>, rhs: HashMap<Key, Value>) -> Bool {
        lhs.cachedSize == rhs.cachedSize &&
            lhs.cachedKeySetHashCode == rhs.cachedKeySetHashCode &&
            (lhs.rootNode === rhs.rootNode || lhs.rootNode == rhs.rootNode)
    }
    
    public var hashValue: Int {
        preconditionFailure("Not yet implemented")
    }
    
    public func hash(into: inout Hasher) {
        preconditionFailure("Not yet implemented")
    }
}

extension HashMap : Sequence {
    public __consuming func makeIterator() -> MapKeyValueTupleIterator<Key, Value> {
        return MapKeyValueTupleIterator(rootNode: rootNode)
    }
}

fileprivate let EmptyMapNode = BitmapIndexedMapNode<AnyHashable, Any>(0, 0, Array())

// TODO assess if convertible to a `protocol`. Variance / constraints on return types make it difficult.
class MapNode<Key, Value> : Node where Key : Hashable {
    
    func get(_ key: Key, _ hash: Int, _ shift: Int) -> Value? {
        preconditionFailure("This method must be overridden")
    }

    func containsKey(_ key: Key, _ hash: Int, _ shift: Int) -> Bool {
        preconditionFailure("This method must be overridden")
    }

    func updated(_ key: Key, _ value: Value, _ hash: Int, _ shift: Int, _ effect: inout MapEffect) -> MapNode<Key, Value> {
        preconditionFailure("This method must be overridden")
    }

    func removed(_ key: Key, _ hash: Int, _ shift: Int, _ effect: inout MapEffect) -> MapNode<Key, Value> {
        preconditionFailure("This method must be overridden")
    }
    
    var hasNodes: Bool {
        preconditionFailure("This method must be overridden")
    }

    var nodeArity: Int {
        preconditionFailure("This method must be overridden")
    }

    func getNode(_ index: Int) -> MapNode<Key, Value> {
        preconditionFailure("This method must be overridden")
    }
    
    var hasPayload: Bool {
        preconditionFailure("This method must be overridden")
    }

    var payloadArity: Int {
        preconditionFailure("This method must be overridden")
    }

    func getPayload(_ index: Int) -> (Key, Value) {
        preconditionFailure("This method must be overridden")
    }
}

extension MapNode : Equatable {
    static func == (lhs: MapNode<Key, Value>, rhs: MapNode<Key, Value>) -> Bool {
        preconditionFailure("Not yet implemented")
    }
}

fileprivate var TupleLength: Int { 2 }

final class BitmapIndexedMapNode<Key, Value> : MapNode<Key, Value> where Key : Hashable {
    let dataMap: Int
    let nodeMap: Int
    let content: [Any]
    
    init(_ dataMap: Int, _ nodeMap: Int, _ content: [Any]) {
        self.dataMap = dataMap
        self.nodeMap = nodeMap
        self.content = content
    }
    
    override func getPayload(_ index: Int) -> (Key, Value) {
        (content[TupleLength * index + 0] as! Key,
         content[TupleLength * index + 1] as! Value)
    }

    override func getNode(_ index: Int) -> MapNode<Key, Value> {
        content[content.count - 1 - index] as! MapNode<Key, Value>
    }
    
    override func get(_ key: Key, _ keyHash: Int, _ shift: Int) -> Value? {
        let mask = maskFrom(keyHash, shift)
        let bitpos = bitposFrom(mask)
        
        if ((dataMap & bitpos) != 0) {
            let index = indexFrom(dataMap, mask, bitpos)
            let payload = self.getPayload(index)
            if (key == payload.0) { return payload.1 } else { return nil }
        }

        if ((nodeMap & bitpos) != 0) {
          let index = indexFrom(nodeMap, mask, bitpos)
          return self.getNode(index).get(key, keyHash, shift + BitPartitionSize)
        }

        return nil
    }
    
    override func containsKey(_ key: Key, _ keyHash: Int, _ shift: Int) -> Bool {
        let mask = maskFrom(keyHash, shift)
        let bitpos = bitposFrom(mask)
        
        if ((dataMap & bitpos) != 0) {
            let index = indexFrom(dataMap, mask, bitpos)
            let payload = self.getPayload(index)
            return key == payload.0
        }

        if ((nodeMap & bitpos) != 0) {
          let index = indexFrom(nodeMap, mask, bitpos)
          return self.getNode(index).containsKey(key, keyHash, shift + BitPartitionSize)
        }

        return false
    }
    
    override func updated(_ key: Key, _ value: Value, _ keyHash: Int, _ shift: Int, _ effect: inout MapEffect) -> MapNode<Key, Value> {
        let mask = maskFrom(keyHash, shift)
        let bitpos = bitposFrom(mask)

        if ((dataMap & bitpos) != 0) {
          let index = indexFrom(dataMap, mask, bitpos)
          let (key0, value0) = self.getPayload(index)

          if (key0 == key) {
            effect.setReplacedValue()
            return copyAndSetValue(bitpos, value)
          } else {
            let subNodeNew = mergeTwoKeyValPairs(key0, value0, computeHash(key0), key, value, keyHash, shift + BitPartitionSize)
            effect.setModified()
            return copyAndMigrateFromInlineToNode(bitpos, subNodeNew)
          }
        }

        if ((nodeMap & bitpos) != 0) {
          let index = indexFrom(nodeMap, mask, bitpos)
          let subNode = self.getNode(index)

          let subNodeNew = subNode.updated(key, value, keyHash, shift + BitPartitionSize, &effect)
          if (!effect.modified) {
            return self
          } else {
            return copyAndSetNode(bitpos, subNodeNew)
          }
        }

        effect.setModified()
        return copyAndInsertValue(bitpos, key, value)
    }
    
    override func removed(_ key: Key, _ keyHash: Int, _ shift: Int, _ effect: inout MapEffect) -> MapNode<Key, Value> {
        let mask = maskFrom(keyHash, shift)
        let bitpos = bitposFrom(mask)
        
        if ((dataMap & bitpos) != 0) {
            let index = indexFrom(dataMap, mask, bitpos)
            let (key0, _) = self.getPayload(index)
            
            if (key0 == key) {
                effect.setModified()
                if (self.payloadArity == 2 && self.nodeArity == 0) {
                    /*
                     * Create new node with remaining pair. The new node will a) either become the new root
                     * returned, or b) unwrapped and inlined during returning.
                     */
                    let newDataMap: Int
                    if (shift == 0) { newDataMap = (dataMap ^ bitpos) } else { newDataMap = bitposFrom(maskFrom(keyHash, 0)) }
                    if (index == 0) {
                        let (k, v) = getPayload(1)
                        return BitmapIndexedMapNode(newDataMap, 0, Array(arrayLiteral: k, v) )
                    } else {
                        let (k, v) = getPayload(0)
                        return BitmapIndexedMapNode(newDataMap, 0, Array(arrayLiteral: k, v))
                    }
                } else { return copyAndRemoveValue(bitpos) }
            } else { return self }
        }
        
        if ((nodeMap & bitpos) != 0) {
            let index = indexFrom(nodeMap, mask, bitpos)
            let subNode = self.getNode(index)
            
            let subNodeNew = subNode.removed(key, keyHash, shift + BitPartitionSize, &effect)

            if (!effect.modified) { return self }
            switch subNodeNew.payloadArity {
            case 1:
                if (self.payloadArity == 0 && self.nodeArity == 1) { // escalate (singleton or empty) result
                    return subNodeNew
                }
                else { // inline value (move to front)
                    return copyAndMigrateFromNodeToInline(bitpos, subNodeNew)
                }
                
            default: // equivalent to `case 2...`
                // modify current node (set replacement node)
                return copyAndSetNode(bitpos, subNodeNew)
            }
        }
        
        return self
    }
    
    func mergeTwoKeyValPairs(_ key0: Key, _ value0: Value, _ keyHash0: Int, _ key1: Key, _ value1: Value, _ keyHash1: Int, _ shift: Int) -> MapNode<Key, Value> {
        if (shift >= HashCodeLength) {
            preconditionFailure("Not yet implemented")
        } else {
            let mask0 = maskFrom(keyHash0, shift)
            let mask1 = maskFrom(keyHash1, shift)
            
            if (mask0 != mask1) {
                // unique prefixes, payload fits on same level
                let dataMap = bitposFrom(mask0) | bitposFrom(mask1)
                
                if (mask0 < mask1) {
                    return BitmapIndexedMapNode(dataMap, 0, Array(arrayLiteral: key0, value0, key1, value1))
                } else {
                    return BitmapIndexedMapNode(dataMap, 0, Array(arrayLiteral: key1, value1, key0, value0))
                }
            } else {
                // identical prefixes, payload must be disambiguated deeper in the trie
                let nodeMap = bitposFrom(mask0)
                let node = mergeTwoKeyValPairs(key0, value0, keyHash0, key1, value1, keyHash1, shift + BitPartitionSize)
                
                return BitmapIndexedMapNode(0, nodeMap, Array(arrayLiteral: node))
            }
        }
    }
    
    override var hasNodes: Bool { nodeMap != 0 }

    override var nodeArity: Int { nodeMap.nonzeroBitCount }

    override var hasPayload: Bool { dataMap != 0 }

    override var payloadArity: Int { dataMap.nonzeroBitCount }

    func dataIndex(_ bitpos: Int) -> Int { (dataMap & (bitpos - 1)).nonzeroBitCount }

    func nodeIndex(_ bitpos: Int) -> Int { (nodeMap & (bitpos - 1)).nonzeroBitCount }

    /// TODO: leverage lazy copy-on-write only when aliased. The pattern required by the current data structure design
    /// isn't expressible in Swift currently (i.e., `isKnownUniquelyReferenced(&self)` isn't supported). Example:
    ///
    /// ```
    /// class Node {
    ///     var src: [Any]
    ///     func updateInlineOrCopy(idx: Int, newValue: Any) {
    ///         if isKnownUniquelyReferenced(&self) { // this isn't supported ...
    ///             src[idx] = newValue
    ///             return self
    ///         } else {
    ///             var dst = self.content
    ///             dst[idx] = newValue
    ///             return Node(dst)
    ///         }
    ///     }
    /// }
    /// ```
    ///
    /// Some more context:
    /// * Node should be a reference counted data type (i.e., `class`)
    /// * In a optimized version `src` would be gone, and `Node` likely become a subclass of `ManagedBuffer`
    /// * I want to check `isKnownUniquelyReferenced(&self)` since `updateInlineOrCopy` should be recursive call that decides upon returning from recursion if modifications are necessary
    ///
    /// Possible mitigations: transform recursive to loop where `isKnownUniquelyReferenced` could be checked from the outside.
    /// This would be very invasive though and make problem logic hard to understand and maintain.
    func copyAndSetValue(_ bitpos: Int, _ newValue: Value) -> BitmapIndexedMapNode<Key, Value> {
        let idx = TupleLength * dataIndex(bitpos) + 1

        var dst = self.content
        dst[idx] = newValue

        return BitmapIndexedMapNode(dataMap, nodeMap, dst)
    }

    func copyAndSetNode(_ bitpos: Int, _ newNode: MapNode<Key, Value>) -> BitmapIndexedMapNode<Key, Value> {
        let idx = self.content.count - 1 - self.nodeIndex(bitpos)

        var dst = self.content
        dst[idx] = newNode
        
        return BitmapIndexedMapNode(dataMap, nodeMap, dst)
    }

    func copyAndInsertValue(_ bitpos: Int, _ key: Key, _ value: Value) -> BitmapIndexedMapNode<Key, Value> {
        let idx = TupleLength * dataIndex(bitpos)
        
        var dst = self.content
        dst.insert(contentsOf: [key, value], at: idx)
        
        return BitmapIndexedMapNode(dataMap | bitpos, nodeMap, dst)
    }

    func copyAndRemoveValue(_ bitpos: Int) -> BitmapIndexedMapNode<Key, Value> {
        let idx = TupleLength * dataIndex(bitpos)
        
        var dst = self.content
        dst.removeSubrange(idx..<idx+TupleLength)
        
        return BitmapIndexedMapNode(dataMap ^ bitpos, nodeMap, dst)
    }

    func copyAndMigrateFromInlineToNode(_ bitpos: Int, _ node: MapNode<Key, Value>) -> BitmapIndexedMapNode<Key, Value> {
        let idxOld = TupleLength * dataIndex(bitpos)
        let idxNew = self.content.count - TupleLength - nodeIndex(bitpos)
        
        var dst = self.content
        dst.removeSubrange(idxOld..<idxOld+TupleLength)
        dst.insert(node, at: idxNew)
        
        return BitmapIndexedMapNode(dataMap ^ bitpos, nodeMap | bitpos, dst)
    }

    func copyAndMigrateFromNodeToInline(_ bitpos: Int, _ node: MapNode<Key, Value>) -> BitmapIndexedMapNode<Key, Value> {
        let idxOld = self.content.count - 1 - nodeIndex(bitpos)
        let idxNew = TupleLength * dataIndex(bitpos)
        
        let (key, value) = node.getPayload(0)
        
        var dst = self.content
        dst.remove(at: idxOld)
        dst.insert(contentsOf: [key, value], at: idxNew)
        
        return BitmapIndexedMapNode(dataMap | bitpos, nodeMap ^ bitpos, dst)
    }
}

extension BitmapIndexedMapNode /* : Equatable */ {
    static func == (lhs: BitmapIndexedMapNode<Key, Value>, rhs: BitmapIndexedMapNode<Key, Value>) -> Bool {
        lhs === rhs ||
            lhs.nodeMap == rhs.nodeMap &&
            lhs.dataMap == rhs.dataMap &&
            deepContentEquality(lhs.content, rhs.content, lhs.content.count)
    }

    private static func deepContentEquality(_ a1: [Any], _ a2: [Any], _ length: Int) -> Bool {
        preconditionFailure("Not yet implemented")
    }
}

struct MapEffect {
    var modified: Bool = false
    var replacedValue: Bool = false
    
    mutating func setModified() {
        self.modified = true
    }
    
    mutating func setReplacedValue() {
        self.modified = true
        self.replacedValue = true
    }
}

public struct MapKeyValueTupleIterator<Key : Hashable, Value> {
    private var baseIterator: ChampBaseIterator<MapNode<Key, Value>>
    
    init(rootNode: MapNode<Key, Value>) {
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
    private var baseIterator: ChampBaseReverseIterator<MapNode<Key, Value>>
    
    init(rootNode: MapNode<Key, Value>) {
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
