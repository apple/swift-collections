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
  /// Return a new dictionary that has the specified key-value pair in addition
  /// to all existing elements in this dictionary.
  ///
  /// If `self` already contains the given key, then the result replaces its
  /// original value in `self` with `value`, without updating the existing key.
  /// (In some cases, equal keys may be distinguishable from each other by
  /// identity comparison or some other means.)
  ///
  /// - Parameters:
  ///   - value: The new value to add to the dictionary.
  ///   - key: The key to associate with `value`. If `key` already exists in
  ///     the dictionary, `value` replaces the existing associated value in the
  ///     result. If `key` isn't already a key of the dictionary, then the
  ///     `(key, value)` pair is added to the result.
  ///
  /// - Returns: A new dictionary with the update applied.
  ///
  /// - Complexity: This operation is expected to copy at most O(log(`count`))
  ///    existing members and to perform at most O(1) hashing/comparison
  ///    operations on the `Element` type, as long as `Element` properly
  ///    implements hashing.
  @inlinable
  public func updatingValue(_ value: Value, forKey key: Key) -> Self {
    var copy = self
    copy.updateValue(value, forKey: key)
    return copy
  }

  /// Return a new dictionary that contains all key-value pairs that are in
  /// this dictionary except for the pair that matches given `key`.
  ///
  /// If this dictionary does not contain a value for `key`, then this
  /// method simply returns `self`.
  ///
  /// - Parameter key: The key to remove from the returned dictionary.
  ///
  /// - Returns: A new dictionary with all existing key-value pairs in `self`
  ///    except for the one that matches `key` (if any).
  ///
  /// - Complexity: This operation is expected to copy at most O(log(`count`))
  ///    existing members and to perform at most O(1) hashing/comparison
  ///    operations on the `Element` type, as long as `Element` properly
  ///    implements hashing.
  @inlinable
  public func removingValue(forKey key: Key) -> Self {
    guard let r = _root.removing(.top, key, _Hash(key)) else { return self }
    return Self(_new: r.replacement.finalize(.top))
  }
}
