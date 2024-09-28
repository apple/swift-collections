//===--- OutputSpan.swift -------------------------------------------------===//
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

public struct OutputSpan<Element: ~Copyable /*& ~Escapable*/>: ~Copyable, ~Escapable {
  @usableFromInline let _start: UnsafeMutablePointer<Element>
  public let capacity: Int
  public private(set) var initialized: Int = 0

  deinit {
    // `self` always borrows memory, and it shouldn't have gotten here.
    // Failing to use `relinquishBorrowedMemory()` is an error.
    if initialized > 0 {
      fatalError()
    }
  }

  public init<Owner: ~Copyable & ~Escapable>(
    initializing pointer: UnsafeMutablePointer<Element>,
    capacity: Int,
    initialized: Int = 0,
    owner: borrowing Owner
  ) -> dependsOn(owner) Self {
    self._start = pointer
    self.capacity = capacity
    self.initialized = initialized
  }
}

extension OutputSpan where Element: ~Copyable /*& ~Escapable*/ {
  public mutating func appendElement(_ value: consuming Element) {
    precondition(initialized < capacity, "Output buffer overflow")
    _start.advanced(by: initialized).initialize(to: value)
    initialized &+= 1
  }

  public mutating func deinitializeLastElement() -> Element? {
    guard initialized > 0 else { return nil }
    initialized &-= 1
    return _start.advanced(by: initialized).move()
  }
}

extension OutputSpan where Element: ~Copyable {
  public mutating func deinitialize() {
    let b = UnsafeMutableBufferPointer(start: _start, count: initialized)
    b.deinitialize()
    initialized = 0
  }
}

extension OutputSpan {
  public mutating func append<S>(
    from elements: S
  ) -> S.Iterator where S: Sequence, S.Element == Element {
    var iterator = elements.makeIterator()
    append(from: &iterator)
    return iterator
  }

  public mutating func append(
    from elements: inout some IteratorProtocol<Element>
  ) {
    while initialized < capacity {
      guard let element = elements.next() else { break }
      _start.advanced(by: initialized).initialize(to: element)
      initialized &+= 1
    }
  }

  public mutating func append(
    fromContentsOf source: some Collection<Element>
  ) {
    let count = source.withContiguousStorageIfAvailable {
      guard let sourceAddress = $0.baseAddress, !$0.isEmpty else {
        return 0
      }
      let available = capacity &- initialized
      precondition(
        $0.count <= available,
        "buffer cannot contain every element from source."
      )
      let tail = _start.advanced(by: initialized)
      tail.initialize(from: sourceAddress, count: $0.count)
      return $0.count
    }
    if let count {
      initialized &+= count
      return
    }

    let available = capacity &- initialized
    let tail = _start.advanced(by: initialized)
    let suffix = UnsafeMutableBufferPointer(start: tail, count: available)
    var (iterator, copied) = source._copyContents(initializing: suffix)
    precondition(
      iterator.next() == nil,
      "buffer cannot contain every element from source."
    )
    assert(initialized + copied <= capacity)
    initialized &+= copied
  }

  //FIXME: rdar://136838539 & rdar://136849171
  public mutating func append(fromContentsOf source: Span<Element>) {
    let available = capacity &- initialized
    precondition(
      source.count <= available,
      "buffer cannot contain every element from source."
    )
    source.withUnsafeBufferPointer {
      let tail = _start.advanced(by: initialized)
      tail.initialize(from: $0.baseAddress!, count: $0.count)
    }
    initialized &+= source.count
  }
}

extension OutputSpan where Element: ~Copyable /*& ~Escapable*/ {

  public mutating func moveAppend(
    fromContentsOf source: UnsafeMutableBufferPointer<Element>
  ) {
    guard let sourceAddress = source.baseAddress, !source.isEmpty else {
      return
    }
    let available = capacity &- initialized
    precondition(
      source.count <= available,
      "buffer cannot contain every element from source."
    )
    let tail = _start.advanced(by: initialized)
    tail.moveInitialize(from: sourceAddress, count: source.count)
    initialized &+= source.count
  }
}

extension OutputSpan {

  public mutating func moveAppend(
    fromContentsOf source: Slice<UnsafeMutableBufferPointer<Element>>
  ) {
    moveAppend(fromContentsOf: UnsafeMutableBufferPointer(rebasing: source))
  }
}

