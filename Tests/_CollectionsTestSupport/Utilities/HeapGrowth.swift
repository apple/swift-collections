//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Collections open source project
//
// Copyright (c) 2026 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
//
// SPDX-License-Identifier: Apache-2.0 WITH Swift-exception
//
//===----------------------------------------------------------------------===//

#if canImport(Darwin)
import Darwin
#endif

/// Returns the number of bytes currently allocated on the heap, or `nil` if
/// this information isn't available on the current platform.
public func _heapBytesInUse() -> Int? {
#if canImport(Darwin)
  var stats = malloc_statistics_t()
  unsafe malloc_zone_statistics(nil, &stats)
  return stats.size_in_use
#else
  return nil
#endif
}

/// Runs `body`, then reports a test failure if the heap grew by `tolerance`
/// bytes or more during its execution.
///
/// This is useful for catching leaks of raw allocations (such as storage
/// buffers) that `LifetimeTracked` cannot detect. To get a reliable signal,
/// `body` should repeat the operation under test many times, so that a leak
/// would grow the heap well beyond `tolerance`. Avoid calling `expect*`
/// functions within `body`, as failures allocate memory.
///
/// On platforms where heap statistics are unavailable, this simply runs
/// `body` without checking anything.
public func expectNoHeapGrowth<E: Error, R>(
  tolerance: Int,
  _ message: @autoclosure () -> String = "",
  file: StaticString = #filePath,
  line: UInt = #line,
  _ body: () throws(E) -> R
) throws(E) -> R {
  guard let before = _heapBytesInUse() else { return try body() }
  let result = try body()
  let growth = _heapBytesInUse()! - before
  if growth >= tolerance {
    _expectFailure(
      "Heap grew by \(growth) bytes (tolerance: \(tolerance))",
      message, trapping: false, file: file, line: line)
  }
  return result
}
