//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Collections open source project
//
// Copyright (c) 2021 - 2022 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
//
//===----------------------------------------------------------------------===//

import _CollectionsUtilities

extension OrderedDictionary: CustomStringConvertible {
  /// A textual representation of this instance.
  public var description: String {
    _dictionaryDescription(for: self.elements)
  }
}

extension OrderedDictionary: CustomDebugStringConvertible {
  /// A textual representation of this instance, suitable for debugging.
  public var debugDescription: String {
    _dictionaryDescription(for: self.elements, typeName: _debugTypeName())
  }

  internal func _debugTypeName() -> String {
    "OrderedDictionary<\(Key.self), \(Value.self)>"
  }
}
