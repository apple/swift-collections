//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2023 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
//
//===----------------------------------------------------------------------===//
//
//  A helper struct to provide fixed-sized array like functionality
//
//===----------------------------------------------------------------------===//

typealias FixedArray4<T> = FixedArray<FixedStorage4<T>>
typealias FixedArray8<T> = FixedArray<FixedStorage8<T>>
typealias FixedArray16<T> = FixedArray<FixedStorage16<T>>
typealias FixedArray48<T> = FixedArray<FixedStorage48<T>>
typealias FixedArray256<T> = FixedArray<FixedStorage256<T>>

internal struct FixedArray<Storage: FixedStorage> {
  typealias Element = Storage.Element
  internal var storage: Storage
}

extension FixedArray {
  @inline(__always)
  init(repeating: Element) {
    self.storage = Storage(repeating: (repeating))
  }
}

extension FixedArray {
  internal static var capacity: Int {
    @inline(__always) get { return Storage.capacity }
  }

  internal var capacity: Int {
    @inline(__always) get { return Self.capacity }
  }
}
