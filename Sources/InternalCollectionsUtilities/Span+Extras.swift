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

#if compiler(>=6.2)

@available(SwiftStdlib 5.0, *)
extension Span where Element: ~Copyable {
  @_lifetime(copy self)
  @_alwaysEmitIntoClient
  package mutating func _trim(first maxLength: Int) -> Self {
    precondition(maxLength >= 0, "Cannot have a prefix of negative length")
    let cut = Swift.min(maxLength, count)
    guard cut > 0 else { return .init() }
    let result = self.extracting(first: cut)
    self = self.extracting(droppingFirst: cut)
    return result
  }

  @_lifetime(copy self)
  @_alwaysEmitIntoClient
  package mutating func _trim(last maxLength: Int) -> Self {
    precondition(maxLength >= 0, "Cannot have a suffix of negative length")
    let cut = Swift.min(maxLength, count)
    guard cut > 0 else { return .init() }
    let result = self.extracting(last: cut)
    self = self.extracting(droppingLast: cut)
    return result
  }
}

@available(SwiftStdlib 5.0, *)
extension Span where Element: Equatable /* & ~Copyable */ {
  @_alwaysEmitIntoClient
  package func _elementsEqual(to other: borrowing Self) -> Bool {
    return self.withUnsafeBufferPointer { a in
      other.withUnsafeBufferPointer { b in
        guard a.count == b.count else { return false }
        guard a.baseAddress != b.baseAddress else { return true }
        var i = 0
        while i < self.count {
          guard a[i] == b[i] else { return false }
          i &+= 1
        }
        return true
      }
    }
  }
}

@available(SwiftStdlib 5.0, *)
extension Span where Element: Hashable /* & ~Copyable */ {
  @_alwaysEmitIntoClient
  package func _hashContents(into hasher: inout Hasher) {
    // Note: no discriminating combine call -- caller is expected to do that
    // separately when needed.
    var i = 0
    while i < self.count {
      hasher.combine(self[unchecked: i])
      i &+= 1
    }

  }
}

#endif
