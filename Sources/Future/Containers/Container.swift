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

@available(SwiftCompatibilitySpan 5.0, *)
public protocol Container<Element>: ~Copyable, ~Escapable {
  associatedtype Element: ~Copyable/* & ~Escapable*/
  associatedtype Index: Comparable

  var isEmpty: Bool { get }
  var count: Int { get }

  var startIndex: Index { get }
  var endIndex: Index { get }

  func index(after index: Index) -> Index
  func formIndex(after i: inout Index)
  func distance(from start: Index, to end: Index) -> Int
  func index(_ index: Index, offsetBy n: Int) -> Index
  func formIndex(
    _ i: inout Index,
    offsetBy distance: inout Int,
    limitedBy limit: Index
  )

  #if compiler(>=9999) // FIXME: We can't do this yet
  subscript(index: Index) -> Element { borrow }
  #else
  @lifetime(copy self)
  func borrowElement(at index: Index) -> Borrow<Element>
  #endif

  @lifetime(copy self)
  func nextSpan(after index: inout Index, maximumCount: Int) -> Span<Element>
}

@available(SwiftCompatibilitySpan 5.0, *)
extension Container where Self: ~Copyable & ~Escapable {
  @inlinable
  public subscript(index: Index) -> Element {
    @lifetime(copy self)
    unsafeAddress {
      unsafe borrowElement(at: index)._pointer
    }
  }
}

