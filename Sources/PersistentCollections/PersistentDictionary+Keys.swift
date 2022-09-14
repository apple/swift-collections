//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Collections open source project
//
// Copyright (c) 2022 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
//
//===----------------------------------------------------------------------===//

// TODO: implement a custom `Keys` view rather than relying on an array representation
extension PersistentDictionary {
  /// A view of a dictionary’s keys.
  public typealias Keys = [Key]
  
  /// A collection containing just the keys of the dictionary.
  @inlinable
  public var keys: Self.Keys /* { get } */ {
    self.map { $0.key }
  }
}
