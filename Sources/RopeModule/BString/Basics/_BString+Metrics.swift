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

#if swift(>=5.8)

@available(macOS 13.3, iOS 16.4, watchOS 9.4, tvOS 16.4, *)
internal protocol _StringMetric: _RopeMetric where Element == _BString.Chunk {
  func distance(
    from start: String.Index,
    to end: String.Index,
    in chunk: _BString.Chunk
  ) -> Int
  
  func formIndex(
    _ i: inout String.Index,
    offsetBy distance: inout Int,
    in chunk: _BString.Chunk
  ) -> (found: Bool, forward: Bool)
}

@available(macOS 13.3, iOS 16.4, watchOS 9.4, tvOS 16.4, *)
extension _BString {
  internal struct CharacterMetric: _StringMetric {
    typealias Element = _BString.Chunk
    typealias Summary = _BString.Summary
    
    @inline(__always)
    func size(of summary: Summary) -> Int {
      summary.characters
    }
    
    func distance(
      from start: String.Index,
      to end: String.Index,
      in chunk: _BString.Chunk
    ) -> Int {
      chunk.characterDistance(from: start, to: end)
    }
    
    func formIndex(
      _ i: inout String.Index,
      offsetBy distance: inout Int,
      in chunk: _BString.Chunk
    ) -> (found: Bool, forward: Bool) {
      chunk.formCharacterIndex(&i, offsetBy: &distance)
    }
    
    func index(at offset: Int, in chunk: _BString.Chunk) -> String.Index {
      precondition(offset < chunk.characterCount)
      return chunk.wholeCharacters._index(at: offset)
    }
  }
  
  internal struct UnicodeScalarMetric: _StringMetric {
    @inline(__always)
    func size(of summary: Summary) -> Int {
      summary.unicodeScalars
    }
    
    func distance(
      from start: String.Index,
      to end: String.Index,
      in chunk: _BString.Chunk
    ) -> Int {
      chunk.string.unicodeScalars.distance(from: start, to: end)
    }
    
    func formIndex(
      _ i: inout String.Index,
      offsetBy distance: inout Int,
      in chunk: _BString.Chunk
    ) -> (found: Bool, forward: Bool) {
      guard distance != 0 else {
        i = chunk.string.unicodeScalars._index(roundingDown: i)
        return (true, false)
      }
      if distance > 0 {
        let end = chunk.string.endIndex
        while distance > 0, i < end {
          chunk.string.unicodeScalars.formIndex(after: &i)
          distance &-= 1
        }
        return (distance == 0, true)
      }
      let start = chunk.string.startIndex
      while distance < 0, i > start {
        chunk.string.unicodeScalars.formIndex(before: &i)
        distance &+= 1
      }
      return (distance == 0, false)
    }
    
    func index(at offset: Int, in chunk: _BString.Chunk) -> String.Index {
      chunk.string.unicodeScalars.index(chunk.string.startIndex, offsetBy: offset)
    }
  }
  
  internal struct UTF8Metric: _StringMetric {
    @inline(__always)
    func size(of summary: Summary) -> Int {
      summary.utf8
    }
    
    func distance(
      from start: String.Index,
      to end: String.Index,
      in chunk: _BString.Chunk
    ) -> Int {
      chunk.string.utf8.distance(from: start, to: end)
    }
    
    func formIndex(
      _ i: inout String.Index,
      offsetBy distance: inout Int,
      in chunk: _BString.Chunk
    ) -> (found: Bool, forward: Bool) {
      // Here we make use of the fact that the UTF-8 view of native Swift strings
      // have O(1) index distance & offset calculations.
      let offset = chunk.string.utf8.distance(from: chunk.string.startIndex, to: i)
      if distance >= 0 {
        let rest = chunk.utf8Count - offset
        if distance > rest {
          i = chunk.string.endIndex
          distance -= rest
          return (false, true)
        }
        i = chunk.string.utf8.index(i, offsetBy: distance)
        distance = 0
        return (true, true)
      }
      
      if offset + distance < 0 {
        i = chunk.string.startIndex
        distance += offset
        return (false, false)
      }
      i = chunk.string.utf8.index(i, offsetBy: distance)
      distance = 0
      return (true, false)
    }
    
    func index(at offset: Int, in chunk: _BString.Chunk) -> String.Index {
      chunk.string.utf8.index(chunk.string.startIndex, offsetBy: offset)
    }
  }
  
  internal struct UTF16Metric: _StringMetric {
    @inline(__always)
    func size(of summary: Summary) -> Int {
      summary.utf16
    }
    
    func distance(
      from start: String.Index,
      to end: String.Index,
      in chunk: _BString.Chunk
    ) -> Int {
      chunk.string.utf16.distance(from: start, to: end)
    }
    
    func formIndex(
      _ i: inout String.Index,
      offsetBy distance: inout Int,
      in chunk: _BString.Chunk
    ) -> (found: Bool, forward: Bool) {
      if distance >= 0 {
        if
          distance <= chunk.utf16Count,
          let r = chunk.string.utf16.index(
            i, offsetBy: distance, limitedBy: chunk.string.endIndex
          ) {
          i = r
          distance = 0
          return (true, true)
        }
        distance -= chunk.string.utf16.distance(from: i, to: chunk.string.endIndex)
        i = chunk.string.endIndex
        return (false, true)
      }
      
      if
        distance.magnitude <= chunk.utf16Count,
        let r = chunk.string.utf16.index(
          i, offsetBy: distance, limitedBy: chunk.string.endIndex
        ) {
        i = r
        distance = 0
        return (true, true)
      }
      distance += chunk.string.utf16.distance(from: chunk.string.startIndex, to: i)
      i = chunk.string.startIndex
      return (false, false)
    }
    
    func index(at offset: Int, in chunk: _BString.Chunk) -> String.Index {
      chunk.string.utf16.index(chunk.string.startIndex, offsetBy: offset)
    }
  }
}

#endif
