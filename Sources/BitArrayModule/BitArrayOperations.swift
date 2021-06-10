//
//  File.swift
//  
//
//  Created by Mahanaz Atiqullah on 6/4/21.
//



// NOTE: Research @inlinable

import  Foundation

extension BitArray {
    
public mutating func append(_ newValue: Bool) {
        if (!newValue) {
            if(excess == 0) { storage.append(0)}
            adjustExcess() // excess += 1
            return
        }
        
        if (excess == 0) {
            storage.append(1)
        } else {
            storage[storage.endIndex-1] += (1 << excess)
        }
        adjustExcess()
    }
    
    private mutating func adjustExcess(){
        if (self.excess == 7) {
            self.excess = 0
        } else {
            self.excess += 1
        }
    }
}
