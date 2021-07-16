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

static CFComparisonResult HeapCompare(const void *lhs, const void *rhs, void *context)
{
  if (*(NSInteger *)lhs == *(NSInteger *)rhs) {
    return  kCFCompareEqualTo;
  } else if (*(NSInteger *)lhs < *(NSInteger *)rhs) {
    return kCFCompareLessThan;
  } else {
    return kCFCompareGreaterThan;
  }
}

- (instancetype)init
{
  if ((self = [super init]))
  {
    CFBinaryHeapCallBacks callbacks = (CFBinaryHeapCallBacks){
      .version = 0,
      .retain = NULL,
      .release = NULL,
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
  NSInteger *val = malloc(sizeof(NSInteger));
  *val = value;
  CFBinaryHeapAddValue(_storage, val);
}

- (NSInteger)popMinimum
{
  const NSInteger *val = CFBinaryHeapGetMinimum(_storage);
  CFBinaryHeapRemoveMinimumValue(_storage);

  NSInteger value = *val;
  free((void *)val);
  return value;
}

@end
