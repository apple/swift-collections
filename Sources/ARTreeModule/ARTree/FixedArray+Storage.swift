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

protocol FixedStorage {
  associatedtype Element

  static var capacity: Int { get }
  init(repeating: Element)
}

struct FixedStorage4<T>: FixedStorage {
  internal var items: (T, T, T, T)

  @inline(__always)
  init(repeating v: T) {
    self.items = (v, v, v, v)
  }

  static var capacity: Int {
    @inline(__always) get { 4 }
  }
}

struct FixedStorage8<T>: FixedStorage {
  internal var items: (T, T, T, T, T, T, T, T)

  @inline(__always)
  init(repeating v: T) {
    self.items = (v, v, v, v, v, v, v, v)
  }

  static var capacity: Int {
    @inline(__always) get { 8 }
  }
}

struct FixedStorage16<T>: FixedStorage {
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

struct FixedStorage48<T>: FixedStorage {
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

struct FixedStorage256<T>: FixedStorage {
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
