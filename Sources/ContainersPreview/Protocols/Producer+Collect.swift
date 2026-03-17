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

#if compiler(>=6.2) && COLLECTIONS_UNSTABLE_CONTAINERS_PREVIEW

@available(SwiftStdlib 5.0, *)
extension Producer where Self: ~Copyable & ~Escapable {
  @inlinable
  public consuming func collect<
    R: DynamicContainer<Element> & ~Copyable
  >(
    into container: R.Type = R.self
  ) throws(ProducerError) -> R {
    try R(from: self)
  }

  @inlinable
  public consuming func collect(
    into container: inout some DynamicContainer<Element> & ~Copyable
  ) throws(ProducerError) {
    try container.append(from: self)
  }
}

#endif
