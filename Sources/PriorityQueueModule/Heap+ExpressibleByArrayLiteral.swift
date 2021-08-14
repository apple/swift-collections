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

extension Heap: ExpressibleByArrayLiteral {
  /// Creates a new heap from the contents of an array literal.
  ///
  /// **Do not call this initializer directly.** It is used by the compiler when
  /// you use an array literal. Instead, create a new heap using an array
  /// literal as its value by enclosing a comma-separated list of values in
  /// square brackets. You can use an array literal anywhere a heap is expected
  /// by the type context.
  ///
  /// - Parameter elements: A variadic list of elements of the new heap.
  public init(arrayLiteral elements: Element...) {
    self.init(elements)
  }
}
