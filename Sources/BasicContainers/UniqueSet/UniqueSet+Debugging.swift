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
  public func _describe(
    bitmap: Bool = false,
    chains: Bool = false,
    buckets: Bool = false,
  ) -> String {
    _storage._describe(bitmap: bitmap, chains: chains, buckets: buckets)
  }

  public func _dump(
    bitmap: Bool = false,
    chains: Bool = false,
    buckets: Bool = false,
  ) {
    _storage._dump(bitmap: bitmap, chains: chains, buckets: buckets)
  }
}

#endif
