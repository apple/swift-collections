//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Collections open source project
//
// Copyright (c) 2022 - 2026 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
//
// SPDX-License-Identifier: Apache-2.0 WITH Swift-exception
//
//===----------------------------------------------------------------------===//

import SwiftShims

/// Immortalize the given instance, ensuring that it never deinitializes, and
/// rendering its refcount operations noops.
///
/// This intentionally leaks memory, but it avoids a costly compare/exchange
/// loop on retains/releases.
@inlinable
@_alwaysEmitIntoClient
package func _immortalize<T: AnyObject>(_ object: consuming T) -> T {
  unsafe _swift_stdlib_immortalize(Unmanaged.passUnretained(object).toOpaque())
  return object
}
