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

typealias Bitmap = Int64

let BitPartitionSize: Int = 5

let BitPartitionMask: Int = (1 << BitPartitionSize) - 1

let HashCodeLength: Int = Int.bitWidth

let MaxDepth = Int(ceil(Double(HashCodeLength) / Double(BitPartitionSize)))

func maskFrom(_ hash: Int, _ shift: Int) -> Int {
    (hash >> shift) & BitPartitionMask
}

func bitposFrom(_ mask: Int) -> Bitmap {
    1 << mask
}

func indexFrom(_ bitmap: Bitmap, _ bitpos: Bitmap) -> Int {
    (bitmap & (bitpos &- 1)).nonzeroBitCount
}

func indexFrom(_ bitmap: Bitmap, _ mask: Int, _ bitpos: Bitmap) -> Int {
    (bitmap == -1) ? mask : indexFrom(bitmap, bitpos)
}

enum TrieNode<BitmapIndexedNode : Node, HashCollisionNode : Node> {
    case bitmapIndexed(BitmapIndexedNode)
    case hashCollision(HashCollisionNode)

//    func value<T: AnyObject>() -> T {
//        switch self {
//        case .bitmapIndexed(let node):
//            return node as! T
//        case .hashCollision(let node):
//            return node as! T
//        }
//    }

    var hasPayload: Bool {
        switch self {
        case .bitmapIndexed(let node):
            return node.hasPayload
        case .hashCollision(let node):
            return node.hasPayload
        }
    }

    var payloadArity: Int {
        switch self {
        case .bitmapIndexed(let node):
            return node.payloadArity
        case .hashCollision(let node):
            return node.payloadArity
        }
    }

//    func getPayload(_ index: Int) -> Node.ReturnPayload {
//        switch self {
//        case .bitmapIndexed(let node):
//            return node.getPayload(index)
//        case .hashCollision(let node):
//            return node.getPayload(index)
//        }
//    }

    var hasNodes: Bool {
        switch self {
        case .bitmapIndexed(let node):
            return node.hasNodes
        case .hashCollision(let node):
            return node.hasNodes
        }
    }

    var nodeArity: Int {
        switch self {
        case .bitmapIndexed(let node):
            return node.nodeArity
        case .hashCollision(let node):
            return node.nodeArity
        }
    }
}

enum SizePredicate {
    case sizeEmpty
    case sizeOne
    case sizeMoreThanOne
}

extension SizePredicate {
    init<T: Node>(_ node: T) {
        if node.nodeArity == 0 {
            switch node.payloadArity {
            case 0:
                self = .sizeEmpty
            case 1:
                self = .sizeOne
            case _:
                self = .sizeMoreThanOne
            }
        } else {
            self = .sizeMoreThanOne
        }
    }
}

protocol Node {
    associatedtype ReturnPayload
    associatedtype ReturnBitmapIndexedNode : Node
    associatedtype ReturnHashCollisionNode : Node
    
    var hasBitmapIndexedNodes: Bool { get }
    
    var bitmapIndexedNodeArity: Int { get }
    
    func getBitmapIndexedNode(_ index: Int) -> ReturnBitmapIndexedNode

    var hasHashCollisionNodes: Bool { get }

    var hashCollisionNodeArity: Int { get }

    func getHashCollisionNode(_ index: Int) -> ReturnHashCollisionNode

    var hasNodes: Bool { get }

    var nodeArity: Int { get }

    func getNode(_ index: Int) -> TrieNode<ReturnBitmapIndexedNode, ReturnHashCollisionNode>

    var hasPayload: Bool { get }
    
    var payloadArity: Int { get }
    
    func getPayload(_ index: Int) -> ReturnPayload

    var sizePredicate: SizePredicate { get }
}

///
/// Base class for fixed-stack iterators that traverse a hash-trie. The iterator performs a
/// depth-first pre-order traversal, which yields first all payload elements of the current
/// node before traversing sub-nodes (left to right).
///
struct ChampBaseIterator<BitmapIndexedNode : Node, HashCollisionNode : Node> {
    typealias T = TrieNode<BitmapIndexedNode, HashCollisionNode>

    var currentValueCursor: Int = 0
    var currentValueLength: Int = 0
    var currentValueNode: T? = nil
    
    private var currentStackLevel: Int = -1
    private var nodeCursorsAndLengths: Array<Int> = Array<Int>(repeating: 0, count: MaxDepth * 2)
    private var nodes: Array<T?> = Array<T?>(repeating: nil, count: MaxDepth)

    init(rootNode: T) {
        if (rootNode.hasNodes)   { pushNode(rootNode) }
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

                // TODO remove duplication in specialization
                switch nodes[currentStackLevel]! {
                case .bitmapIndexed(let currentNode):
                    let nextNode = currentNode.getNode(nodeCursor) as! T

                    if (nextNode.hasNodes)   { pushNode(nextNode) }
                    if (nextNode.hasPayload) { setupPayloadNode(nextNode) ; return true }
                case .hashCollision(let currentNode):
                    let nextNode = currentNode.getNode(nodeCursor) as! T

                    if (nextNode.hasNodes)   { pushNode(nextNode) }
                    if (nextNode.hasPayload) { setupPayloadNode(nextNode) ; return true }
                }
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
struct ChampBaseReverseIterator<BitmapIndexedNode : Node, HashCollisionNode : Node> {
    typealias T = TrieNode<BitmapIndexedNode, HashCollisionNode>

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
                // TODO remove duplication in specialization
                switch nodeStack[currentStackLevel]! {
                case .bitmapIndexed(let currentNode):
                    let nextNode = currentNode.getNode(nodeCursor) as! T
                    pushNode(nextNode)
                case .hashCollision(let currentNode):
                    let nextNode = currentNode.getNode(nodeCursor) as! T
                    pushNode(nextNode)
                }
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
