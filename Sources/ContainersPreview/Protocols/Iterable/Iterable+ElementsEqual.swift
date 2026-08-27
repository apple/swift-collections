//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Collections open source project
//
// Copyright (c) 2026 Apple Inc. and the Swift project authors
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

@available(SwiftStdlib 6.4, *)
extension Iterable
  where Self: ~Copyable & ~Escapable, Element: ~Copyable
{
  @_alwaysEmitIntoClient
  public borrowing func elementsEqual<Other: Iterable>(
    _ other: borrowing Other,
    // FIXME: The predicate should be able to throw an arbitrary error type,
    // but we cannot throw an error union yet.
    by areEquivalent: (borrowing Element, borrowing Other.Element) throws(Failure) -> Bool
  ) throws(Failure) -> Bool
  where
    Other: ~Copyable & ~Escapable,
    Other.Element: ~Copyable,
    // FIXME: This should not require Other.Failure == Failure; but we cannot
    // throw an error union yet.
    Other.Failure == Failure
  {
    try _elementsEqual(other, by: areEquivalent)
  }
}

@available(SwiftStdlib 6.4, *)
extension Iterable
where Self: ~Copyable & ~Escapable, Element: ~Copyable & Equatable {
  @_alwaysEmitIntoClient
  public borrowing func elementsEqual<Other: Iterable>(
    _ other: borrowing Other
  ) throws(Failure) -> Bool
  where
    Other: ~Copyable & ~Escapable,
    Other.Element: ~Copyable,
    Other.Element == Element,
    // FIXME: This should not require Other.Failure == Failure; but we cannot
    // throw an error union yet.
    Other.Failure == Failure
  {
    try _elementsEqual(other)
  }
}

#endif
