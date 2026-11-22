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

#if compiler(>=6.4)
import Builtin

extension Optional where Wrapped: ~Copyable {
  /// A span over the wrapped value of this instance.
  ///
  /// The span contains a single element when this instance has a wrapped
  /// value, and is empty when this instance is `nil`.
  ///
  /// - Returns: A `Span` over the wrapped value of this instance.
  ///
  /// - Complexity: O(1)
  @export(implementation)
  package var _span: Span<Wrapped> {
    // FIXME: Remove once SE-0555 is available in supported toolchains
    @_addressableSelf
    @_lifetime(borrow self)
    borrowing get {
      let count = (self == nil) ? 0 : 1
      let address = Builtin.unprotectedAddressOfBorrow(self)
      let span = unsafe Span<Wrapped>(
        _unsafeStart: UnsafePointer(address), count: count)
      return unsafe _overrideLifetime(span, borrowing: self)
    }
  }

  /// A mutable span over the wrapped value of this instance.
  ///
  /// The span contains a single element when this instance has a wrapped
  /// value, and is empty when this instance is `nil`.
  ///
  /// - Returns: A `MutableSpan` over the wrapped value of this instance.
  ///
  /// - Complexity: O(1)
  @export(implementation)
  package var _mutableSpan: MutableSpan<Wrapped> {
    // FIXME: Remove once SE-0555 is available in supported toolchains
    @_lifetime(&self)
    mutating get {
      let count = (self == nil) ? 0 : 1
      let address = Builtin.unprotectedAddressOf(&self)
      let span = unsafe MutableSpan<Wrapped>(
        _unsafeStart: UnsafeMutablePointer(address), count: count)
      return unsafe _overrideLifetime(span, mutating: &self)
    }
  }
}
#endif
