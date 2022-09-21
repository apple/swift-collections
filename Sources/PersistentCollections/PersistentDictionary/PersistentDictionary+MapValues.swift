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
    let transformed = try _root.mapValues(transform)
    return PersistentDictionary<Key, T>(_new: transformed)
  }

  @inlinable
  public func compactMapValues<T>(
    _ transform: (Value) throws -> T?
  ) rethrows -> PersistentDictionary<Key, T> {
    // FIXME: We could do this as a structural transformation.
    var result: PersistentDictionary<Key, T> = [:]
    for (key, v) in self {
      guard let value = try transform(v) else { continue }
      let hash = _Hash(key)
      let inserted = result._root.insert((key, value), .top, hash)
      assert(inserted)
    }
    return result
  }
}
