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

extension OrderedDictionary {
  /// Accesses the element at the specified index.
  ///
  /// - Parameter offset: The offset of the element to access, measured from
  ///   the start of the collection. `offset` must be greater than or equal to
  ///   `0` and less than `count`.
  ///
  /// - Complexity: O(1)
  @available(*, deprecated, // since 0.0.6
              message: "Please use `elements[offset]`")
  @inlinable
  @inline(__always)
  public subscript(offset offset: Int) -> Element {
    (_keys[offset], _values[offset])
  }
}

extension OrderedDictionary {
  // Deprecated since 0.0.6
  @available(*, deprecated, // since 0.0.6
              renamed: "updateValue(forKey:default:with:)")
  @inlinable
  public mutating func modifyValue<R>(
    forKey key: Key,
    default defaultValue: @autoclosure () -> Value,
    _ body: (inout Value) throws -> R
  ) rethrows -> R {
    try self.updateValue(forKey: key, default: defaultValue(), with: body)
  }

  @available(*, deprecated, // since 0.0.6
              renamed: "updateValue(forKey:insertingDefault:at:with:)")
  @inlinable
  public mutating func modifyValue<R>(
    forKey key: Key,
    insertingDefault defaultValue: @autoclosure () -> Value,
    at index: Int,
    _ body: (inout Value) throws -> R
  ) rethrows -> R {
    try self.updateValue(
      forKey: key,
      insertingDefault: defaultValue(),
      at: index,
      with: body)
  }
}
