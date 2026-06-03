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

#if compiler(>=6.4) && UnstableContainersPreview

/// A producer with an exact count.
@available(SwiftStdlib 5.0, *)
public protocol CountedProducer<Element, Failure>: ~Copyable, ~Escapable, Producer
where Element: ~Copyable
{
  var count: Int { get }
}

@available(SwiftStdlib 5.0, *)
extension CountedProducer where Self: ~Copyable & ~Escapable, Element: ~Copyable {
  @_alwaysEmitIntoClient
  @inline(__always)
  public var underestimatedCount: Int {
    count
  }
}
#endif
