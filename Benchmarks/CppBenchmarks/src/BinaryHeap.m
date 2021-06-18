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

#import <Foundation/Foundation.h>

#import "BinaryHeap.h"

@implementation BinaryHeap
{
  CFBinaryHeapRef _storage;
}

static const void *HeapRetain(CFAllocatorRef allocator, const void *object)
{
  return CFRetain(object);
}

static void HeapRelease(CFAllocatorRef allocator, const void *object)
{
  CFRelease(object);
}

static CFComparisonResult HeapCompare(const void *lhs, const void *rhs, void *context)
{
  return (CFComparisonResult)[(__bridge id)lhs compare:(__bridge id)rhs];
}

- (instancetype)init
{
  if ((self = [super init]))
  {
    CFBinaryHeapCallBacks callbacks = (CFBinaryHeapCallBacks){
      .version = 0,
      .retain = &HeapRetain,
      .release = &HeapRelease,
      .copyDescription = &CFCopyDescription,
      .compare = &HeapCompare
    };
    _storage = CFBinaryHeapCreate(kCFAllocatorDefault, 0, &callbacks, NULL);
  }

  return self;
}

- (void)dealloc
{
  CFRelease(_storage);
}

- (NSUInteger)count
{
  return CFBinaryHeapGetCount(_storage);
}

- (void)insert:(NSInteger)value
{
  NSNumber *val = @(value);
  CFBinaryHeapAddValue(_storage, (__bridge const void *)val);
}

- (NSInteger)popMinimum
{
  NSNumber *val = CFBinaryHeapGetMinimum(_storage);
  CFBinaryHeapRemoveMinimumValue(_storage);
  return val.integerValue;
}

@end
