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

// OutputSpan<Element> represents a span of memory which contains
// a variable number of `Element` instances, followed by uninitialized memory.
@_disallowFeatureSuppression(NonescapableTypes)
@frozen
public struct OutputSpan<Element: ~Copyable>: ~Copyable, ~Escapable {
  @usableFromInline let _pointer: UnsafeMutableRawPointer?

  public let capacity: Int

  @usableFromInline
  var _initialized: Int = 0

  @usableFromInline @inline(__always)
  var _start: UnsafeMutableRawPointer { _pointer.unsafelyUnwrapped }

  @_alwaysEmitIntoClient
  public var available: Int { capacity &- _initialized }

  @_alwaysEmitIntoClient
  public var count: Int { _initialized }

  @_alwaysEmitIntoClient
  public var isEmpty: Bool { _initialized == 0 }

  deinit {
    // `self` always borrows memory, and it shouldn't have gotten here.
    // Failing to use `relinquishBorrowedMemory()` is an error.
    if _initialized > 0 {
#if false
      _start.withMemoryRebound(to: Element.self, capacity: _initialized) {
        $0.deinitialize(count: _initialized)
      }
#else
      fatalError()
#endif
    }
  }

  @_disallowFeatureSuppression(NonescapableTypes)
  @usableFromInline @inline(__always)
  init(
    _unchecked start: UnsafeMutableRawPointer?,
    capacity: Int,
    initialized: Int
  ) -> dependsOn(immortal) Self {
    _pointer = start
    self.capacity = capacity
    _initialized = initialized
  }
}

@_disallowFeatureSuppression(NonescapableTypes)
@available(*, unavailable)
extension OutputSpan: Sendable {}

@_disallowFeatureSuppression(NonescapableTypes)
extension OutputSpan where Element: ~Copyable  {

  @_disallowFeatureSuppression(NonescapableTypes)
  @usableFromInline @inline(__always)
  init(
    _unchecked buffer: UnsafeMutableBufferPointer<Element>,
    initialized: Int
  ) -> dependsOn(immortal) Self {
    _pointer = .init(buffer.baseAddress)
    capacity = buffer.count
    _initialized = initialized
  }

  @_disallowFeatureSuppression(NonescapableTypes)
  @_alwaysEmitIntoClient
  public init(
    _initializing buffer: UnsafeMutableBufferPointer<Element>,
    initialized: Int = 0
  ) -> dependsOn(immortal) Self {
    precondition(
      ((Int(bitPattern: buffer.baseAddress) &
        (MemoryLayout<Element>.alignment&-1)) == 0),
      "baseAddress must be properly aligned to access Element"
    )
    self.init(_unchecked: buffer, initialized: initialized)
  }

  @_disallowFeatureSuppression(NonescapableTypes)
  @_alwaysEmitIntoClient
  public init(
    _initializing pointer: UnsafeMutablePointer<Element>,
    capacity: Int,
    initialized: Int = 0
  ) -> dependsOn(immortal) Self {
    precondition(capacity >= 0, "Capacity must be 0 or greater")
    self.init(
      _initializing: .init(start: pointer, count: capacity),
      initialized: initialized
    )
  }
}

@_disallowFeatureSuppression(NonescapableTypes)
extension OutputSpan {

  @_disallowFeatureSuppression(NonescapableTypes)
  @_alwaysEmitIntoClient
  public init(
    _initializing buffer: Slice<UnsafeMutableBufferPointer<Element>>,
    initialized: Int = 0
  ) -> dependsOn(immortal) Self {
    self.init(_initializing: .init(rebasing: buffer), initialized: initialized)
  }
}

@_disallowFeatureSuppression(NonescapableTypes)
extension OutputSpan where Element: BitwiseCopyable {

  @_disallowFeatureSuppression(NonescapableTypes)
  @_alwaysEmitIntoClient
  public init(
    _initializing bytes: UnsafeMutableRawBufferPointer,
    initialized: Int = 0
  ) -> dependsOn(immortal) Self {
    precondition(
      ((Int(bitPattern: bytes.baseAddress) &
        (MemoryLayout<Element>.alignment&-1)) == 0),
      "baseAddress must be properly aligned to access Element"
    )
    let (byteCount, stride) = (bytes.count, MemoryLayout<Element>.stride)
    let (count, remainder) = byteCount.quotientAndRemainder(dividingBy: stride)
    precondition(remainder == 0, "Span must contain a whole number of elements")
    self.init(
      _unchecked: bytes.baseAddress, capacity: count, initialized: initialized
    )
  }

