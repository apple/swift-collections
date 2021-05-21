//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Collections open source project
//
// Copyright (c) 2021 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
//
//===----------------------------------------------------------------------===//

extension _Node {
  @usableFromInline
  internal struct BufferHeader {
    @inlinable
    @inline(__always)
    internal init() {}
  }
  
  /// Represents a contiguous sequence of elements.
  /// - Warning: does not deallocate itself.
  @usableFromInline
  typealias Buffer<Element> = ManagedBuffer<BufferHeader, Element>
}
