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

/*
 *  Change to PriorityQueue: Sequence once PriorityQueue.swift is made
 */
extension Heap: Sequence {
    
    /*
     *  Defines an iterator to conform to Sequence
     */
    public struct Iterator:IteratorProtocol {

        private var _base:Heap
        
        internal init(_base:Heap) {
            self._base = _base
        }
        
        /*
         *  Determines the next element in the iterator
         *  @return  the next element in the iterator, or nil if it doesn't exist
         */
        public mutating func next() -> Element? {
            return _base.remove() ?? nil
        }
        
    }
    
    /*
     *  Creates the iterator for the heap
     *  @return  the iterator for the heap
     */
    public func makeIterator() -> Iterator {
        return Iterator(_base: self)
    }
    
    
    
}
