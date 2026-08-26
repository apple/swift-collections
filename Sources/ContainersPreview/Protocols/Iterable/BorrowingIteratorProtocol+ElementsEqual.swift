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

@available(SwiftStdlib 6.4, *)
extension BorrowingIteratorProtocol
where
  Self: ~Copyable & ~Escapable,
  Element: ~Copyable & Equatable
{
  @_alwaysEmitIntoClient
  public consuming func elementsEqual<
    Other: BorrowingIteratorProtocol<Element, Failure> & ~Copyable & ~Escapable
  >(
    _ other: consuming Other,
  ) throws(Failure) -> Bool
    where Other.Element: ~Copyable
  {
    try self._elementsEqual(other)
  }
}

@available(SwiftStdlib 6.4, *)
extension BorrowingIteratorProtocol
where
  Self: ~Copyable & ~Escapable,
  Element: ~Copyable
{
  @_alwaysEmitIntoClient
  public consuming func elementsEqual<
    Other: BorrowingIteratorProtocol & ~Copyable & ~Escapable
  >(
    _ other: consuming Other,
    by areEquivalent: (borrowing Element, borrowing Other.Element) throws(Failure) -> Bool
  ) throws(Failure) -> Bool
  where Other.Element: ~Copyable, Other.Failure == Failure
  {
    try self._elementsEqual(other, by: areEquivalent)
  }
}

#endif
