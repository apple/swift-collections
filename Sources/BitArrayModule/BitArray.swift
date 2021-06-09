//
//  File.swift
//  
//
//  Created by Mahanaz Atiqullah on 5/21/21.
//

public struct BitArray {
    typealias UNIT = UInt8  // created for experimental purposes to make it easier to test different UInts without having to change a lot of the code
    
    // Will start off storing elements little-endian just because I have a hunch the calculations might be cleaner
    var storage : [UNIT] = []
    var excess: UInt8 = 0 // I've been playng around with this variable to get some sort of size going. This probably isn't the best way but I'm working on it and evolving it. First I had this as 'size' which basically stored the count, but that was very obviously problematic, even if I just wanted it to get things initially working. Besides, only storing the 'excess' is probably closer to the solution Im anticipating to have
    
    public init() { }
    
    
}
