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

#ifndef FOUNDATIONBENCHMARKS_CFBINARYHEAP_H
#define FOUNDATIONBENCHMARKS_CFBINARYHEAP_H

#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif

/// Create a `CFBinaryHeap`, populating it with data from the
/// supplied buffer. Returns an opaque pointer to the created instance.
extern void *fnd_binary_heap_create(const intptr_t *start, size_t count);

/// Destroys a binary heap previously returned by `fnd_binary_heap_create`.
extern void fnd_binary_heap_destroy(void *ptr);

/// Push a value to a binary heap.
extern void fnd_binary_heap_add(void *ptr, intptr_t value);

/// Loop through the supplied buffer, pushing each value to the heap.
extern void fnd_binary_heap_add_loop(void *ptr, const intptr_t *start, size_t count);

/// Remove and return the top value off of a binary heap.
extern intptr_t fnd_binary_heap_remove_min(void *ptr);

/// Remove and discard all values in a binary heap one by one in a loop.
extern void fnd_binary_heap_remove_min_all(void *ptr);

#ifdef __cplusplus
}
#endif

#endif /* FOUNDATIONBENCHMARKS_CFBINARYHEAP_H */
