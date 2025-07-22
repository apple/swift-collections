//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Collections open source project
//
// Copyright (c) 2023 - 2024 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
//
//===----------------------------------------------------------------------===//

#if compiler(>=6.2)

@available(SwiftStdlib 6.2, *)
internal protocol _StringMetric: RopeMetric where Element == BigString._Chunk {
  /// Measure the distance between the given start and end positions within
  /// the specified chunk.
  ///
  /// `start` must be less than or equal to the `end` position. The measurement
  /// is done by (logically) first rounding both indices down to the nearest
  /// metric boundary.
  ///
  /// In the character metric, an element may start and end in different chunks,
  /// which considerably complicates distance measurement. To allow measuring
  /// distances without looking at data in more than one chunk, both indices
  /// are expected to address a known character boundary.
  func distance(
    from start: BigString._Chunk.Index,
    to end: BigString._Chunk.Index,
    in chunk: BigString._Chunk
  ) -> Int

  /// Measure the distance between the start of this chunk and the given end
  /// position.
  ///
  /// The end position is (logically) rounded down to the nearest metric
  /// boundary before starting the measurement.
  ///
  /// In the character metric, an element may start and end in different chunks,
  /// which considerably complicates distance measurement. To allow measuring
  /// distances without looking at data in more than one chunk, the given end
  /// index is expected to address a known character boundary.
  func prefixSize(
    to end: BigString._Chunk.Index,
    in chunk: BigString._Chunk
  ) -> Int

  func formIndex(
    _ i: inout BigString._Chunk.Index,
    offsetBy distance: inout Int,
    in chunk: BigString._Chunk
  ) -> (found: Bool, forward: Bool)
}

@available(SwiftStdlib 6.2, *)
extension BigString {
  internal struct _CharacterMetric: _StringMetric {
    typealias Element = _Chunk
    typealias Summary = BigString.Summary

    @inline(__always)
    func size(of summary: Summary) -> Int {
      summary.characters
    }

    func distance(
      from start: _Chunk.Index,
      to end: _Chunk.Index,
      in chunk: _Chunk
    ) -> Int {
      assert(start <= end)
      return chunk.characterDistance(from: start, to: end)
    }

    func prefixSize(to end: _Chunk.Index, in chunk: _Chunk) -> Int {
      // The prefix must not count the initial partial character that
      // ends in the chunk (any scalar before the first break) -- that character
      // logically belongs to (and counted in) a prior chunk: the one that
      // contains its leading scalar.
      //
      // To measure the prefix, we must therefore start counting from the
      // `firstBreak` position. We can guarantee that `firstBreak` is on a
      // character break: either the chunk has known breaks in it (in which case
      // `firstBreak` is obviously one of them), or the chunk has no known
      // breaks, but we know that `end` is on one. So in that case, `end` must
      // be on the end of the chunk, and `firstBreak` points to the same.
      assert(chunk.hasBreaks || chunk.firstBreak == end)
      return chunk.characterDistance(from: chunk.firstBreak, to: end)
    }

    @inline(__always)
    func formIndex(
      _ i: inout _Chunk.Index,
      offsetBy distance: inout Int,
      in chunk: _Chunk
    ) -> (found: Bool, forward: Bool) {
      chunk.formCharacterIndex(&i, offsetBy: &distance)
    }

    func index(at offset: Int, in chunk: _Chunk) -> _Chunk.Index {
      precondition(offset < chunk.characterCount)
      return chunk.characterIndex(chunk.firstBreak, offsetBy: offset)
    }
  }

  internal struct _UnicodeScalarMetric: _StringMetric {
    @inline(__always)
    func size(of summary: Summary) -> Int {
      summary.unicodeScalars
    }

    func distance(
      from start: _Chunk.Index,
      to end: _Chunk.Index,
      in chunk: _Chunk
    ) -> Int {
      assert(start <= end)

      // Make use of the chunk's known scalar count to reduce the amount of data we need to look at.
      if end._utf8Offset - start._utf8Offset < chunk.utf8Count / 2 {
        return chunk.scalarDistance(from: start, to: end)
      }
      var result: Int
      result = chunk.unicodeScalarCount
      result -= chunk.scalarDistance(from: chunk.startIndex, to: start)
      result -= chunk.scalarDistance(from: end, to: chunk.endIndex)
      return result
    }

    func prefixSize(to end: _Chunk.Index, in chunk: _Chunk) -> Int {
      // Make use of the chunk's known scalar count to reduce the amount of data we need to look at.
      if end.utf8Offset < chunk.utf8Count / 2 {
        return chunk.scalarDistance(from: chunk.startIndex, to: end)
      }

      return chunk.unicodeScalarCount - chunk.scalarDistance(from: end, to: chunk.endIndex)
    }

