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

extension _BString {
  internal func hashCharacters(into hasher: inout Hasher) {
    // FIXME: Implement properly normalized comparisons & hashing.
    // This is somewhat tricky as we shouldn't just normalize individual pieces of the string
    // split up on random Character boundaries -- Unicode does not promise that
    // norm(a + c) == norm(a) + norm(b) in this case.
    // To do this properly, we'll probably need to expose new stdlib entry points. :-/
    var it = self.makeCharacterIterator()
    while let character = it.next() {
      let s = String(character)
      s._withNFCCodeUnits { hasher.combine($0) }
    }
    hasher.combine(0xFF as UInt8)
  }

  /// Feed the UTF-8 encoding of `self` into hasher, with a terminating byte.
  internal func hashUTF8(into hasher: inout Hasher) {
    for chunk in self.rope {
      var string = chunk.string
      string.withUTF8 {
        hasher.combine(bytes: .init($0))
      }
      hasher.combine(0xFF as UInt8)
    }
  }
}
