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
      // FIXME: We could recover the key's hash from self.
      // (As many bits of it as we need to insert it into the new tree.)
      // However, this requires a series of `UInt32._bit(ranked:)` invocations
      // that may or may not be meaningfully better than simply rehashing the
      // key.
      let hash = _Hash(item.key)
      let r = result._root.updateValue(item.value, forKey: item.key, .top, hash)
      assert(r == nil)
    }
    return result
  }
}
