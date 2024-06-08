//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Collections open source project
//
// Copyright (c) 2023 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
//
//===----------------------------------------------------------------------===//

// TODO: Subscripts with default value, ranges and index.
@available(macOS 13.3, iOS 16.4, watchOS 9.4, tvOS 16.4, *)
extension RadixTree {
  /// Accesses the value associated with the key for both read and write operations
  ///
  /// This key-based subscript returns the value for the given key if the key is found in
  /// the tree, or nil if the key is not found.
  ///
  /// When you assign a value for a key and that key already exists, the tree overwrites
  /// the existing value. If the tree doesn’t contain the key, the key and value are added
  /// as a new key-value pair.
  ///
  /// - Parameter key: The key to find in the tree
  /// - Returns: The value associated with key if key is in the tree; otherwise, nil.
  /// - Complexity: O(?)
  @inlinable
  @inline(__always)
  public subscript(key: Key) -> Value? {
    get {
      return self.getValue(forKey: key)
    }

    set {
      if let newValue = newValue {
        _ = self.updateValue(newValue, forKey: key)
      } else {
        self.removeValue(forKey: key)
      }
    }
  }
}
