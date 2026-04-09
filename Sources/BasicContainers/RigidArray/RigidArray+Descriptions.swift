//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Collections open source project
//
// Copyright (c) 2026 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
//
// SPDX-License-Identifier: Apache-2.0 WITH Swift-exception
//
//===----------------------------------------------------------------------===//

#if compiler(>=6.2)

// FIXME: Add this when/if SE-0499 gets implemented.
//#if compiler(>=6.x)
//@available(SwiftStdlib 5.0, *)
//extension RigidArray: CustomStringConvertible where Element: ~Copyable {
//}
//#endif

@available(SwiftStdlib 5.0, *)
extension RigidArray where Element: ~Copyable {
  public var description: String {
    /// FIXME: Print the item descriptions when available.
    "<\(count) items>"
  }
}

// FIXME: Add this when/if SE-0499 gets implemented.
//#if compiler(>=6.5)
//@available(SwiftStdlib 5.0, *)
//extension RigidArray: CustomDebugStringConvertible where Element: ~Copyable {
//}
//#endif

@available(SwiftStdlib 5.0, *)
extension RigidArray where Element: ~Copyable {
  public var debugDescription: String {
    /// FIXME: Print the item descriptions when available.
    "<\(count) items>"
  }
}


#endif
