//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Collections open source project
//
// Copyright (c) 2025 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
//
//===----------------------------------------------------------------------===//

/// Describes a type that has some number of elements following it directly
/// in memory. Such types are generally used with the `TrailingArray`
/// type, which manages storage for the header and its trailing elements.
public protocol TrailingElements: ~Copyable {
  /// The element type of the data that follows the header in memory.
  associatedtype Element
  
  /// The number of elements following the header.
  var trailingCount: Int { get }
}
