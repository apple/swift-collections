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

func computeHash<T: Hashable>(_ value: T) -> Int {
    value.hashValue
}

typealias Bitmap = UInt32

extension Bitmap {
    public func nonzeroBits() -> NonzeroBits<Self> {
        return NonzeroBits(from: self)
    }

    public func zeroBits() -> NonzeroBits<Self> {
        return NonzeroBits(from: ~self)
    }
}

public struct NonzeroBits<Bitmap>: Sequence, IteratorProtocol, CustomStringConvertible where Bitmap: BinaryInteger {
    var bitmap: Bitmap

    init(from bitmap: Bitmap) {
        self.bitmap = bitmap
    }

    public mutating func next() -> Int? {
        guard bitmap != 0 else { return nil }

        let index = bitmap.trailingZeroBitCount
        bitmap ^= 1 << index

        return index
    }

    public var description: String {
        "[\(self.map { $0.description }.joined(separator: ", "))]"
    }
}

let bitPartitionSize: Int = 5

let bitPartitionMask: Int = (1 << bitPartitionSize) - 1

typealias Capacity = UInt8

let hashCodeLength: Int = Int.bitWidth

let maxDepth = Int((Double(hashCodeLength) / Double(bitPartitionSize)).rounded(.up))

func maskFrom(_ hash: Int, _ shift: Int) -> Int {
    (hash >> shift) & bitPartitionMask
}

func bitposFrom(_ mask: Int) -> Bitmap {
    1 << mask
}

func indexFrom(_ bitmap: Bitmap, _ bitpos: Bitmap) -> Int {
    (bitmap & (bitpos &- 1)).nonzeroBitCount
}

func indexFrom(_ bitmap: Bitmap, _ mask: Int, _ bitpos: Bitmap) -> Int {
    (bitmap == Bitmap.max) ? mask : indexFrom(bitmap, bitpos)
}

enum TrieNode<BitmapIndexedNode: Node, HashCollisionNode: Node> {
    case bitmapIndexed(BitmapIndexedNode)
    case hashCollision(HashCollisionNode)

    /// The convenience computed properties below are used in the base iterator implementations.

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

protocol Node: AnyObject {
    associatedtype ReturnPayload
    associatedtype ReturnBitmapIndexedNode: Node
    associatedtype ReturnHashCollisionNode: Node

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
struct ChampBaseIterator<BitmapIndexedNode: Node, HashCollisionNode: Node> {
    typealias T = TrieNode<BitmapIndexedNode, HashCollisionNode>

    var currentValueCursor: Int = 0
    var currentValueLength: Int = 0
    var currentValueNode: T? = nil

    private var currentStackLevel: Int = -1
    private var nodeCursorsAndLengths: [Int] = Array(repeating: 0, count: maxDepth * 2)
    private var nodes: [T?] = Array(repeating: nil, count: maxDepth)

    init(rootNode: T) {
        if rootNode.hasNodes   { pushNode(rootNode) }
        if rootNode.hasPayload { setupPayloadNode(rootNode) }
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
        while currentStackLevel >= 0 {
            let cursorIndex = currentStackLevel * 2
            let lengthIndex = currentStackLevel * 2 + 1

            let nodeCursor = nodeCursorsAndLengths[cursorIndex]
            let nodeLength = nodeCursorsAndLengths[lengthIndex]

            if nodeCursor < nodeLength {
                nodeCursorsAndLengths[cursorIndex] += 1

                // TODO remove duplication in specialization
                switch nodes[currentStackLevel]! {
                case .bitmapIndexed(let currentNode):
                    let nextNode = currentNode.getNode(nodeCursor) as! T

                    if nextNode.hasNodes   { pushNode(nextNode) }
                    if nextNode.hasPayload { setupPayloadNode(nextNode) ; return true }
                case .hashCollision(let currentNode):
                    let nextNode = currentNode.getNode(nodeCursor) as! T

                    if nextNode.hasNodes   { pushNode(nextNode) }
                    if nextNode.hasPayload { setupPayloadNode(nextNode) ; return true }
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
struct ChampBaseReverseIterator<BitmapIndexedNode: Node, HashCollisionNode: Node> {
    typealias T = TrieNode<BitmapIndexedNode, HashCollisionNode>

    var currentValueCursor: Int = -1
    var currentValueNode: T? = nil

    private var currentStackLevel: Int = -1
    private var nodeIndex: [Int] = Array(repeating: 0, count: maxDepth + 1)
    private var nodeStack: [T?] = Array(repeating: nil, count: maxDepth + 1)

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
        while currentStackLevel >= 0 {
            let nodeCursor = nodeIndex[currentStackLevel] ; nodeIndex[currentStackLevel] = nodeCursor - 1

            if nodeCursor >= 0 {
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

                if currNode.hasPayload { setupPayloadNode(currNode) ; return true }
            }
        }

        return false
    }

    mutating func hasNext() -> Bool {
        return (currentValueCursor >= 0) || searchNextValueNode()
    }
}

func rangeInsert<T>(_ element: T, at index: Int, intoRange range: Range<UnsafeMutablePointer<T>>) {
    let seq = range.dropFirst(index)

    let src = seq.startIndex
    let dst = src.successor()

    dst.moveInitialize(from: src, count: seq.count)

    src.initialize(to: element)
}

// NEW
@inlinable
@inline(__always)
func rangeInsert<T>(_ element: T, at index: Int, into baseAddress: UnsafeMutablePointer<T>, count: Int) {
    let src = baseAddress.advanced(by: index)
    let dst = src.successor()

    dst.moveInitialize(from: src, count: count - index)

    src.initialize(to: element)
}

// `index` is the logical index starting at the rear, indexing to the left
func rangeInsertReversed<T>(_ element: T, at index: Int, intoRange range: Range<UnsafeMutablePointer<T>>) {
    let seq = range.dropLast(index)

    let src = seq.startIndex
    let dst = src.predecessor()

    dst.moveInitialize(from: src, count: seq.count)

    // requires call to predecessor on "past the end" position
    seq.endIndex.predecessor().initialize(to: element)
}

func rangeRemove<T>(at index: Int, fromRange range: Range<UnsafeMutablePointer<T>>) {
    let seq = range.dropFirst(index + 1)

    let src = seq.startIndex
    let dst = src.predecessor()

    dst.deinitialize(count: 1)
    dst.moveInitialize(from: src, count: seq.count)
}

// NEW
@inlinable
@inline(__always)
func rangeRemove<T>(at index: Int, from baseAddress: UnsafeMutablePointer<T>, count: Int) {
    let src = baseAddress.advanced(by: index + 1)
    let dst = src.predecessor()

    dst.deinitialize(count: 1)
    dst.moveInitialize(from: src, count: count - index - 1)
}

// `index` is the logical index starting at the rear, indexing to the left
func rangeRemoveReversed<T>(at index: Int, fromRange range: Range<UnsafeMutablePointer<T>>) {
    let seq = range.dropLast(index + 1)

    let src = seq.startIndex
    let dst = src.successor()

    seq.endIndex.deinitialize(count: 1)
    dst.moveInitialize(from: src, count: seq.count)
}