    func formIndex(
      _ i: inout _Chunk.Index,
      offsetBy distance: inout Int,
      in chunk: _Chunk
    ) -> (found: Bool, forward: Bool) {
      // FIXME: Make use of the chunk's known scalar count to reduce work
      guard distance != 0 else {
        i = chunk.scalarIndex(roundingDown: i)
        return (true, false)
      }
      if distance > 0 {
        let end = chunk.endIndex
        while distance > 0, i < end {
          i = chunk.scalarIndex(after: i)
          distance &-= 1
        }
        return (distance == 0, true)
      }
      let start = chunk.startIndex
      while distance < 0, i > start {
        i = chunk.scalarIndex(before: i)
        distance &+= 1
      }
      return (distance == 0, false)
    }

    func index(at offset: Int, in chunk: _Chunk) -> _Chunk.Index {
      chunk.scalarIndex(chunk.startIndex, offsetBy: offset)
    }
  }

  internal struct _UTF8Metric: _StringMetric {
    @inline(__always)
    func size(of summary: Summary) -> Int {
      summary.utf8
    }

    @inline(__always)
    func distance(
      from start: _Chunk.Index,
      to end: _Chunk.Index,
      in chunk: _Chunk
    ) -> Int {
      chunk.utf8Distance(from: start, to: end)
    }

    @inline(__always)
    func prefixSize(to end: _Chunk.Index, in chunk: _Chunk) -> Int {
      end.utf8Offset
    }

    func formIndex(
      _ i: inout _Chunk.Index,
      offsetBy distance: inout Int,
      in chunk: _Chunk
    ) -> (found: Bool, forward: Bool) {
      // Here we make use of the fact that the UTF-8 view of BigString._Chunk
      // has O(1) index distance & offset calculations.
      let offset = i.utf8Offset
      if distance >= 0 {
        let rest = chunk.utf8Count - offset
        if distance > rest {
          i = chunk.endIndex
          distance -= rest
          return (false, true)
        }
        i.utf8Offset += distance
        distance = 0
        return (true, true)
      }

      if offset + distance < 0 {
        i = chunk.startIndex
        distance += offset
        return (false, false)
      }
      i.utf8Offset += distance
      distance = 0
      return (true, false)
    }

    func index(at offset: Int, in chunk: _Chunk) -> _Chunk.Index {
      chunk.startIndex.offset(by: offset)
    }
  }

  internal struct _UTF16Metric: _StringMetric {
    @inline(__always)
    func size(of summary: Summary) -> Int {
      summary.utf16
    }

    func distance(
      from start: _Chunk.Index,
      to end: _Chunk.Index,
      in chunk: _Chunk
    ) -> Int {
      assert(start <= end)

      // Make use of the chunk's known UTF-16 count to reduce the amount of data we need to look at.
      if end._utf8Offset - start._utf8Offset < chunk.utf8Count / 2 {
        return chunk.utf16Distance(from: start, to: end)
      }
      var result = chunk.utf16Count
      result -= chunk.utf16Distance(from: chunk.startIndex, to: start)
      result -= chunk.utf16Distance(from: end, to: chunk.endIndex)
      return result
    }

    func prefixSize(to end: _Chunk.Index, in chunk: _Chunk) -> Int {
      // Make use of the chunk's known UTF-16 count to reduce the amount of data we need to look at.
      if end._utf8Offset < chunk.utf8Count / 2 {
        return chunk.utf16Distance(from: chunk.startIndex, to: end)
      }
      return chunk.utf16Count - chunk.utf16Distance(from: end, to: chunk.endIndex)
    }

    func formIndex(
      _ i: inout _Chunk.Index,
      offsetBy distance: inout Int,
      in chunk: _Chunk
    ) -> (found: Bool, forward: Bool) {
      // FIXME: Make use of the chunk's known UTF-16 count to reduce work
      if distance >= 0 {
        if
          distance <= chunk.utf16Count,
          let r = chunk.utf16Index(
            i, offsetBy: distance, limitedBy: chunk.endIndex
          ) {
          i = r
          distance = 0
          return (true, true)
        }
        distance -= chunk.utf16Distance(from: i, to: chunk.endIndex)
        i = chunk.endIndex
        return (false, true)
      }

      if
        distance.magnitude <= chunk.utf16Count,
        let r = chunk.utf16Index(
          i, offsetBy: distance, limitedBy: chunk.endIndex
        ) {
        i = r
        distance = 0
        return (true, true)
      }
      distance += chunk.utf16Distance(from: chunk.startIndex, to: i)
      i = chunk.startIndex
      return (false, false)
    }

    func index(at offset: Int, in chunk: _Chunk) -> _Chunk.Index {
      chunk.utf16Index(chunk.startIndex, offsetBy: offset)
    }
  }
}

#endif // compiler(>=6.2)
