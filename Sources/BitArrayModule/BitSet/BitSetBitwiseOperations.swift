//
//  File.swift
//  
//
//  Created by Mahanaz Atiqullah on 6/25/21.
//

extension BitSet {
    
    public mutating func formBitwiseOR(with: BitSet) {
        
        for i in with {
            if (!self.storage.contains(i)) {
                self.append(i)
            }
        }
        
        self.storage.sort()
        
    }
    
    public mutating func formBitwiseAND(with: BitSet) {
        
        self.storage.removeAll(where: {!with.contains($0)})
        
    }
    
    public mutating func formBitwiseXOR(with: BitSet) {
        for i in with {
            if (!self.storage.contains(i)) {
                self.append(i)
            } else {
                self.storage.removeAll(where: {$0 == i})
            }
        }
        
        self.storage.sort()
    }
    
}
