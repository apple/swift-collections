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

//extension _Node.UnsafeHandle: Equatable where Key: Equatable, Value: Equatable {
//  /// Compares whether the subtree rooted at the following node is equatable to another node
//  // TODO: optimized node equality checking is non-trivial
//  @inlinable
//  @inline(__always)
//  internal static func ==(lhs: Self, rhs: Self) -> Bool {
//    // Two nodes of varying sizes cannot be equal
//    if lhs.subtreeCount != rhs.subtreeCount { return false }
//
//    // If two nodes share the same header, they are by pointer identity the same
//    // node.
//    if lhs.header == rhs.header { return true }
//
//
//    for i in 0..<lhs.elementCount {
//
//    }
//
//    // TODO: is it faster to compare the keys first or children first
//  }
//}
