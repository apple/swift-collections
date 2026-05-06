//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Collections open source project
//
// Copyright (c) 2024 - 2026 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
//
// SPDX-License-Identifier: Apache-2.0 WITH Swift-exception
//
//===----------------------------------------------------------------------===//

#if !COLLECTIONS_SINGLE_MODULE
import InternalCollectionsUtilities
#endif

#if compiler(>=6.4) && UnstableContainersPreview

@available(SwiftStdlib 5.0, *)
extension BorrowingIteratorProtocol_
where
  Self: ~Copyable & ~Escapable,
  Element_: ~Copyable
{
  @inlinable
  internal consuming func _spanwiseZip<
    Other: BorrowingIteratorProtocol_ & ~Copyable & ~Escapable,
    State: ~Copyable, E: Error
  >(
    state: inout State,
    with other: consuming Other,
    by process: (inout State, Span<Element_>, Span<Other.Element_>) throws(E) -> Bool
  ) throws(E)
  where Other.Element_: ~Copyable
  {
#if true // FIXME: rdar://150228920 Exclusive access scopes aren't expanded enough
    // Note: This is the less efficient implementation of spanwiseZip. The
    // variant in the #else branch would be preferable, but it doesn't work yet.
    // (It lets the two iterators run at their native speeds, with no artificial
    // maximumCounts.)
  loop:
    while true {
      var a = self.nextSpan_()
      if a.isEmpty {
        while true {
          let b = other.nextSpan_()
          guard !b.isEmpty else { break }
          guard try process(&state, a, b) else { break }
        }
        return
      }
      repeat {
        let b = other.nextSpan_(maximumCount: a.count)
        if b.isEmpty {
          guard try process(&state, a, b) else { return }
        } else {
          guard try process(&state, a._trim(first: b.count), b) else {
            return
          }
        }
      } while !a.isEmpty
    }
#else
    var a = Span<Element>()
    var b = Span<Other.Element>()
    var offset = 0 // Offset of the start of the current spans
  loop:
    while true {
      if a.isEmpty {
        a = self.nextSpan()
      }
      if b.isEmpty {
        b = other.nextSpan()
      }
      if a.isEmpty || b.isEmpty {
        return offset
      }

      let c = Swift.min(a.count, b.count)
      guard try process(&state, a._trim(first: c), b._trim(first: c)) else {
        return offset
      }
      offset += c
    }
#endif
  }
}

#endif
