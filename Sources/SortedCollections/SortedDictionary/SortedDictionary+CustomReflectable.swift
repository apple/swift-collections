//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Collections open source project
//
// Copyright (c) 2021 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
//
//===----------------------------------------------------------------------===//

extension SortedDictionary: CustomReflectable {
  // TODO: Review this implementation
  // TODO: Implement nice playground output.
  
  /// The custom mirror for this instance.
  public var customMirror: Mirror {
    // TODO: instead of Array(self), implement a Element view?
    Mirror(self, unlabeledChildren: Array(self), displayStyle: .dictionary)
  }
}
