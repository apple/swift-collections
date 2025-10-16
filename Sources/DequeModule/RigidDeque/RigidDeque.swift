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

#if compiler(<6.2)

@frozen
@available(*, unavailable, message: "RigidDeque requires a Swift 6.2 toolchain")
public struct RigidDeque<Element: ~Copyable>: ~Copyable {
  public init() {
    fatalError()
  }
}

#else

@available(SwiftStdlib 5.0, *)
@safe
@frozen
public struct RigidDeque<Element: ~Copyable>: ~Copyable {

}

@available(SwiftStdlib 5.0, *)
extension RigidDeque: @unchecked Sendable where Element: Sendable & ~Copyable {}

#endif // compiler(<6.2)
