//
//  BitArray.swift
//  
//
//  Created by Mahanaz Atiqullah on 5/21/21.
//

public struct BitArray {
  typealias UNIT = UInt8  // created for experimental purposes to make it easier to test different UInts without having to change a lot of the code
  
  // Will start off storing elements little-endian just because I have a hunch the calculations might be cleaner
  var storage : [UNIT] = []
  var excess: UInt8 = 0
  
  public init() { }
  
}
