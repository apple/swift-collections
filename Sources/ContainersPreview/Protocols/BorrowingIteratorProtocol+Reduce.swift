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

#if compiler(>=6.4) && UnstableContainersPreview

@available(SwiftStdlib 6.4, *)
extension BorrowingIteratorProtocol
where
  Self: ~Copyable & ~Escapable,
  Element: ~Copyable
{
  @inlinable
  public consuming func reduce<Result: ~Copyable>(
    _ initialResult: consuming Result,
    _ nextPartialResult: (consuming Result, borrowing Element) throws(Failure) -> Result
  ) throws(Failure) -> Result {
    var result = initialResult
    while true {
      let span = try self.nextSpan()
      guard !span.isEmpty else { break }
      var i = 0
      while i < span.count {
        result = try nextPartialResult(result, span[unchecked: i])
        i &+= 1
      }
    }
    return result
  }

  @inlinable
  public consuming func reduce<Result: ~Copyable>(
    into initialResult: consuming Result,
    _ updateAccumulatingResult: (inout Result, borrowing Element) throws(Failure) -> Void
  ) throws(Failure) -> Result {
    var result = initialResult
    while true {
      let span = try self.nextSpan()
      guard !span.isEmpty else { break }
      var i = 0
      while i < span.count {
        try updateAccumulatingResult(&result, span[unchecked: i])
        i &+= 1
      }
    }
    return result
  }
}

#endif