  @_disallowFeatureSuppression(NonescapableTypes)
  @_alwaysEmitIntoClient
  public init(
    _initializing pointer: UnsafeMutableRawPointer,
    capacity: Int,
    initialized: Int = 0
  ) -> dependsOn(immortal) Self {
    precondition(capacity >= 0, "Capacity must be 0 or greater")
    self.init(
      _initializing: .init(start: pointer, count: capacity),
      initialized: initialized
    )
  }

  @_disallowFeatureSuppression(NonescapableTypes)
  @_alwaysEmitIntoClient
  public init(
    _initializing buffer: Slice<UnsafeMutableRawBufferPointer>,
    initialized: Int = 0
  ) -> dependsOn(immortal) Self {
    self.init(
      _initializing: UnsafeMutableRawBufferPointer(rebasing: buffer),
      initialized: initialized
    )
  }
}

@_disallowFeatureSuppression(NonescapableTypes)
extension OutputSpan where Element: ~Copyable {

  @_alwaysEmitIntoClient
  public mutating func appendElement(_ value: consuming Element) {
    precondition(_initialized < capacity, "Output buffer overflow")
    let p = _start.advanced(by: _initialized&*MemoryLayout<Element>.stride)
    p.initializeMemory(as: Element.self, to: value)
    _initialized &+= 1
  }

  @_alwaysEmitIntoClient
  public mutating func deinitializeLastElement() -> Element? {
    guard _initialized > 0 else { return nil }
    _initialized &-= 1
    let p = _start.advanced(by: _initialized&*MemoryLayout<Element>.stride)
    return p.withMemoryRebound(to: Element.self, capacity: 1, { $0.move() })
  }

  @_alwaysEmitIntoClient
  public mutating func deinitialize() {
    _ = _start.withMemoryRebound(to: Element.self, capacity: _initialized) {
      $0.deinitialize(count: _initialized)
    }
    _initialized = 0
  }
}

//MARK: bulk-update functions
@_disallowFeatureSuppression(NonescapableTypes)
extension OutputSpan {

  @_alwaysEmitIntoClient
  public mutating func append(repeating repeatedValue: Element, count: Int) {
    let available = capacity &- _initialized
    precondition(
      count <= available,
      "destination span cannot contain number of elements requested."
    )
    let offset = _initialized&*MemoryLayout<Element>.stride
    let p = _start.advanced(by: offset)
    p.withMemoryRebound(to: Element.self, capacity: count) {
      $0.initialize(repeating: repeatedValue, count: count)
    }
    _initialized &+= count
  }

  @_alwaysEmitIntoClient
  public mutating func append<S>(
    from elements: S
  ) -> S.Iterator where S: Sequence, S.Element == Element {
    var iterator = elements.makeIterator()
    append(from: &iterator)
    return iterator
  }

  @_alwaysEmitIntoClient
  public mutating func append(
    from elements: inout some IteratorProtocol<Element>
  ) {
    while _initialized < capacity {
      guard let element = elements.next() else { break }
      let p = _start.advanced(by: _initialized&*MemoryLayout<Element>.stride)
      p.initializeMemory(as: Element.self, to: element)
      _initialized &+= 1
    }
  }

  @_alwaysEmitIntoClient
  public mutating func append(
    fromContentsOf source: some Collection<Element>
  ) {
    let void: Void? = source.withContiguousStorageIfAvailable {
#if false
      append(fromContentsOf: Span(_unsafeElements: $0))
#else //FIXME: remove once rdar://136838539 & rdar://136849171 are fixed
      append(fromContentsOf: $0)
#endif
    }
    if void != nil {
      return
    }

    let available = capacity &- _initialized
    let tail = _start.advanced(by: _initialized&*MemoryLayout<Element>.stride)
    var (iterator, copied) =
    tail.withMemoryRebound(to: Element.self, capacity: available) {
      let suffix = UnsafeMutableBufferPointer(start: $0, count: available)
      return source._copyContents(initializing: suffix)
    }
    precondition(
      iterator.next() == nil,
      "destination span cannot contain every element from source."
    )
    assert(_initialized + copied <= capacity) // invariant check
    _initialized &+= copied
  }

  //FIXME: remove once rdar://136838539 & rdar://136849171 are fixed
  public mutating func append(
    fromContentsOf source: UnsafeBufferPointer<Element>
  ) {
    guard !source.isEmpty else { return }
    precondition(
      source.count <= available,
      "destination span cannot contain every element from source."
    )
    let tail = _start.advanced(by: _initialized&*MemoryLayout<Element>.stride)
    source.baseAddress!.withMemoryRebound(to: Element.self, capacity: source.count) {
      _ = tail.initializeMemory(as: Element.self, from: $0, count: source.count)
    }
    _initialized += source.count
  }

