//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Collections open source project
//
// Copyright (c) 2023 - 2024 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
//
//===----------------------------------------------------------------------===//

#if swift(>=5.8)

/// The core of a B-tree based String implementation.
@available(macOS 13.3, iOS 16.4, watchOS 9.4, tvOS 16.4, *)
public struct BigString: Sendable {
  typealias _Rope = Rope<_Chunk>

  var _rope: _Rope
  
  internal init(_rope: _Rope) {
    self._rope = _rope
  }
}

#else

// `BigString` depends on fixes and newly exposed functionality that landed in
// version 5.8 of the Swift Standard Library.
@available(*, unavailable, message: "BigString depends on version 5.8 of the Swift Standard Library")
public struct BigString: Sendable {}

#endif
