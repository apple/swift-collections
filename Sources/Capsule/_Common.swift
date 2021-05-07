//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Collections open source project
//
// Copyright (c) 2019 - 2020 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
//
//===----------------------------------------------------------------------===//

import func Foundation.ceil

func computeHash<T : Hashable>(_ value: T) -> Int {
    value.hashValue
}

var HashCodeLength: Int { Int.bitWidth }

var BitPartitionSize: Int { 6 }

var BitPartitionMask: Int { (1 << BitPartitionSize) - 1 }

let MaxDepth = Int(ceil(Double(HashCodeLength) / Double(BitPartitionSize)))

func maskFrom(_ hash: Int, _ shift: Int) -> Int {
    (hash >> shift) & BitPartitionMask
}

func bitposFrom(_ mask: Int) -> Int {
    1 << mask
}

func indexFrom(_ bitmap: Int, _ bitpos: Int) -> Int {
    (bitmap & (bitpos &- 1)).nonzeroBitCount
}

func indexFrom(_ bitmap: Int, _ mask: Int, _ bitpos: Int) -> Int {
    (bitmap == -1) ? mask : indexFrom(bitmap, bitpos)
}

protocol Node {
    associatedtype ReturnPayload
    associatedtype ReturnNode : Node
    
    var hasNodes: Bool { get }
    
    var nodeArity: Int { get }
    
    func getNode(_ index: Int) -> ReturnNode
    
    var hasPayload: Bool { get }
    
    var payloadArity: Int { get }
    
    func getPayload(_ index: Int) -> ReturnPayload
}

///
/// Base class for fixed-stack iterators that traverse a hash-trie. The iterator performs a
/// depth-first pre-order traversal, which yields first all payload elements of the current
/// node before traversing sub-nodes (left to right).
///
struct ChampBaseIterator<T : Node> {
    
    var currentValueCursor: Int = 0
    var currentValueLength: Int = 0
    var currentValueNode: T? = nil
    
    private var currentStackLevel: Int = -1
    private var nodeCursorsAndLengths: Array<Int> = Array<Int>(repeating: 0, count: MaxDepth * 2)
    private var nodes: Array<T?> = Array<T?>(repeating: nil, count: MaxDepth)
    
    init(rootNode: T) {
        if (rootNode.hasNodes) { pushNode(rootNode) }
        if (rootNode.hasPayload) { setupPayloadNode(rootNode) }
    }
    
    private mutating func setupPayloadNode(_ node: T) {
        currentValueNode = node
        currentValueCursor = 0
        currentValueLength = node.payloadArity
    }
    
    private mutating func pushNode(_ node: T) {
        currentStackLevel = currentStackLevel + 1
        
        let cursorIndex = currentStackLevel * 2
        let lengthIndex = currentStackLevel * 2 + 1
        
        nodes[currentStackLevel] = node
        nodeCursorsAndLengths[cursorIndex] = 0
        nodeCursorsAndLengths[lengthIndex] = node.nodeArity
    }
    
    private mutating func popNode() {
        currentStackLevel = currentStackLevel - 1
    }
    
    ///
    /// Searches for next node that contains payload values,
    /// and pushes encountered sub-nodes on a stack for depth-first traversal.
    ///
    private mutating func searchNextValueNode() -> Bool {
        while (currentStackLevel >= 0) {
            let cursorIndex = currentStackLevel * 2
            let lengthIndex = currentStackLevel * 2 + 1
            
            let nodeCursor = nodeCursorsAndLengths[cursorIndex]
            let nodeLength = nodeCursorsAndLengths[lengthIndex]
            
            if (nodeCursor < nodeLength) {
                nodeCursorsAndLengths[cursorIndex] += 1
                
                let nextNode = nodes[currentStackLevel]!.getNode(nodeCursor) as! T
                
                if (nextNode.hasNodes)   { pushNode(nextNode) }
                if (nextNode.hasPayload) { setupPayloadNode(nextNode) ; return true }
            } else {
                popNode()
            }
        }
        
        return false
    }
    
    mutating func hasNext() -> Bool {
        return (currentValueCursor < currentValueLength) || searchNextValueNode()
    }
    
}

///
/// Base class for fixed-stack iterators that traverse a hash-trie in reverse order. The base
/// iterator performs a depth-first post-order traversal, traversing sub-nodes (right to left).
///
struct ChampBaseReverseIterator<T : Node> {

    var currentValueCursor: Int = -1
    var currentValueNode: T? = nil
    
    private var currentStackLevel: Int = -1
    private var nodeIndex: Array<Int> = Array<Int>(repeating: 0, count: MaxDepth + 1)
    private var nodeStack: Array<T?> = Array<T?>(repeating: nil, count: MaxDepth + 1)
    
    init(rootNode: T) {
        pushNode(rootNode)
        searchNextValueNode()
    }
    
    private mutating func setupPayloadNode(_ node: T) {
        currentValueNode = node
        currentValueCursor = node.payloadArity - 1
    }
    
    private mutating func pushNode(_ node: T) {
        currentStackLevel = currentStackLevel + 1
        
        nodeStack[currentStackLevel] = node
        nodeIndex[currentStackLevel] = node.nodeArity - 1
    }
    
    private mutating func popNode() {
        currentStackLevel = currentStackLevel - 1
    }
    
    ///
    /// Searches for rightmost node that contains payload values,
    /// and pushes encountered sub-nodes on a stack for depth-first traversal.
    ///
    @discardableResult
    private mutating func searchNextValueNode() -> Bool {
        while (currentStackLevel >= 0) {
            let nodeCursor = nodeIndex[currentStackLevel] ; nodeIndex[currentStackLevel] = nodeCursor - 1
            
            if (nodeCursor >= 0) {
                let nextNode = nodeStack[currentStackLevel]!.getNode(nodeCursor) as! T
                pushNode(nextNode)
            } else {
                let currNode = nodeStack[currentStackLevel]!
                popNode()
                
                if (currNode.hasPayload) { setupPayloadNode(currNode) ; return true }
            }
        }
        
        return false
    }
    
    mutating func hasNext() -> Bool {
        return (currentValueCursor >= 0) || searchNextValueNode()
    }
}
