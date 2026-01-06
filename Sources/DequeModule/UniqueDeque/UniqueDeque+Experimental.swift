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

@_alwaysEmitIntoClient
@_transparent
@_lifetime(borrow self)
public func borrowElement(at index: Int) -> Ref<Element> {
  _storage.borrowElement(at: index)
}

@_alwaysEmitIntoClient
@_transparent
@_lifetime(&self)
public mutating func mutateElement(at index: Int) -> Mut<Element> {
  _storage.mutateElement(at: index)
}

#endif
#endif
