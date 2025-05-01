//===---------------------------------------------------------------------===//
//
// This source file is part of the Swift.org open source project
//
// Copyright (c) 2024 - 2025 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
// See https://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//
//===----------------------------------------------------------------------===//

@available(SwiftStdlib 6.2, *)
public protocol ContiguousContainer<Element>
  : RandomAccessContainer, ~Copyable, ~Escapable
{
  var span: Span<Element> { @lifetime(borrow self) get }
}

@available(SwiftStdlib 6.2, *)
extension ContiguousContainer
where Self: ~Copyable & ~Escapable, Index == Int {
  @inlinable
  @lifetime(borrow self)
  public func borrowElement(at index: Index) -> Borrow<Element> {
    span.borrowElement(at: index - startIndex)
  }

  @inlinable
  @lifetime(borrow self)
  public func nextSpan(after index: inout Index) -> Span<Element> {
    var i = index - startIndex
    let result = span.nextSpan(after: &i)
    index = i + startIndex
    return result
  }

  @inlinable
  @lifetime(borrow self)
  public func previousSpan(before index: inout Index) -> Span<Element> {
    var i = index - startIndex
    let result = span.previousSpan(before: &i)
    index = i + startIndex
    return result
  }
}

@available(SwiftStdlib 6.2, *)
extension Array: ContiguousContainer {}

@available(SwiftStdlib 6.2, *)
extension ContiguousArray: ContiguousContainer {}

@available(SwiftStdlib 6.2, *)
extension CollectionOfOne: ContiguousContainer {}
