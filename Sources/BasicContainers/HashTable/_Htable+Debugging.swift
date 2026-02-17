//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Collections open source project
//
// Copyright (c) 2026 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
//
//===----------------------------------------------------------------------===//

#if !COLLECTIONS_SINGLE_MODULE
import InternalCollectionsUtilities
#endif

#if compiler(>=6.2)
extension _HTable {
  package var description: String {
    let multiline = self.endBucket.offset > Word.capacity

    var buckets = ""
    if !self.isSmall {
      let lastWord = self.endBucket.bit > 0 ? self.endBucket.word : self.endBucket.word - 1
      var it = self.makeBucketIterator()
      while !it.isAtEnd {
        if it.currentBucket.isOnWordBoundary {
          if multiline {
            buckets += "\n  "
            buckets += it.currentBucket.word == lastWord ? "└╴" : "├╴"
            buckets += "[" + String(it.currentBucket.offset).lpad(8, with: "0") + "] "
          } else {
            buckets += " "
          }
        } else if it.currentBucket.bit % 8 == 0 {
          buckets += "∙"
        }
        buckets.append(it.isOccupied ? "■" : "□")
        it.advanceToNextBit()
      }
    }

    var s = "⌗ \(scale == 0 ? "small" : "large@\(scale)")"
    s += "\(multiline ? "" : buckets) "
    s += "\(count)/\(capacity), "
    s += "totalProbeLength: \(_totalProbeLength)"

    if !self.isSmall, multiline {
      s += buckets
    }
    return s
  }
}
#endif
