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

extension PersistentSet {
  @inlinable
  public init() {
    self.init(_new: ._emptyNode())
  }

  @inlinable
  public init<S: Sequence>(_ items: __owned S) where S.Element == Element {
    if S.self == Self.self {
      self = items as! Self
      return
    }
    self.init()
    for item in items {
      self._insert(item)
    }
  }

  @inlinable
  public init(_ items: __owned Self) {
    self = items
  }

  @inlinable
  public init<Value>(
    _ item: __owned PersistentDictionary<Element, Value>.Keys
  ) {
    self.init(_new: item._base._root.mapValues { _ in () })
  }
}
