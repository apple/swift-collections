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

#if compiler(>=6.3) && COLLECTIONS_UNSTABLE_NONCOPYABLE_KEYS

@available(SwiftStdlib 5.0, *)
extension UniqueSet where Element: ~Copyable {
  @inlinable
  public init() {
    self.init(_storage: .init())
  }
  
  @inlinable
  public init(minimumCapacity: Int) {
    self.init(
      _storage: .init(_table: _HTable(minimumCapacity: minimumCapacity)))
  }
  
  @inlinable
  public init(consuming set: consuming RigidSet<Element>) {
    self.init(_storage: set)
  }
}

#endif
