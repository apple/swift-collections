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

extension PersistentDictionary: CustomStringConvertible {
  public var description: String {
    _dictionaryDescription(for: self)
  }
}

extension PersistentDictionary: CustomDebugStringConvertible {
  public var debugDescription: String {
    _dictionaryDescription(
      for: self, debug: true, typeName: _debugTypeName())
  }

  internal func _debugTypeName() -> String {
    "PersistentDictionary<\(Key.self), \(Value.self)>"
  }
}
