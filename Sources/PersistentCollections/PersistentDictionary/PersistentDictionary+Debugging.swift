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

extension PersistentDictionary {
  public static var _isConsistencyCheckingEnabled: Bool {
    _isCollectionsInternalCheckingEnabled
  }

  @inlinable
  public func _invariantCheck() {
    _root._fullInvariantCheck(.top, _Hash(_value: 0))
  }

  public func _dump(iterationOrder: Bool = false) {
    _root.dump(iterationOrder: iterationOrder)
  }

  public static var _maxDepth: Int {
    _Level.limit
  }
}
