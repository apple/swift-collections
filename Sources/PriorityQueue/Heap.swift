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

//Indicates a min or max heap
public enum HeapType {
    case max
    case min
} 

/*
 *  Implements a min/max binary heap.
 */
public struct Heap<Element: Comparable> {
    
    //The underlying storage for the min/max heap
    private var _storage: [Element]
    
    //Indicates the type of binary heap "storage" is
    private let _storageType: HeapType
    
    /*
     *eventually add a constructor that accepts a Sequence and generates the underlying storage in O(n) instead of O(nlogn)
     */
    public init(heapType: HeapType) {
        _storage = [Element]()
        _storageType = heapType
    }
    
    /*
     *  Adds an element to the heap
     *  @param  value  the element to add to the heap
     */
    public mutating func insert(value: Element) {
        _storage.append(value)
        _raise(elementIndex: _storage.count-1)
    }
    
    /*
     *  Moves a specified element down the array (towards index zero) until it's in its natural position
     *  @param  elementIndex  the index of the specified element
     */
    private mutating func _raise(elementIndex: Int) {
        var parentIndex = _getParent(index: elementIndex)
        var currentIndex = elementIndex
        var temp:Element;
        while(parentIndex != -1){
            if(_compare(firstElement: _storage[currentIndex], secondElement: _storage[parentIndex]) < 0){
                //swap currentElement with parentIndex to preserve binary heap order
                temp = _storage[parentIndex]
                _storage[parentIndex] = _storage[currentIndex]
                _storage[currentIndex] = temp
            }
            currentIndex = parentIndex
            //ends the loop when the parentIndex is at the root
            parentIndex = (parentIndex == 0) ? -1 : _getParent(index: parentIndex)
        }
    }
    
    /*
     *  Determines whether firstElement comes before (smaller index) or after (larger index) the secondElement in the underlying storage based on the storageType
     *  @param  firstElement  the first element to compare
     *  @param  secondElement  the second element to compare
     *  @return  -1 if firstElement comes before secondElement,
                  0 if firstElement is equal to secondElement,
                  1 if firstElement goes after secondElement
     */
    private func _compare(firstElement: Element, secondElement: Element) -> Int {
        //doesn't depend on storageType
        if(firstElement == secondElement){
            return 0;
        }
        
        if(_storageType == .min){
            if(firstElement < secondElement){
                return -1
            }else{
                return 1
            }
        }else{
            if(firstElement < secondElement){
                return 1
            }else{
                return -1
            }
        }
    }
    
    /*
     *  Determines the parent of a certain element
     *  @param  index  a valid index of a certian element
     *  @return  the index of a certain element's parent, or -1 if the element has no parent
     */
    private func _getParent(index: Int) -> Int {
        let parent = (index-1)/2
        return (parent < 0) ? -1 : parent
    }
    
    /*
     *  Determines the left child of a certian element
     *  @param  index  a valid index of a certain element
     *  @return  the index of a certain element's left child, or -1 if the element has no left child
     */
    private func _getLeftChild(index: Int) -> Int {
        let child = (2*index)+1
        return (child >= count()) ? -1 : child
    }
    
    /*
     *  Determines the right child of a certian element
     *  @param  index  a valid index of a certain element
     *  @return  the index of a certain element's right child, or -1 if the element has no right child
     */
    private func _getRightChild(index: Int) -> Int {
        let child = (2*index)+2
        return (child >= count()) ? -1 : child
    }
    
    /*
     *  Removes the min or max element in the heap
        *func name needs to be more specific when min and max heap is implemented (both)
     *  @return  the min or max element, or nil if the heap is empty
     */
    public mutating func remove() -> Element? {
        if(isEmpty() == true){
            return nil
        }
        
        let removedElement = _storage[0];
        _storage[0] = _storage.last!
        _storage.removeLast()
        _lower(elementIndex: 0)
        return removedElement
    }
    
    /*
     *  Moves a specified element up the array (away from index zero) until it's in its natural position
     */
    private mutating func _lower(elementIndex: Int) {
        var currentIndex = elementIndex
        var leftChild = _getLeftChild(index: elementIndex)
        var rightChild = _getRightChild(index: elementIndex)
        var childToSwap:Int
        var temp:Element
        
        //loops until a swap is not needed or currentIndex has no children
        while(true) {
            //chooses which child to swap currentIndex with
            if(leftChild != -1 && rightChild != -1){
                //both children are present
                childToSwap = (_compare(firstElement: _storage[leftChild], secondElement: _storage[rightChild]) < 0) ? leftChild : rightChild;
            }else if(leftChild != -1){
                //only left child present
                childToSwap = leftChild
            }else if(rightChild != -1){
                //only right child present
                childToSwap = rightChild
            }else{
                //neither children present
                break
            }
            //swap currentIndex with appropriate child if needed
            if(_compare(firstElement: _storage[childToSwap], secondElement: _storage[currentIndex]) < 0){
                temp = _storage[currentIndex]
                _storage[currentIndex] = _storage[childToSwap]
                _storage[childToSwap] = temp
                
                //updates children and current index in case swap caused more problems
                currentIndex = childToSwap;
                leftChild = _getLeftChild(index: childToSwap)
                rightChild = _getRightChild(index: childToSwap)
            }else{
                //swap is not needed
                break
            }
        }
        
        
    }
    
    /*
     *  Determines the min or max element, depending on the heap type
        *func name needs to change when min and max heap is implemented (both)
     *  @return  the min or max element, or nil if no elements exist
     */
    public func peek() -> Element? {
        if(isEmpty() == true){
            return nil
        }
        return _storage[0]
    }
    
    /*
     *  Determines whether the heap is empty.
     *  @return  true if the heap is empty, false otherwise
     */
    public func isEmpty() -> Bool {
        return count() == 0
    }
    
    /*
     *  Determines the size of the heap
     */
    public func count() -> Int {
        return _storage.count
    }
    
    /*
     *  Determines the heap type of the current heap
     *  @return  the heap type of the current heap
     */
    public func getHeapType() -> HeapType {
        return _storageType
    }
    
}
