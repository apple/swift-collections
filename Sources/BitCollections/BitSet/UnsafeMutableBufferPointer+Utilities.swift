//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Collections open source project
//
// Copyright (c) 2021-2022 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
//
//===----------------------------------------------------------------------===//

extension Collection {
  @inlinable
  @inline(__always)
  internal func _rebased<Element>() -> UnsafeBufferPointer<Element>
  where Self == UnsafeBufferPointer<Element>.SubSequence {
    .init(rebasing: self)
  }
}

extension Collection {
  @inlinable
  @inline(__always)
  internal func _rebased<Element>() -> UnsafeMutableBufferPointer<Element>
  where Self == UnsafeMutableBufferPointer<Element>.SubSequence {
    .init(rebasing: self)
  }
}

extension UnsafeMutableBufferPointer {
  @inlinable
  @inline(__always)
  internal func _assign(from source: Self) {
    assert(source.count == self.count)
    if count > 0 {
      baseAddress!.assign(from: source.baseAddress!, count: count)
    }
  }

  @inlinable
  @inline(__always)
  internal func _initialize(at index: Int, to value: Element) {
    (baseAddress.unsafelyUnwrapped + index).initialize(to: value)
  }
}
