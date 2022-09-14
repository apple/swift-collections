//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Collections open source project
//
// Copyright (c) 2019 - 2022 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
//
//===----------------------------------------------------------------------===//

@usableFromInline
@frozen
struct _DictionaryEffect<Value> {
  @usableFromInline
  var modified: Bool = false

  @usableFromInline
  var previousValue: Value?

  @inlinable
  init() {}

  @inlinable
  mutating func setModified() {
    self.modified = true
  }
  
  @inlinable
  mutating func setModified(previousValue: Value) {
    self.modified = true
    self.previousValue = previousValue
  }
  
  @inlinable
  mutating func setReplacedValue(previousValue: Value) {
    self.modified = true
    self.previousValue = previousValue
  }
}
