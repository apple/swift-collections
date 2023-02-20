//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Collections open source project
//
// Copyright (c) 2023 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
//
//===----------------------------------------------------------------------===//

struct _RopeVersion {
  // FIXME: Replace this probabilistic mess with atomics when Swift gets its act together.
  var _value: UInt

  init() {
    var rng = SystemRandomNumberGenerator()
    _value = rng.next()
  }

  init(_ value: UInt) {
    self._value = value
  }
}

extension _RopeVersion: Equatable {
  static func ==(left: Self, right: Self) -> Bool {
    left._value == right._value
  }
}

extension _RopeVersion {
  mutating func bump() {
    _value &+= 1
  }

  mutating func reset() {
    var rng = SystemRandomNumberGenerator()
    _value = rng.next()
  }
}
