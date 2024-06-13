//===--- ContiguousStorage.swift ------------------------------------------===//
//
// This source file is part of the Swift.org open source project
//
// Copyright (c) 2024 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
// See https://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//
//===----------------------------------------------------------------------===//

public protocol ContiguousStorage<StoredElement>: ~Copyable, ~Escapable {
  associatedtype StoredElement/*: ~Copyable & ~Escapable*/

  var storage: Span<StoredElement> { borrowing get }
}

extension Span: ContiguousStorage /*where Element: ~Copyable & ~Escapable*/ {
  public typealias StoredElement = Element
  public var storage: Self { self }
}

extension Array: ContiguousStorage {
  public typealias StoredElement = Element
  public var storage: Span<Element> {
    _read {
      if let a = _baseAddressIfContiguous {
        yield Span(
          unsafePointer: a, count: count, owner: self
        )
      }
      else {
        let a = ContiguousArray(copy self)
        #if true
        let s = Span(
          unsafePointer: a._baseAddressIfContiguous!, count: a.count, owner: a
        )
        #else
        let s = a.storage
        #endif
        yield s
      }
    }
  }
}

extension ContiguousArray: ContiguousStorage {
  public typealias StoredElement = Element
  public var storage: Span<Element> {
    borrowing get {
      Span(
        unsafePointer: _baseAddressIfContiguous!, count: count, owner: self
      )
    }
  }
}

extension CollectionOfOne: ContiguousStorage {
  public typealias StoredElement = Element
  public var storage: Span<Element> {
    _read {
/* ideally: (with strawman syntax)
      @addressable let value = self._element
      yield Span(
        unsafePointer: Builtin.addressable(value), count: 1, owner: self
      )
*/

      let a = ContiguousArray(self)
      yield Span(
        unsafePointer: a._baseAddressIfContiguous!, count: 1, owner: a
      )
    }
  }
}

extension String: ContiguousStorage {
  public typealias StoredElement = UTF8.CodeUnit
  public var storage: Span<UTF8.CodeUnit> {
    _read {
      if utf8.count < 16 { // Wrong way to know whether the String is smol
//      if _guts.isSmall {
//        let /*@addressable*/ rawStorage = _guts.asSmall._storage
//        let span = RawSpan(
//          unsafeRawPointer: UnsafeRawPointer(Builtin.adressable(rawStorage)),
//          count: MemoryLayout<_SmallString.RawBitPattern>.size,
//          owner: self
//        )
//        yield span.view(as: UTF8.CodeUnit.self)

        let a = ContiguousArray(utf8)
//        yield a.storage
        yield Span(
          unsafePointer: a._baseAddressIfContiguous!, count: 1, owner: a
        )
      }
      else if let buffer = utf8.withContiguousStorageIfAvailable({ $0 }) {
        // this is totally wrong, but there is a way with stdlib-internal API
        yield Span(
          unsafeBufferPointer: buffer,
          owner: self
        )
      }
      else { // copy non-fast code units if we don't have eager bridging
        let a = ContiguousArray(utf8)
//        yield a.storage
        yield Span(
          unsafePointer: a._baseAddressIfContiguous!, count: 1, owner: a
        )
      }
    }
  }
}
