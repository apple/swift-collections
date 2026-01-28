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
import ContainersPreview
#endif

#if compiler(>=6.2)

@available(SwiftStdlib 5.0, *)
extension UniqueDeque where Element: ~Copyable {
#if COLLECTIONS_UNSTABLE_CONTAINERS_PREVIEW
  @_alwaysEmitIntoClient
  @inline(__always)
  public mutating func consume(
    _ subrange: Range<Index>,
    consumingWith consumer: (inout InputSpan<Element>) -> Void
  ) {
    _storage.consume(subrange, consumingWith: consumer)
  }

  @_alwaysEmitIntoClient
  @inline(__always)
  public mutating func consume<R: RangeExpression<Index>>(
    _ subrange: R,
    consumingWith consumer: (inout InputSpan<Element>) -> Void
  ) {
    consume(subrange.relative(to: indices), consumingWith: consumer)
  }
  
  @_alwaysEmitIntoClient
  @inline(__always)
  public mutating func consumeAll(
    consumingWith consumer: (inout InputSpan<Element>) -> Void
  ) {
    consume(indices, consumingWith: consumer)
  }
#endif
}

#if COLLECTIONS_UNSTABLE_CONTAINERS_PREVIEW
@available(SwiftStdlib 5.0, *)
extension UniqueDeque where Element: ~Copyable {
  public typealias SubrangeConsumer = RigidDeque<Element>.SubrangeConsumer

  @_alwaysEmitIntoClient
  @inline(__always)
  @_lifetime(&self)
  public mutating func consume(
    _ subrange: Range<Index>
  ) -> SubrangeConsumer {
    _storage.consume(subrange)
  }
  
  @_alwaysEmitIntoClient
  @inline(__always)
  @_lifetime(&self)
  public mutating func consume<R: RangeExpression<Index>>(
    _ subrange: R
  ) -> SubrangeConsumer {
    consume(subrange.relative(to: indices))
  }
  
  @_alwaysEmitIntoClient
  @inline(__always)
  @_lifetime(&self)
  public mutating func consumeAll() -> SubrangeConsumer {
    consume(indices)
  }
}
#endif

#endif
