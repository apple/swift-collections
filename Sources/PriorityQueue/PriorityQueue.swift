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
public enum HeapType{
    case max;
    case min;
}

/*
 *  Implements a PriorityQueue using an array-based min/max binary heap.
 */
struct PriorityQueue<Element:Comparable>{
    
    //The underlying storage for the min/max heap
    private var storage:[Element];
    
    //Indicates the type of binary heap "storage" is
    private let storageType:HeapType;
    
    //initialize instance variables
    //eventually add a constructor that accepts a Sequence and generates the underlying storage in O(n) instead of O(nlogn)
    public init(priorityQueueType:HeapType){
        storage = [Element]()
        storageType = priorityQueueType
    }
    
    /*
     *  Adds an element to the Priority Queue
     *  @param  value  the element to add to the Priority Queue
     *  @return  true if value could be added, false otherwise
     */
    public mutating func enqueue(value:Element) -> Bool{
        storage.append(value)
        swimUp(elementIndex: storage.count-1);
        
        return true;
    }
    
    /*
     *  Moves a specified element down the array (towards index zero) until it's in its natural position
     *  @param  elementIndex  the index of the specified element
     */
    private mutating func swimUp(elementIndex:Int){
        var parentIndex = getParent(index: elementIndex)
        var currentIndex = elementIndex
        var temp:Element;
        while(parentIndex != -1){
            if(compare(firstElement: storage[currentIndex], secondElement: storage[parentIndex]) < 0){
                //swap currentElement with parentIndex to preserve binary heap order
                temp = storage[parentIndex]
                storage[parentIndex] = storage[currentIndex]
                storage[currentIndex] = temp
            }
            currentIndex = parentIndex
            //ends the loop when the parentIndex is at the root
            parentIndex = (parentIndex == 0) ? -1 : getParent(index: parentIndex);
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
    private func compare(firstElement:Element, secondElement:Element) -> Int{
        //doesn't depend on storageType
        if(firstElement == secondElement){
            return 0;
        }
        
        if(storageType == .min){
            if(firstElement < secondElement){
                return -1;
            }else{
                return 1;
            }
        }else{
            if(firstElement < secondElement){
                return 1;
            }else{
                return -1;
            }
        }
    }
    
    /*
     *  Determines the parent of a certain element
     *  @param  index  a valid index of a certian element
     *  @return  the index of a certain element's parent, or -1 if the element has no parent
     */
    private func getParent(index:Int) -> Int{
        let parent = (index-1)/2
        return (parent < 0) ? -1 : parent;
    }
    
    /*
     *  Determines the left child of a certian element
     *  @param  index  a valid index of a certain element
     *  @return  the index of a certain element's left child, or -1 if the element has no left child
     */
    private func getLeftChild(index:Int) -> Int{
        let child = (2*index)+1
        return (child >= size()) ? -1 : child;
    }
    
    /*
     *  Determines the right child of a certian element
     *  @param  index  a valid index of a certain element
     *  @return  the index of a certain element's right child, or -1 if the element has no right child
     */
    private func getRightChild(index:Int) -> Int{
        let child = (2*index)+2
        return (child >= size()) ? -1 : child;
    }
    
    /*
     *  Removes the item with highest/lowest priority in the Priority Queue
     *  @return  the item with highest/lowest priority or nil if the Priority Queue is empty
     */
    public mutating func dequeue() -> Element?{
        if(isEmpty() == true){
            return nil;
        }
        let removedElement = storage[0];
        storage[0] = storage.last!
        storage.removeLast()
        sinkDown(elementIndex: 0)
        return removedElement;
    }
    
    /*
     *  Moves a specified element up the array (away from index zero) until it's in its natural position
     */
    private mutating func sinkDown(elementIndex:Int){
        var currentIndex = elementIndex
        var leftChild = getLeftChild(index: elementIndex)
        var rightChild = getRightChild(index: elementIndex)
        var childToSwap:Int
        var temp:Element
        
        //loops until a swap is not needed or currentIndex has no children
        while(true){
            //chooses which child to swap currentIndex with
            if(leftChild != -1 && rightChild != -1){
                //both children are present
                childToSwap = (compare(firstElement: storage[leftChild], secondElement: storage[rightChild]) < 0) ? leftChild : rightChild;
            }else if(leftChild != -1){
                //only left child present
                childToSwap = leftChild
            }else if(rightChild != -1){
                //only right child present
                childToSwap = rightChild
            }else{
                //neither children present
                break;
            }
            //swap currentIndex with appropriate child if needed
            if(compare(firstElement: storage[childToSwap], secondElement: storage[currentIndex]) < 0){
                temp = storage[currentIndex]
                storage[currentIndex] = storage[childToSwap]
                storage[childToSwap] = temp
                
                //updates children and current index in case swap caused more problems
                currentIndex = childToSwap;
                leftChild = getLeftChild(index: childToSwap)
                rightChild = getRightChild(index: childToSwap)
            }else{
                //swap is not needed
                break;
            }
        }
        
        
    }
    
    /*
     *  Determines whether the Priority Queue is full.
     *  @return  true if the PriorityQueue is full, false otherwise
     */
    public func isFull() -> Bool{
        return false; //The resizable Priority Queue is never full
    }
    
    /*
     *  Determines whether the Priority Queue is empty.
     *  @return  true if the Priority Queue is empty, false otherwise
     */
    public func isEmpty() -> Bool{
        return size() == 0;
    }
    
    /*
     *  Determines the size of the Priority Queue
     */
    public func size() -> Int{
        return storage.count;
    }
    
}
