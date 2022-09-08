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

struct DictionaryEffect<Value> {
  var modified: Bool = false
  var previousValue: Value?
  
  mutating func setModified() {
    self.modified = true
  }
  
  mutating func setModified(previousValue: Value) {
    self.modified = true
    self.previousValue = previousValue
  }
  
  mutating func setReplacedValue(previousValue: Value) {
    self.modified = true
    self.previousValue = previousValue
  }
}
