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

extension PriorityQueue:Sequence{
    
    /*
     *  Defines an iterator to conform to Sequence
     */
    public struct Iterator:IteratorProtocol{
        //the priority queue at a specific moment
        private var _base:PriorityQueue
        
        internal init(_base:PriorityQueue){
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
     *  Creates the iterator for the priority queue
     *  @return  the iterator for the priority queue
     */
    public func makeIterator() -> Iterator {
        return Iterator(_base: self)
    }
    
    
    
}
