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
  @discardableResult
  @_alwaysEmitIntoClient
  @_transparent
  public mutating func remove(at index: Int) -> Element {
    _storage.remove(at: index)
  }

  @_alwaysEmitIntoClient
  @_transparent
  public mutating func removeSubrange(_ bounds: Range<Int>) {
    _storage.removeSubrange(bounds)
  }

  @discardableResult
  @_alwaysEmitIntoClient
  @_transparent
  public mutating func removeFirst() -> Element {
    _storage.removeFirst()
  }

  @discardableResult
  @_alwaysEmitIntoClient
  @_transparent
  public mutating func removeLast() -> Element {
    _storage.removeLast()
  }

  @_alwaysEmitIntoClient
  @_transparent
  public mutating func removeFirst(_ n: Int) {
    _storage.removeFirst(n)
  }

  @_alwaysEmitIntoClient
  @_transparent
  public mutating func removeLast(_ n: Int) {
    _storage.removeLast(n)
  }

  @_alwaysEmitIntoClient
  @_transparent
  public mutating func removeAll() {
    _storage.removeAll()
  }

  @_alwaysEmitIntoClient
  @_transparent
  public mutating func popFirst() -> Element? {
    _storage.popFirst()
  }

  @_alwaysEmitIntoClient
  @_transparent
  public mutating func popLast() -> Element? {
    _storage.popLast()
  }
}

#endif
