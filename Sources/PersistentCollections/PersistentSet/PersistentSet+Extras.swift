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

extension PersistentSet {
  @discardableResult
  public mutating func remove(at position: Index) -> Element {
    precondition(_isValid(position))
    _invalidateIndices()
    return _root.remove(.top, at: position._path).key
  }
}
