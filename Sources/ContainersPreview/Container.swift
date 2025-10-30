//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Collections open source project
//
// Copyright (c) 2024 - 2025 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
//
//===----------------------------------------------------------------------===//

#if compiler(>=6.2) && COLLECTIONS_UNSTABLE_CONTAINERS_PREVIEW

#if false // Unfortunately this does not work well with Iterable yet.

@available(SwiftStdlib 5.0, *)
public struct ContainerIterator<
  Base: Container & ~Copyable /*& ~Escapable*/
>: ~Copyable, ~Escapable {
  let _base: Ref<Base>
  var _position: Base.Index
  
  @_lifetime(borrow base)
  init(_borrowing base: borrowing @_addressable Base, from position: Base.Index) {
    self._base = Ref(_borrowing: base)
    self._position = position
  }
}

@available(SwiftStdlib 5.0, *)
extension ContainerIterator: BorrowIteratorProtocol where Base: ~Copyable {
  public typealias Element = Base.Element

  @_lifetime(&self)
  public mutating func nextSpan(maximumCount: Int) -> Span<Base.Element> {
    let r = _base[].nextSpan(after: &self._position, maximumCount: maximumCount)
    return r
  }
}

@available(SwiftStdlib 5.0, *)
public protocol Container<Element>: Iterable, ~Copyable, ~Escapable {
  associatedtype Index
  
  var count: Int { get }
  
  var startIndex: Index { get }
  var endIndex: Index { get }
  func index(after index: Index) -> Index
  func index(_ index: Index, offsetBy delta: Int) -> Index
  // ...
  
//  subscript(index: Index) -> Element { borrow }
  
  @_lifetime(borrow self)
  func nextSpan(after index: inout Index, maximumCount: Int) -> Span<Element>
}

@available(SwiftStdlib 5.0, *)
extension Container where Self: ~Copyable & ~Escapable {
  @_transparent
  public var estimatedCount: EstimatedCount { .exactly(count) }
}

@available(SwiftStdlib 5.0, *)
extension Container
where
  Self: ~Copyable /*& ~Escapable*/,
  BorrowIterator == ContainerIterator<Self>
{
  @_lifetime(borrow self)
  public func startBorrowIteration() -> BorrowIterator {
    ContainerIterator(_borrowing: self, from: self.startIndex)
  }
}

#endif

#endif
