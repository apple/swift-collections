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

#if COLLECTIONS_SINGLE_MODULE
import Collections
#else
import InternalCollectionsUtilities
import ContainersPreview
#endif

#if compiler(>=6.4) && UnstableContainersPreview

/// A wrapper over an arbitrary producer that _only_ conforms to the base
/// `Producer` protocol, without any of its refinements, and without any
/// extensions that may be present on the original type.
///
/// All requirements are implemented by directly forwarding to the base
/// producer.
@available(SwiftStdlib 5.0, *)
package struct PureProducer<Wrapped: Producer & ~Copyable & ~Escapable>
: ~Copyable, ~Escapable
where
  Wrapped.Element: ~Copyable
{
  package var _base: Wrapped

  @_lifetime(copy base)
  package init(_ base: consuming Wrapped) {
    self._base = base
  }
}

#if false
// FIXME: This is rejected:
// > error: Conditional conformance to 'Copyable' must explicitly state whether
// >        'Wrapped.Element' is required to conform to 'Escapable' or not
// etc.
extension PureProducer: Copyable
where
  Wrapped: Copyable & ~Escapable,
  Wrapped.Element: ~Copyable & Escapable,
  Wrapped.Failure: Copyable & Escapable {}

extension PureProducer: Escapable
where
  Wrapped: ~Copyable & Escapable,
  Wrapped.Element: ~Copyable & Escapable,
  Wrapped.Failure: Copyable & Escapable {}
#endif

extension PureProducer: Producer
where Wrapped: ~Copyable & ~Escapable, Wrapped.Element: ~Copyable {
  package typealias Element = Wrapped.Element
  package typealias Failure = Wrapped.Failure

  package var underestimatedCount: Int { _base.underestimatedCount }

  @discardableResult
  @_lifetime(target: copy target)
  package mutating func generate(
    into target: inout OutputSpan<Element>
  ) throws(Failure) -> Int {
    try _base.generate(into: &target)
  }

  package mutating func skip(by n: inout Int) throws(Failure) {
    try _base.skip(by: &n)
  }

  package mutating func next() throws(Failure) -> Element? {
    try _base.next()
  }
}


#endif
