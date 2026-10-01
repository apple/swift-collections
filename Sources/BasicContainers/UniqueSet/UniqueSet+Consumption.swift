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

#if compiler(>=6.4) && UnstableHashedContainers && UnstableContainersPreview

#if !COLLECTIONS_SINGLE_MODULE
import SpanPreview
#endif

@available(SwiftStdlib 5.0, *)
extension UniqueSet where Element: ~Copyable {
  @inlinable
  public mutating func consumeAll(
    consumingWith consumer: (inout InputSpan<Element>) -> Void
  ) {
    _storage.consumeAll(consumingWith: consumer)
  }
  
  @inlinable
  @unsafe
  public mutating func _consumeAll(
    consumingWith consumer: (UnsafeMutableBufferPointer<Element>) -> Void
  ) {
    unsafe _storage._consumeAll(consumingWith: consumer)
  }

}

#endif