  //FIXME: rdar://136838539 & rdar://136849171
  @_disallowFeatureSuppression(NonescapableTypes)
  @_alwaysEmitIntoClient
  public mutating func append(
    fromContentsOf source: Span<Element>
  ) {
    guard !source.isEmpty else { return }
    precondition(
      source.count <= available,
      "destination span cannot contain every element from source."
    )
    let tail = _start.advanced(by: _initialized&*MemoryLayout<Element>.stride)
    source._start.withMemoryRebound(to: Element.self, capacity: source.count) {
      _ = tail.initializeMemory(as: Element.self, from: $0, count: source.count)
    }
    _initialized += source.count
  }

  @_disallowFeatureSuppression(NonescapableTypes)
  @_alwaysEmitIntoClient
  public mutating func append(fromContentsOf source: borrowing MutableSpan<Element>) {
    source.withUnsafeBufferPointer { append(fromContentsOf: $0) }
  }
}

@_disallowFeatureSuppression(NonescapableTypes)
extension OutputSpan where Element: ~Copyable {

  @_disallowFeatureSuppression(NonescapableTypes)
  @_alwaysEmitIntoClient
  public mutating func moveAppend(
    fromContentsOf source: consuming Self
  ) {
    guard !source.isEmpty else { return }
    precondition(
      source.count <= available,
      "buffer cannot contain every element from source."
    )
    let buffer = source.relinquishBorrowedMemory()
    // we must now deinitialize the returned UMBP
    let tail = _start.advanced(by: _initialized&*MemoryLayout<Element>.stride)
    tail.moveInitializeMemory(
      as: Element.self, from: buffer.baseAddress!, count: buffer.count
    )
    _initialized &+= buffer.count
  }

  @_disallowFeatureSuppression(NonescapableTypes)
  @_alwaysEmitIntoClient
  public mutating func moveAppend(
    fromContentsOf source: UnsafeMutableBufferPointer<Element>
  ) {
#if false //FIXME: rdar://136838539 & rdar://136849171
    let source = OutputSpan(_initializing: source, initialized: source.count)
    moveAppend(fromContentsOf: source)
#else
    guard !source.isEmpty else { return }
    precondition(
      source.count <= available,
      "buffer cannot contain every element from source."
    )
    let tail = _start.advanced(by: _initialized&*MemoryLayout<Element>.stride)
    tail.moveInitializeMemory(
      as: Element.self, from: source.baseAddress!, count: source.count
    )
    _initialized &+= source.count
#endif
  }
}

extension OutputSpan {

  @_disallowFeatureSuppression(NonescapableTypes)
  @_alwaysEmitIntoClient
  public mutating func moveAppend(
    fromContentsOf source: Slice<UnsafeMutableBufferPointer<Element>>
  ) {
    moveAppend(fromContentsOf: UnsafeMutableBufferPointer(rebasing: source))
  }
}

extension OutputSpan where Element: BitwiseCopyable {

}

extension OutputSpan where Element: ~Copyable {

  @_disallowFeatureSuppression(NonescapableTypes)
  @_alwaysEmitIntoClient
  public var initializedPrefix: Span<Element> {
    get { Span(_unchecked: _pointer, count: _initialized) }
  }

  @_disallowFeatureSuppression(NonescapableTypes)
  @_alwaysEmitIntoClient
  public func withSpan<E: Error, R: ~Copyable>(
    _ body: (Span<Element>) throws(E) -> R
  ) throws(E) -> R {
    try body(initializedPrefix)
  }

  @_disallowFeatureSuppression(NonescapableTypes)
  @_alwaysEmitIntoClient
  public mutating func withMutableSpan<E: Error, Result: ~Copyable>(
    _ body: (inout MutableSpan<Element>) throws(E) -> Result
  ) throws(E) -> Result {
    var span = MutableSpan<Element>(_unchecked: _pointer, count: _initialized)
    defer {
      precondition(
        span.count == _initialized && span._pointer == _start,
        "Substituting the MutableSpan is unsound and unsafe."
      )
    }
    return try body(&span)
  }
}

@_disallowFeatureSuppression(NonescapableTypes)
extension OutputSpan where Element: ~Copyable {

  @_alwaysEmitIntoClient
  public consuming func relinquishBorrowedMemory() -> UnsafeMutableBufferPointer<Element> {
    let (start, count) = (self._pointer, self._initialized)
    discard self
    let typed = start?.bindMemory(to: Element.self, capacity: count)
    return .init(start: typed, count: count)
  }
}

@_disallowFeatureSuppression(NonescapableTypes)
extension OutputSpan where Element: BitwiseCopyable {

  @_alwaysEmitIntoClient
  public consuming func relinquishBorrowedBytes() -> UnsafeMutableRawBufferPointer {
    let (start, count) = (self._pointer, self._initialized)
    discard self
    return .init(start: start, count: count&*MemoryLayout<Element>.stride)
  }
}
