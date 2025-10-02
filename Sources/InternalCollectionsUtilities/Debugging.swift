//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Collections open source project
//
// Copyright (c) 2022 - 2025 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
//
//===----------------------------------------------------------------------===//

/// True if consistency checking is enabled in the implementation of the
/// Swift Collections package, false otherwise.
///
/// Documented performance promises are null and void when this property
/// returns true -- for example, operations that are documented to take
/// O(1) time might take O(*n*) time, or worse.
@inlinable @inline(__always)
package var _isCollectionsInternalCheckingEnabled: Bool {
#if COLLECTIONS_INTERNAL_CHECKS
  return true
#else
  return false
#endif
}
