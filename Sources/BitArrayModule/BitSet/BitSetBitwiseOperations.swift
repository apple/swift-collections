//
//  File.swift
//  
//
//  Created by Mahanaz Atiqullah on 6/25/21.
//

extension BitSet {
    
    public mutating func formBitwiseOR(with: BitSet) {
        
        
        
    }
    
    public mutating func formBitwiseAND(with: BitSet) {
        
        for i in with {
            if (!self.storage.contains(i)) {
                self.append(i)
            }
        }
        
        self.storage.sort()
    }
    
    public mutating func formBitwiseXOR(with: BitSet) {
        
    }
    
}
