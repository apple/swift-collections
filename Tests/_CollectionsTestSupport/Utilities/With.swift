//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Collections open source project
//
// Copyright (c) 2021 - 2026 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
//
// SPDX-License-Identifier: Apache-2.0 WITH Swift-exception
//
//===----------------------------------------------------------------------===//

#if compiler(>=6.4)
// FIXME: Properties with borrow accessors cannot initialize locals.
//
//   let keys = d.keys // error: `d.keys` is borrowed and cannot be consumed
//
// We'll probably need language support for `borrow` (rather than
// `let`) bindings. Meanwhile, work around this by defining a silly
// `_with(foo) { foo in ... }` that sort of emulates borrow bindings
// in the most unhelpful way...
//
//   _with(d.keys) { keys in
//     // OK
//   }
@inlinable
package func _with<
  T: ~Copyable & ~Escapable,
  E: Error,
  R: ~Copyable
>(
  _ value: borrowing T,
  do body: (borrowing T) throws(E) -> R
) throws(E) -> R {
  try body(value)
}
#endif
