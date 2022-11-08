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

import _CollectionsUtilities

extension ShareableDictionary: CustomStringConvertible {
  // A textual representation of this instance.
  public var description: String {
    _dictionaryDescription(for: self)
  }
}

extension ShareableDictionary: CustomDebugStringConvertible {
  /// A textual representation of this instance, suitable for debugging.
  public var debugDescription: String {
    _dictionaryDescription(
      for: self, debug: true, typeName: Self._debugTypeName())
  }

  internal static func _debugTypeName() -> String {
    "ShareableDictionary<\(Key.self), \(Value.self)>"
  }
}
