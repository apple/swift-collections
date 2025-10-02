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

#if compiler(>=6.2) && !$Embedded

/// The core of a B-tree based String implementation.
@available(SwiftStdlib 6.2, *)
public struct BigString: Sendable {
  typealias _Rope = Rope<_Chunk>

  nonisolated(unsafe)
  var _rope: _Rope

  internal init(_rope: _Rope) {
    self._rope = _rope
  }
}

#endif // compiler(>=6.2) && !$Embedded
