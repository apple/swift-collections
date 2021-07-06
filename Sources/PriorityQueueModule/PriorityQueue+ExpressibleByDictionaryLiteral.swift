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

import Swift

extension PriorityQueue: ExpressibleByDictionaryLiteral {
  /// Creates a new priority queue from the contents of a dictionary literal.
  ///
  /// **Do not call this initializer directly.** It is used by the compiler when
  /// you use a dictionary literal. Instead, create a new queue using a
  /// dictionary literal as its value by enclosing a comma-separated list of
  /// values in square brackets. You can use a dictionary literal anywhere a
  /// priority queue is expected by the type context.
  ///
  /// - Parameter elements: A variadic list of element-priority pairs for the new
  ///                       queue.
  @inlinable
  public init(dictionaryLiteral elements: (Value, Priority)...) {
    self.init(elements)
  }
}
