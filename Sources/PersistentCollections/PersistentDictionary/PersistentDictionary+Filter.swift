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
  @inlinable
  public func filter(
    _ isIncluded: (Element) throws -> Bool
  ) rethrows -> Self {
    var result: PersistentDictionary = [:]
    for item in self {
      guard try isIncluded(item) else { continue }
      // FIXME: We could do this as a structural transformation.
      let hash = _Hash(item.key)
      let inserted = result._root.insert(item, .top, hash)
      assert(inserted)
    }
    return result
  }
}
