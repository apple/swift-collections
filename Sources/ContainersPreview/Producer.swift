//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Collections open source project
//
// Copyright (c) 2024 - 2026 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
//
//===----------------------------------------------------------------------===//

#if compiler(>=6.2) && COLLECTIONS_UNSTABLE_CONTAINERS_PREVIEW

@available(SwiftStdlib 5.0, *)
public protocol Producer<Element>: ~Copyable, ~Escapable {
  associatedtype Element: ~Copyable /* ~Escapable */
  
  @_lifetime(target: copy target)
  mutating func generate(into target: inout OutputSpan<Element>)
}

#endif
