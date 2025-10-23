//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Collections open source project
//
// Copyright (c) 2025 Apple Inc. and the Swift project authors
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
extension RigidDeque where Element: ~Copyable {
  @_alwaysEmitIntoClient
  @_transparent
  public init(capacity: Int) {
    self.init(_handle: .allocate(capacity: capacity))
  }
}

@available(SwiftStdlib 5.0, *)
extension RigidDeque /*where Element: Copyable*/ {
  /// Creates a new deque containing the specified number of a single,
  /// repeated value.
  ///
  /// - Parameters:
  ///   - repeatedValue: The element to repeat.
  ///   - count: The number of times to repeat the value passed in the
  ///     `repeating` parameter. `count` must be zero or greater.
  ///
  /// - Complexity: O(`count`)
  public init(repeating repeatedValue: Element, count: Int) {
    self.init(capacity: count)
    _handle.mutableBuffer.initialize(repeating: repeatedValue)
    _handle.count = count
  }

  /// Creates a new deque with the specified capacity, holding a copy
  /// of the contents of a given sequence.
  ///
  /// - Parameters:
  ///   - capacity: The storage capacity of the new deque.
  ///   - contents: The sequence whose contents to copy into the new deque.
  ///      The sequence must not contain more than `capacity` elements.
  @_alwaysEmitIntoClient
  @inline(__always)
  public init(
    capacity: Int,
    copying contents: some Sequence<Element>
  ) {
    self.init(capacity: capacity)
    self.append(copying: contents)
  }
}

#endif
