//
//  File.swift
//  
//
//  Created by Mahanaz Atiqullah on 6/25/21.
//

extension BitSet {
    
    public mutating func append(_ newIndex: Int) { // Should it be Int? Does it really matter?
        
        // making sure the BitArray storage is big enough
        while (storage.storage.count-1 < newIndex) {
            storage.storage.append(0)
        }
        
        storage[newIndex] = true // Why does    storage.storage[newIndex] = true     not work
    }
}
