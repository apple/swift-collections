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
  @available(*, deprecated, renamed: "updateValue(forKey:default:with:)")
  @inlinable
  public mutating func modifyValue<R>(
    forKey key: Key,
    default defaultValue: @autoclosure () -> Value,
    _ body: (inout Value) throws -> R
  ) rethrows -> R {
    try self.updateValue(forKey: key, default: defaultValue(), with: body)
  }

  @available(*, deprecated, renamed: "updateValue(forKey:insertingDefault:at:with:)")
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
