//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Collections open source project
//
// Copyright (c) 2022 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
//
//===----------------------------------------------------------------------===//

extension PersistentDictionary {
  @inlinable
  public func mapValues<T>(
    _ transform: (Value) throws -> T
  ) rethrows -> PersistentDictionary<Key, T> {
    let transformed = try _root.mapValues { try transform($0.value) }
    return PersistentDictionary<Key, T>(_new: transformed)
  }

  @inlinable
  public func compactMapValues<T>(
    _ transform: (Value) throws -> T?
  ) rethrows -> PersistentDictionary<Key, T> {
    let result = try _root.compactMapValues(.top, transform)
    return PersistentDictionary<Key, T>(_new: result.finalize(.top))
  }
}
