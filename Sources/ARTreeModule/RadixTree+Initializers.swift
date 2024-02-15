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

@available(macOS 13.3, iOS 16.4, watchOS 9.4, tvOS 16.4, *)
extension RadixTree {
  /// Creates a Radix Tree collection from a sequence of key-value pairs.
  ///
  /// If duplicates are encountered the last instance of the key-value pair is the one
  /// that is kept.
  ///
  /// - Parameter keysAndValues: A sequence of key-value pairs to use
  ///     for the new Radix Tree.
  /// - Complexity: O(n*k)
  @inlinable
  @inline(__always)
  public init<S>(
    keysWithValues keysAndValues: S
  ) where S: Sequence, S.Element == (key: Key, value: Value) {
    self.init()

    for (key, value) in keysAndValues {
      _ = self.updateValue(value, forKey: key)
    }
  }
}
