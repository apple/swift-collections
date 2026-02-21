//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Collections open source project
//
// Copyright (c) 2026 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
//
//===----------------------------------------------------------------------===//

#if compiler(>=6.3) && COLLECTIONS_UNSTABLE_NONCOPYABLE_KEYS

@available(SwiftStdlib 5.0, *)
extension UniqueSet where Element: ~Copyable {
  @inlinable
  package mutating func _insert(
    _ item: consuming Element
  ) -> RigidSet<Element>._InsertResult {
    let r = _storage._find(item)
    if let bucket = r.bucket {
      return .init(bucket: bucket, remnant: item)
    }
    var hashValue = r.hashValue
    if _ensureFreeCapacity(1) {
      hashValue = _storage._hashValue(for: item)
    }
    let bucket = _storage._insertNew(item, hashValue: hashValue)
    return .init(bucket: bucket, remnant: nil)
  }
  
  /// Inserts the given element into the set unconditionally. If the set already
  /// contained a member equal to `item`, then the new item replaces it.
  ///
  /// - Parameter item: An element to insert into the set.
  /// - Returns: An element equal to `item` if the set already contained such
  ///    a member, otherwise `nil`.
  @inlinable
  @discardableResult
  public mutating func update(
    with item: consuming Element
  ) -> Element? {
    var r = self._insert(item)
    guard let remnant = r.remnant.take() else { return nil }
    return exchange(
      &_storage._memberPtr(at: r.bucket).pointee,
      with: remnant)
  }

  /// Inserts the given element in the set if it is not already present.
  ///
  /// - Parameter item: An element to insert into the set.
  /// - Returns:
  @inlinable
  @discardableResult
  public mutating func insert(
    _ item: consuming Element
  ) -> Element? {
    var r = self._insert(item)
    return r.remnant.take()
  }
}

#endif
