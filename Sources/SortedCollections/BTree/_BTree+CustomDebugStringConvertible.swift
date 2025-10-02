//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Collections open source project
//
// Copyright (c) 2021 - 2025 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
//
//===----------------------------------------------------------------------===//

#if COLLECTIONS_UNSTABLE_SORTED_COLLECTIONS

extension _BTree: CustomDebugStringConvertible {
  #if DEBUG
  /// A textual representation of this instance, suitable for debugging.
  public var debugDescription: String {
    return "BTree<\(Key.self), \(Value.self)>\n" +
      self.root.read { String(reflecting: $0) }
  }
  #else
  /// A textual representation of this instance, suitable for debugging.
  public var debugDescription: String {
    return "BTree<\(Key.self), \(Value.self)>(\(self.root))"
  }
  #endif // DEBUG
}

#endif
