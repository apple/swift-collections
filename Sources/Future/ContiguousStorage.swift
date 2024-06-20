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

public protocol ContiguousStorage<Element>: ~Copyable, ~Escapable {
  associatedtype Element/*: ~Copyable & ~Escapable*/

  var storage: Span<Element> { borrowing get }
}

extension Span: ContiguousStorage /*where Element: ~Copyable & ~Escapable*/ {
  public var storage: Self { self }
}

extension Array: ContiguousStorage {
  public var storage: Span<Element> {
    _read {
      if let a = _baseAddressIfContiguous {
        yield Span(unsafeStart: a, count: count, owner: self)
      }
      else {
        let a = ContiguousArray(copy self)
        #if true
        let s = Span(
          unsafeStart: a._baseAddressIfContiguous!, count: a.count, owner: a
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
  public var storage: Span<Element> {
    borrowing get {
      Span(
        unsafeStart: _baseAddressIfContiguous!, count: count, owner: self
      )
    }
  }
}

extension CollectionOfOne: ContiguousStorage {
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
        unsafeStart: a._baseAddressIfContiguous!, count: 1, owner: a
      )
    }
  }
}

extension String.UTF8View: ContiguousStorage {
  public var storage: Span<UTF8.CodeUnit> {
    _read {
      if count < 16 { // Wrong way to know whether the String is smol
//      if _guts.isSmall {
//        let /*@addressable*/ rawStorage = _guts.asSmall._storage
//        let span = RawSpan(
//          unsafeRawPointer: UnsafeRawPointer(Builtin.adressable(rawStorage)),
//          count: MemoryLayout<_SmallString.RawBitPattern>.size,
//          owner: self
//        )
//        yield span.view(as: UTF8.CodeUnit.self)

        let a = ContiguousArray(self)
//        yield a.storage
        yield Span(
          unsafeStart: a._baseAddressIfContiguous!, count: 1, owner: a
        )
      }
      else if let buffer = withContiguousStorageIfAvailable({ $0 }) {
        // this is totally wrong, but there is a way with stdlib-internal API
        yield Span(unsafeElements: buffer, owner: self)
      }
      else { // copy non-fast code units if we don't have eager bridging
        let a = ContiguousArray(self)
//        yield a.storage
        yield Span(
          unsafeStart: a._baseAddressIfContiguous!, count: 1, owner: a
        )
      }
    }
  }
}
