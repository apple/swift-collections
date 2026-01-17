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
extension UniqueDeque where Element: ~Copyable {
  @_alwaysEmitIntoClient
  @_transparent
  public init() {
    _storage = .init(capacity: 0)
  }

  @_alwaysEmitIntoClient
  @_transparent
  public init(capacity: Int) {
    _storage = .init(capacity: capacity)
  }
}

@available(SwiftStdlib 5.0, *)
extension UniqueDeque /*where Element: Copyable*/ {
  /// Creates a new deque with the specified initial capacity, holding a copy
  /// of the contents of a given sequence.
  ///
  /// - Parameters:
  ///   - capacity: The storage capacity of the new deque, or nil to allocate
  ///      just enough capacity to store the contents.
  ///   - contents: The sequence whose contents to copy into the new deque.
  @_alwaysEmitIntoClient
  @inline(__always)
  public init(
    capacity: Int? = nil,
    copying contents: some Sequence<Element>
  ) {
    self.init(capacity: capacity ?? 0)
    self.append(copying: contents)
  }
}

#endif
