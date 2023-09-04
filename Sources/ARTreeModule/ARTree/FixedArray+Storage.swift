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

protocol FixedArrayStorage {
  associatedtype Element

  static var capacity: Int { get }
  init(repeating: Element)
}

struct FixedArrayStorage4<T>: FixedArrayStorage {
  internal var items: (T, T, T, T)

  @inline(__always)
  init(repeating v: T) {
    self.items = (v, v, v, v)
  }

  static var capacity: Int {
    @inline(__always) get { 4 }
  }
}

struct FixedArrayStorage8<T>: FixedArrayStorage {
  internal var items: (T, T, T, T, T, T, T, T)

  @inline(__always)
  init(repeating v: T) {
    self.items = (v, v, v, v, v, v, v, v)
  }

  static var capacity: Int {
    @inline(__always) get { 8 }
  }
}

struct FixedArrayStorage16<T>: FixedArrayStorage {
  internal var items:
    (
      T, T, T, T, T, T, T, T,
      T, T, T, T, T, T, T, T
    )

  @inline(__always)
  init(repeating v: T) {
    self.items = (
      v, v, v, v, v, v, v, v,
      v, v, v, v, v, v, v, v
    )
  }

  static var capacity: Int {
    @inline(__always) get { 16 }
  }
}

struct FixedArrayStorage48<T>: FixedArrayStorage {
  internal var items:
    (
      T, T, T, T, T, T, T, T, T, T, T, T, T, T, T, T,
      T, T, T, T, T, T, T, T, T, T, T, T, T, T, T, T,
      T, T, T, T, T, T, T, T, T, T, T, T, T, T, T, T
    )

  @inline(__always)
  init(repeating v: T) {
    self.items = (
      v, v, v, v, v, v, v, v, v, v, v, v, v, v, v, v,
      v, v, v, v, v, v, v, v, v, v, v, v, v, v, v, v,
      v, v, v, v, v, v, v, v, v, v, v, v, v, v, v, v
    )
  }

  static var capacity: Int {
    @inline(__always) get { 48 }
  }
}

struct FixedArrayStorage256<T>: FixedArrayStorage {
  internal var items:
    (
      T, T, T, T, T, T, T, T, T, T, T, T, T, T, T, T,
      T, T, T, T, T, T, T, T, T, T, T, T, T, T, T, T,
      T, T, T, T, T, T, T, T, T, T, T, T, T, T, T, T,
      T, T, T, T, T, T, T, T, T, T, T, T, T, T, T, T,
      T, T, T, T, T, T, T, T, T, T, T, T, T, T, T, T,
      T, T, T, T, T, T, T, T, T, T, T, T, T, T, T, T,
      T, T, T, T, T, T, T, T, T, T, T, T, T, T, T, T,
      T, T, T, T, T, T, T, T, T, T, T, T, T, T, T, T,
      T, T, T, T, T, T, T, T, T, T, T, T, T, T, T, T,
      T, T, T, T, T, T, T, T, T, T, T, T, T, T, T, T,
      T, T, T, T, T, T, T, T, T, T, T, T, T, T, T, T,
      T, T, T, T, T, T, T, T, T, T, T, T, T, T, T, T,
      T, T, T, T, T, T, T, T, T, T, T, T, T, T, T, T,
      T, T, T, T, T, T, T, T, T, T, T, T, T, T, T, T,
      T, T, T, T, T, T, T, T, T, T, T, T, T, T, T, T,
      T, T, T, T, T, T, T, T, T, T, T, T, T, T, T, T
    )

  @inline(__always)
  init(repeating v: T) {
    self.items = (
      v, v, v, v, v, v, v, v, v, v, v, v, v, v, v, v,
      v, v, v, v, v, v, v, v, v, v, v, v, v, v, v, v,
      v, v, v, v, v, v, v, v, v, v, v, v, v, v, v, v,
      v, v, v, v, v, v, v, v, v, v, v, v, v, v, v, v,
      v, v, v, v, v, v, v, v, v, v, v, v, v, v, v, v,
      v, v, v, v, v, v, v, v, v, v, v, v, v, v, v, v,
      v, v, v, v, v, v, v, v, v, v, v, v, v, v, v, v,
      v, v, v, v, v, v, v, v, v, v, v, v, v, v, v, v,
      v, v, v, v, v, v, v, v, v, v, v, v, v, v, v, v,
      v, v, v, v, v, v, v, v, v, v, v, v, v, v, v, v,
      v, v, v, v, v, v, v, v, v, v, v, v, v, v, v, v,
      v, v, v, v, v, v, v, v, v, v, v, v, v, v, v, v,
      v, v, v, v, v, v, v, v, v, v, v, v, v, v, v, v,
      v, v, v, v, v, v, v, v, v, v, v, v, v, v, v, v,
      v, v, v, v, v, v, v, v, v, v, v, v, v, v, v, v,
      v, v, v, v, v, v, v, v, v, v, v, v, v, v, v, v
    )
  }

  static var capacity: Int {
    @inline(__always) get { 256 }
  }
}
