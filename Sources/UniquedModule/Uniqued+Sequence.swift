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

extension Uniqued: Sequence {
  public typealias Element = Base.Element
  public typealias Iterator = Base.Iterator

  public func makeIterator() -> Iterator {
    _elements.makeIterator()
  }

  public func _customContainsEquatableElement(_ element: Element) -> Bool? {
    _find(element).index != nil
  }

  public __consuming func _copyToContiguousArray() -> ContiguousArray<Element> {
    _elements._copyToContiguousArray()
  }

  public __consuming func _copyContents(
    initializing ptr: UnsafeMutableBufferPointer<Element>
  ) -> (Iterator, UnsafeMutableBufferPointer<Element>.Index) {
    _elements._copyContents(initializing: ptr)
  }

  public func withContiguousStorageIfAvailable<R>(
    _ body: (UnsafeBufferPointer<Element>) throws -> R
  ) rethrows -> R? {
    try _elements.withContiguousStorageIfAvailable(body)
  }
}
