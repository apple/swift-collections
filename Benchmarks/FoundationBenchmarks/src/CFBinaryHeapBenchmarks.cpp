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

#import <stdint.h>
#import "CoreFoundation/CoreFoundation.h"
#import "Utils.h"

#import "CFBinaryHeapBenchmarks.h"

static CFComparisonResult
_compare(const void *lhs, const void *rhs, void *context)
{
  if ((intptr_t)lhs == (intptr_t)rhs) {
    return kCFCompareEqualTo;
  } else if ((intptr_t)lhs < (intptr_t)rhs) {
    return kCFCompareLessThan;
  } else {
    return kCFCompareGreaterThan;
  }
}

static CFBinaryHeapCallBacks _callbacks = {
  .version = 0,
  .retain = NULL,
  .release = NULL,
  .copyDescription = &CFCopyDescription,
  .compare = &_compare
};

void *
fnd_binary_heap_create(const intptr_t *start, size_t count)
{
  CFBinaryHeapRef heap = CFBinaryHeapCreate(kCFAllocatorDefault, 0, &_callbacks, NULL);
  fnd_binary_heap_add_loop(heap, start, count);
  return heap;
}

void fnd_binary_heap_destroy(void *ptr)
{
  CFRelease(ptr);
}

void
fnd_binary_heap_add(void *ptr, intptr_t value)
{
  CFBinaryHeapAddValue((CFBinaryHeapRef)ptr, (const void *)value);
}

void
fnd_binary_heap_add_loop(void *ptr, const intptr_t *start, size_t count)
{
  for (const intptr_t *p = start; p < start + count; p++) {
    CFBinaryHeapAddValue((CFBinaryHeapRef)ptr, (const void *)*p);
  }
}

intptr_t
fnd_binary_heap_remove_min(void *ptr)
{
  intptr_t val = (intptr_t)CFBinaryHeapGetMinimum((CFBinaryHeapRef)ptr);
  CFBinaryHeapRemoveMinimumValue((CFBinaryHeapRef)ptr);
  return val;
}

void
fnd_binary_heap_remove_min_all(void *ptr)
{
  intptr_t count = CFBinaryHeapGetCount((CFBinaryHeapRef)ptr);
  for (intptr_t i = 0; i < count; i++) {
    black_hole((intptr_t)CFBinaryHeapGetMinimum((CFBinaryHeapRef)ptr));
    CFBinaryHeapRemoveMinimumValue((CFBinaryHeapRef)ptr);
  }
}
