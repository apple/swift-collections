//
//  File.swift
//  
//
//  Created by Mahanaz Atiqullah on 6/4/21.
//



// NOTE: Research @inlinable

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
    
    // there is a potential to remove adjustExcess(), since the if-else block within adjustExcess() would only be need if newValue == true && excess != 0 (basically only if we get to the else block at the end of the append function). Basides that, all other cases would be excess += 1
    private mutating func adjustExcess(){
        if (self.excess == 7) {
            self.excess = 0
        } else {
            self.excess += 1
        }
    }
    
   /* public mutating func removeAll() {
        self.storage = []
        self.excess = 0
    }*/
    
}

// testArray.formBitwiseOr(with: b) - mutating
// testArray.bitwiseOr(with: b) - NONmutating