//extension OutputSpan where Element: ~Copyable /*& ~Escapable*/ {
//  public mutating func initializeSuffixOutOfOrder<R, E>(
//    _ count: Int,
//    body: (inout RandomAccessOutputSpan<Element>) throws(E) -> R
//  ) throws(E) -> R {
//    precondition(initialized + count < capacity)
//    var out = RandomAccessOutputSpan<Element>(
//      initializing: _start.advanced(by: initialized), capacity: count, owner: self
//    )
//    let result = try body(&out)
//    let buffer = out.relinquishBorrowedMemory()
//    assert(
//      buffer.baseAddress == _start.advanced(by: initialized) &&
//      initialized + buffer.count < capacity
//    )
//    initialized &+= buffer.count
//    return result
//  }
//}

extension OutputSpan {
  public var initializedPrefix: Span<Element> {
    get { Span(_unsafeStart: _start, count: initialized) }
  }

  public func withSpan<E: Error, R: ~Copyable>(
    _ body: (Span<Element>) throws(E) -> R
  ) throws(E) -> R {
    try body(initializedPrefix)
  }
}

//  public var mutatingInitializedPrefix: /*inout*/ MutableBufferView<Element> {
//    mutating /* _read */ get /* mutating(self) */ {
//      /* yield */ MutableBufferView(
//        unsafeMutablePointer: _start,
//        count: initialized,
//        dependsOn: /* self */ _start
//      )
//    }
//  }

//  public mutating func withMutableBufferView<R>(
//    _ body: (inout MutableBufferView<Element>) throws -> R
//  ) rethrows -> R {
//    var view = MutableBufferView<Element>(
//      unsafeMutablePointer: _start,
//      count: initialized,
//      dependsOn: /* self */ _start
//    )
//    return try body(&view)
//  }

extension OutputSpan {

  public consuming func relinquishBorrowedMemory() -> UnsafeMutableBufferPointer<Element> {
    let (start, initialized) = (self._start, self.initialized)
    discard self
    return .init(start: start, count: initialized)
  }
}

extension Array {

  public init(
    capacity: Int,
    initializingWith initializer: (inout OutputSpan<Element>) throws -> Void
  ) rethrows {
    try self.init(
      unsafeUninitializedCapacity: capacity,
      initializingWith: { (buffer, count) in
        var output = OutputSpan<Element>(
          initializing: buffer.baseAddress.unsafelyUnwrapped,
          capacity: buffer.count,
          owner: buffer
        )
        try initializer(&output)
        let initialized = output.relinquishBorrowedMemory()
        assert(initialized.baseAddress == buffer.baseAddress)
        count = initialized.count
      }
    )
  }
}

extension String {

  // also see https://github.com/apple/swift/pull/23050
  // and `final class __SharedStringStorage`

  @available(macOS 11, *)
  public init(
    utf8Capacity capacity: Int,
    initializingWith initializer: (inout OutputSpan<UInt8>) throws -> Void
  ) rethrows {
    try self.init(
      unsafeUninitializedCapacity: capacity,
      initializingUTF8With: { buffer in
        var output = OutputSpan(
          initializing: buffer.baseAddress.unsafelyUnwrapped,
          capacity: capacity,
          owner: buffer
        )
        try initializer(&output)
        let initialized = output.relinquishBorrowedMemory()
        assert(initialized.baseAddress == buffer.baseAddress)
        return initialized.count
      }
    )
  }
}

import Foundation

extension Data {

  public init(
    capacity: Int,
    initializingWith initializer: (inout OutputSpan<UInt8>) throws -> Void
  ) rethrows {
    self = Data(count: capacity) // initialized with zeroed buffer
    let count = try self.withUnsafeMutableBytes { rawBuffer in
      try rawBuffer.withMemoryRebound(to: UInt8.self) { buffer in
        buffer.deinitialize()
        var output = OutputSpan(
          initializing: buffer.baseAddress.unsafelyUnwrapped,
          capacity: capacity,
          owner: buffer
        )
        try initializer(&output)
        let initialized = output.relinquishBorrowedMemory()
        assert(initialized.baseAddress == buffer.baseAddress)
        return initialized.count
      }
    }
    assert(count <= self.count)
    self.replaceSubrange(count..<self.count, with: EmptyCollection())
  }
}
