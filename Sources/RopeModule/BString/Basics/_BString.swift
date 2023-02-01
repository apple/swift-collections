//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Collections open source project
//
// Copyright (c) 2023 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
//
//===----------------------------------------------------------------------===//

/// The core of a B-tree based String implementation.
internal struct _BString: Sendable {
  typealias Rope = _Rope<Chunk>
  
  var rope: Rope
  
  internal init() {
    rope = Rope()
  }
  
  internal init(rope: Rope) {
    self.rope = rope
  }
}
