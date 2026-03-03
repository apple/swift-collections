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
  package func maxOccupiedRun() -> Int {
    if isSmall { return self.count }
    var maxOccupiedRun = 0
    var it = self.makeBucketIterator()
    var first = true
    var wrap = 0
    while let next = it.nextOccupiedRegion() {
      if first, next.lowerBound.offset == 0 {
        wrap = next._offsets.count
      }
      first = false
      var c = next._offsets.count
      if next.upperBound == self.endBucket {
        c += wrap
      }
      maxOccupiedRun = max(maxOccupiedRun, c)
    }
    return maxOccupiedRun
  }

  package var _bitmapDescription: String {
    let multiline = self.endBucket.offset > Word.capacity
    var str = ""
    if !self.isSmall {
      let lastWord = self.endBucket.bit > 0 ? self.endBucket.word : self.endBucket.word - 1
      var it = self.makeBucketIterator()
      while !it.isAtEnd {
        if it.currentBucket.isOnWordBoundary {
          if multiline {
            str += "\n  "
            str += it.currentBucket.word == lastWord ? "└╴" : "├╴"
            str += "[" + String(it.currentBucket.offset)._lpad(8, with: "0") + "] "
          } else {
            str += " "
          }
        } else if it.currentBucket.bit % 8 == 0 {
          str += "∙"
        }
        str.append(it.isOccupied ? "■" : "□")
        it.advanceToNextBit()
      }
    }
    return str
  }
  
  package func describe(
    bitmap: Bool = false,
  ) -> String {
    let bitmapDesc = bitmap ? self._bitmapDescription : ""
    let multiline = bitmapDesc.unicodeScalars.contains("\n")
    var s = "⌗ \(scale == 0 ? "small" : "large@\(scale)")"
    s += "\(multiline ? "" : bitmapDesc) "
    s += "\(count)/\(capacity)/\(bucketCount), "
    s += "maxProbeLength: \(_maxProbeLength), "
    s += "maxOccupiedRun: \(maxOccupiedRun())"

    if !self.isSmall, multiline {
      s += bitmapDesc
    }
    return s
  }
  
  package var description: String {
    describe()
  }
}
#endif
