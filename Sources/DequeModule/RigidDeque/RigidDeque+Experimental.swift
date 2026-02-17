//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Collections open source project
//
// Copyright (c) 2026 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
//
//===----------------------------------------------------------------------===//

#if !COLLECTIONS_SINGLE_MODULE
import InternalCollectionsUtilities
import ContainersPreview
#endif

#if compiler(>=6.2) && COLLECTIONS_UNSTABLE_CONTAINERS_PREVIEW

#if false // FIXME
@available(SwiftStdlib 5.0, *)
extension RigidDeque where Element: ~Copyable {
  @_alwaysEmitIntoClient
  @_transparent
  @_lifetime(borrow self)
  public func borrowElement(at index: Int) -> Borrow<Element> {
    _checkItemIndex(index)
    let slot = _handle.slot(forOffset: index)
    return Borrow(unsafeAddress: _handle.ptr(at: slot), borrowing: self)
  }
  
  @_alwaysEmitIntoClient
  @_transparent
  @_lifetime(&self)
  public mutating func mutateElement(at index: Int) -> Inout<Element> {
    _checkItemIndex(index)
    let slot = _handle.slot(forOffset: index)
    return Inout(unsafeAddress: _handle.mutablePtr(at: slot), mutating: &self)
  }
}
#endif

#endif
