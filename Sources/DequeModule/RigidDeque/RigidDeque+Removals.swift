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
  @discardableResult
  @_alwaysEmitIntoClient
  @_transparent
  public mutating func remove(at index: Int) -> Element {
    precondition(index >= 0 && index < count,
                 "Can't remove element at invalid index")
    return _handle.uncheckedRemove(at: index)
  }

  @_alwaysEmitIntoClient
  @_transparent
  public mutating func removeSubrange(_ bounds: Range<Int>) {
    precondition(bounds.lowerBound >= 0 && bounds.upperBound <= count,
                 "Index range out of bounds")
    _handle.uncheckedRemove(offsets: bounds)
  }

  @discardableResult
  @_alwaysEmitIntoClient
  @_transparent
  public mutating func removeFirst() -> Element {
    precondition(!isEmpty, "Cannot remove first element of an empty RigidDeque")
    return _handle.uncheckedRemoveFirst()
  }

  @discardableResult
  @_alwaysEmitIntoClient
  @_transparent
  public mutating func removeLast() -> Element {
    precondition(!isEmpty, "Cannot remove last element of an empty RigidDeque")
    return _handle.uncheckedRemoveLast()
  }

  @_alwaysEmitIntoClient
  @_transparent
  public mutating func removeFirst(_ n: Int) {
    precondition(n >= 0, "Can't remove a negative number of elements")
    precondition(n <= count, "Can't remove more elements than there are in a RigidDeque")
    _handle.uncheckedRemoveFirst(n)
  }

  @_alwaysEmitIntoClient
  @_transparent
  public mutating func removeLast(_ n: Int) {
    precondition(n >= 0, "Can't remove a negative number of elements")
    precondition(n <= count, "Can't remove more elements than there are in a RigidDeque")
    _handle.uncheckedRemoveLast(n)
  }

  @_alwaysEmitIntoClient
  @_transparent
  public mutating func removeAll() {
    _handle.uncheckedRemoveAll()
  }

  @_alwaysEmitIntoClient
  @_transparent
  public mutating func popFirst() -> Element? {
    guard !isEmpty else { return nil }
    return _handle.uncheckedRemoveFirst()
  }

  @_alwaysEmitIntoClient
  @_transparent
  public mutating func popLast() -> Element? {
    guard !isEmpty else { return nil }
    return _handle.uncheckedRemoveLast()
  }
}

#endif
