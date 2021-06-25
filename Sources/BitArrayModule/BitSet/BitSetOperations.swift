//
//  File.swift
//  
//
//  Created by Mahanaz Atiqullah on 6/25/21.
//

extension BitSet {
    
    //needs performance work
    public mutating func append(_ trueIndex: UInt8) {
        storage.append(trueIndex)
        storage.sort()
    }
}
