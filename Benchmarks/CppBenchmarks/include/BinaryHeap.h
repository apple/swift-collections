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

#ifndef BinaryHeap_h
#define BinaryHeap_h

#if __APPLE__ // CFBinaryHeap only exists on Apple platforms

@import Foundation;

@interface BinaryHeap: NSObject

@property (nonatomic, readonly) NSUInteger count;

- (void)insert:(NSInteger)value;
- (NSInteger)popMinimum;

@end

#endif // __APPLE__
#endif /* BinaryHeap_h */
