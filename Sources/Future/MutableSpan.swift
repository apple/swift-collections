//===--- MutableSpan.swift ------------------------------------------------===//
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

import Builtin

// A MutableSpan<Element> represents a span of memory which
// contains initialized `Element` instances.
@_disallowFeatureSuppression(NonescapableTypes)
@frozen
public struct MutableSpan<Element: ~Copyable>: ~Copyable & ~Escapable {
  @usableFromInline let _pointer: UnsafeMutableRawPointer?

  @usableFromInline let _count: Int

  @usableFromInline @inline(__always)
  var _start: UnsafeMutableRawPointer { _pointer.unsafelyUnwrapped }

  @_disallowFeatureSuppression(NonescapableTypes)
  @usableFromInline @inline(__always)
  init(
    _unchecked start: UnsafeMutableRawPointer?,
    count: Int
  ) -> dependsOn(immortal) Self {
    _pointer = start
    _count = count
  }
}

@_disallowFeatureSuppression(NonescapableTypes)
@available(*, unavailable)
extension MutableSpan: Sendable {}

@_disallowFeatureSuppression(NonescapableTypes)
extension MutableSpan where Element: ~Copyable {

  @_disallowFeatureSuppression(NonescapableTypes)
  @usableFromInline @inline(__always)
  internal init(
    _unchecked elements: UnsafeMutableBufferPointer<Element>
  ) -> dependsOn(immortal) Self {
    _pointer = .init(elements.baseAddress)
    _count = elements.count
  }

  @_disallowFeatureSuppression(NonescapableTypes)
  @_alwaysEmitIntoClient
  public init(
    _unsafeElements buffer: UnsafeMutableBufferPointer<Element>
  ) -> dependsOn(immortal) Self {
    precondition(
      ((Int(bitPattern: buffer.baseAddress) &
        (MemoryLayout<Element>.alignment&-1)) == 0),
      "baseAddress must be properly aligned to access Element"
    )
    self.init(_unchecked: buffer)
  }

  @_disallowFeatureSuppression(NonescapableTypes)
  @_alwaysEmitIntoClient
  public init(
    _unsafeStart start: UnsafeMutablePointer<Element>,
    count: Int
  ) -> dependsOn(immortal) Self {
    precondition(count >= 0, "Count must not be negative")
    self.init(_unsafeElements: .init(start: start, count: count))
  }
}

@_disallowFeatureSuppression(NonescapableTypes)
extension MutableSpan {

  @_disallowFeatureSuppression(NonescapableTypes)
  @_alwaysEmitIntoClient
  public init(
    _unsafeElements elements: Slice<UnsafeMutableBufferPointer<Element>>
  ) -> dependsOn(immortal) Self {
    self.init(_unsafeElements: UnsafeMutableBufferPointer(rebasing: elements))
  }
}

@_disallowFeatureSuppression(NonescapableTypes)
extension MutableSpan where Element: BitwiseCopyable {

  @_disallowFeatureSuppression(NonescapableTypes)
  @_alwaysEmitIntoClient
  public init(
    _unsafeBytes buffer: UnsafeMutableRawBufferPointer
  ) -> dependsOn(immortal) Self {
    precondition(
      ((Int(bitPattern: buffer.baseAddress) &
        (MemoryLayout<Element>.alignment&-1)) == 0),
      "baseAddress must be properly aligned to access Element"
    )
    let (byteCount, stride) = (buffer.count, MemoryLayout<Element>.stride)
    let (count, remainder) = byteCount.quotientAndRemainder(dividingBy: stride)
    precondition(remainder == 0, "Span must contain a whole number of elements")
    self.init(_unchecked: buffer.baseAddress, count: count)
  }

  @_disallowFeatureSuppression(NonescapableTypes)
  @_alwaysEmitIntoClient
  public init(
    _unsafeStart pointer: UnsafeMutableRawPointer,
    byteCount: Int
  ) -> dependsOn(immortal) Self {
    precondition(byteCount >= 0, "Count must not be negative")
    self.init(_unsafeBytes: .init(start: pointer, count: byteCount))
  }

  @_disallowFeatureSuppression(NonescapableTypes)
  @_alwaysEmitIntoClient
  public init(
    _unsafeBytes buffer: Slice<UnsafeMutableRawBufferPointer>
  ) -> dependsOn(immortal) Self {
    self.init(_unsafeBytes: UnsafeMutableRawBufferPointer(rebasing: buffer))
  }
}

@_disallowFeatureSuppression(NonescapableTypes)
extension Span where Element: ~Copyable {

  @_disallowFeatureSuppression(NonescapableTypes)
  @_alwaysEmitIntoClient
  public init(_unsafeMutableSpan mutableSpan: borrowing MutableSpan<Element>) {
    self.init(_unchecked: mutableSpan._start, count: mutableSpan.count)
  }
}

@_disallowFeatureSuppression(NonescapableTypes)
extension MutableSpan where Element: ~Copyable {

  @_disallowFeatureSuppression(NonescapableTypes)
  @_alwaysEmitIntoClient
  public var storage: Span<Element> { Span(_unsafeMutableSpan: self) }

  @_disallowFeatureSuppression(NonescapableTypes)
  @_alwaysEmitIntoClient
  public func withSpan<E: Error, Result: ~Copyable>(
    _ body: (Span<Element>) throws(E) -> Result
  ) throws(E) -> Result {
    try body(Span(_unsafeMutableSpan: self))
  }
}

@_disallowFeatureSuppression(NonescapableTypes)
extension RawSpan {

  @_disallowFeatureSuppression(NonescapableTypes)
  @_alwaysEmitIntoClient
  public init<Element: BitwiseCopyable>(
    _unsafeMutableSpan mutableSpan: borrowing MutableSpan<Element>
  ) {
    self.init(
      _unchecked: mutableSpan._start,
      byteCount: mutableSpan.count &* MemoryLayout<Element>.stride
    )
  }
}

@_disallowFeatureSuppression(NonescapableTypes)
extension MutableSpan where Element: Equatable {

  @_disallowFeatureSuppression(NonescapableTypes)
  @_alwaysEmitIntoClient
  public func _elementsEqual(_ other: borrowing Self) -> Bool {
    _elementsEqual(Span(_unsafeMutableSpan: other))
  }

  @_disallowFeatureSuppression(NonescapableTypes)
  @_alwaysEmitIntoClient
  public func _elementsEqual(_ other: Span<Element>) -> Bool {
    Span(_unsafeMutableSpan: self)._elementsEqual(other)
  }

  @_disallowFeatureSuppression(NonescapableTypes)
  @_alwaysEmitIntoClient
  public func _elementsEqual(_ other: some Collection<Element>) -> Bool {
    Span(_unsafeMutableSpan: self)._elementsEqual(other)
  }

  @_disallowFeatureSuppression(NonescapableTypes)
  @_alwaysEmitIntoClient
  public func _elementsEqual(_ other: some Sequence<Element>) -> Bool {
    Span(_unsafeMutableSpan: self)._elementsEqual(other)
  }
}

@_disallowFeatureSuppression(NonescapableTypes)
extension MutableSpan where Element: ~Copyable {

  @_alwaysEmitIntoClient
  public var description: String {
    let addr = String(UInt(bitPattern: _pointer), radix: 16, uppercase: false)
    return "(0x\(addr), \(_count))"
  }
}

//MARK: Collection, RandomAccessCollection
@_disallowFeatureSuppression(NonescapableTypes)
extension MutableSpan where Element: ~Copyable {

  @_alwaysEmitIntoClient
  public var count: Int { _count }

  @_alwaysEmitIntoClient
  public var isEmpty: Bool { _count == 0 }

  @_alwaysEmitIntoClient
  public var _indices: Range<Int> {
    Range(uncheckedBounds: (0, _count))
  }
}

//MARK: Bounds Checking
@_disallowFeatureSuppression(NonescapableTypes)
extension MutableSpan where Element: ~Copyable {

  /// Return true if `index` is a valid offset into this `Span`
  ///
  /// - Parameters:
  ///   - index: an index to validate
  /// - Returns: true if `index` is valid
  @_disallowFeatureSuppression(NonescapableTypes)
  @_alwaysEmitIntoClient
  public func boundsContain(_ index: Int) -> Bool {
    0 <= index && index < _count
  }

  /// Return true if `indices` is a valid range of indices into this `Span`
  ///
  /// - Parameters:
  ///   - indices: a range of indices to validate
  /// - Returns: true if `indices` is a valid range of indices
  @_disallowFeatureSuppression(NonescapableTypes)
  @_alwaysEmitIntoClient
  public func boundsContain(_ indices: Range<Int>) -> Bool {
    boundsContain(indices.lowerBound) && indices.upperBound <= _count
  }

  /// Return true if `indices` is a valid range of indices into this `Span`
  ///
  /// - Parameters:
  ///   - indices: a range of indices to validate
  /// - Returns: true if `indices` is a valid range of indices
  @_disallowFeatureSuppression(NonescapableTypes)
  @_alwaysEmitIntoClient
  public func boundsContain(_ indices: ClosedRange<Int>) -> Bool {
    boundsContain(indices.lowerBound) && indices.upperBound < _count
  }
}

@_disallowFeatureSuppression(NonescapableTypes)
extension MutableSpan where Element: BitwiseCopyable {

  /// Construct a RawSpan over the memory represented by this span
  ///
  /// - Returns: a RawSpan over the memory represented by this span
  @_disallowFeatureSuppression(NonescapableTypes)
  @unsafe //FIXME: remove when the lifetime inference is fixed
  @_alwaysEmitIntoClient
  public var _unsafeRawSpan: RawSpan { RawSpan(_unsafeMutableSpan: self) }
}

@_disallowFeatureSuppression(NonescapableTypes)
extension MutableSpan where Element: ~Copyable {


  /// Accesses the element at the specified position in the `Span`.
  ///
  /// - Parameter position: The offset of the element to access. `position`
  ///     must be greater or equal to zero, and less than `count`.
  ///
  /// - Complexity: O(1)
  @_disallowFeatureSuppression(NonescapableTypes)
  @_alwaysEmitIntoClient
  public subscript(_ position: Int) -> Element {
    _read {
      precondition(boundsContain(position), "index out of bounds")
      yield self[unchecked: position]
    }
    _modify {
      precondition(boundsContain(position), "index out of bounds")
      yield &self[unchecked: position]
    }
  }

  /// Accesses the element at the specified position in the `Span`.
  ///
  /// This subscript does not validate `position`; this is an unsafe operation.
  ///
  /// - Parameter position: The offset of the element to access. `position`
  ///     must be greater or equal to zero, and less than `count`.
  ///
  /// - Complexity: O(1)
  @_disallowFeatureSuppression(NonescapableTypes)
  @_alwaysEmitIntoClient
  public subscript(unchecked position: Int) -> Element {
    _read {
      let offset = position&*MemoryLayout<Element>.stride
      let p = UnsafeRawPointer(_start).advanced(by: offset)._rawValue
      let binding = Builtin.bindMemory(p, count._builtinWordValue, Element.self)
      defer { Builtin.rebindMemory(p, binding) }
      yield UnsafePointer(p).pointee
    }
    _modify {
      let offset = position&*MemoryLayout<Element>.stride
      let p = UnsafeMutableRawPointer(_start).advanced(by: offset)._rawValue
      let binding = Builtin.bindMemory(p, 1._builtinWordValue, Element.self)
      defer { Builtin.rebindMemory(p, binding) }
      yield &(UnsafeMutablePointer(p).pointee)
    }
  }
}

@_disallowFeatureSuppression(NonescapableTypes)
extension MutableSpan where Element: BitwiseCopyable {

  /// Accesses the element at the specified position in the `Span`.
  ///
  /// - Parameter position: The offset of the element to access. `position`
  ///     must be greater or equal to zero, and less than `count`.
  ///
  /// - Complexity: O(1)
  @_disallowFeatureSuppression(NonescapableTypes)
  @_alwaysEmitIntoClient
  public subscript(_ position: Int) -> Element {
    get {
      precondition(boundsContain(position))
      return self[unchecked: position]
    }
    set {
      precondition(boundsContain(position))
      self[unchecked: position] = newValue
    }
  }

  /// Accesses the element at the specified position in the `Span`.
  ///
  /// This subscript does not validate `position`; this is an unsafe operation.
  ///
  /// - Parameter position: The offset of the element to access. `position`
  ///     must be greater or equal to zero, and less than `count`.
  ///
  /// - Complexity: O(1)
  @_disallowFeatureSuppression(NonescapableTypes)
  @_alwaysEmitIntoClient
  public subscript(unchecked position: Int) -> Element {
    get {
      let offset = position&*MemoryLayout<Element>.stride
      return _start.loadUnaligned(fromByteOffset: offset, as: Element.self)
    }
    set {
      let offset = position&*MemoryLayout<Element>.stride
      _start.storeBytes(of: newValue, toByteOffset: offset, as: Element.self)
    }
  }
}

@_disallowFeatureSuppression(NonescapableTypes)
extension MutableSpan where Element: ~Copyable {

  //FIXME: mark closure parameter as non-escaping
  @_disallowFeatureSuppression(NonescapableTypes)
  @_alwaysEmitIntoClient
  public func withUnsafeBufferPointer<E: Error, Result: ~Copyable>(
    _ body: (_ buffer: UnsafeBufferPointer<Element>) throws(E) -> Result
  ) throws(E) -> Result {
    try Span(_unsafeMutableSpan: self).withUnsafeBufferPointer(body)
  }

  //FIXME: mark closure parameter as non-escaping
  @_disallowFeatureSuppression(NonescapableTypes)
  @_alwaysEmitIntoClient
  public mutating func withUnsafeMutableBufferPointer<E: Error, Result: ~Copyable>(
    _ body: (inout UnsafeMutableBufferPointer<Element>) throws(E) -> Result
  ) throws(E) -> Result {
    func executeBody(
      _ start: UnsafeMutablePointer<Element>?, _ count: Int
    ) throws(E) -> Result {
      var buf = UnsafeMutableBufferPointer<Element>(start: start, count: count)
      defer {
        precondition(
          (buf.baseAddress, buf.count) == (start, count),
          "MutableSpan.withUnsafeMutableBufferPointer: replacing the buffer is not allowed"
        )
      }
      return try body(&buf)
    }
    guard let pointer = _pointer, count > 0 else {
      return try executeBody(nil, 0)
    }
    return try pointer.withMemoryRebound(to: Element.self, capacity: count) {
      pointer throws(E) -> Result in
      return try executeBody(pointer, count)
    }
  }
}

@_disallowFeatureSuppression(NonescapableTypes)
extension MutableSpan where Element: BitwiseCopyable {

  //FIXME: mark closure parameter as non-escaping
  @_disallowFeatureSuppression(NonescapableTypes)
  @_alwaysEmitIntoClient
  public func withUnsafeBytes<E: Error, Result: ~Copyable>(
    _ body: (_ buffer: UnsafeRawBufferPointer) throws(E) -> Result
  ) throws(E) -> Result {
    try RawSpan(_unsafeMutableSpan: self).withUnsafeBytes(body)
  }

  //FIXME: mark closure parameter as non-escaping
  @_disallowFeatureSuppression(NonescapableTypes)
  @_alwaysEmitIntoClient
  public mutating func withUnsafeMutableBytes<E: Error, Result: ~Copyable>(
    _ body: (_ buffer: UnsafeMutableRawBufferPointer) throws(E) -> Result
  ) throws(E) -> Result {
    let bytes = UnsafeMutableRawBufferPointer(
      start: (_count == 0) ? nil : _start,
      count: _count &* MemoryLayout<Element>.stride
    )
    return try body(bytes)
  }
}

//MARK: bulk-update functions
@_disallowFeatureSuppression(NonescapableTypes)
extension MutableSpan {

  @_alwaysEmitIntoClient
  public mutating func update(repeating repeatedValue: Element) {
    _start.withMemoryRebound(to: Element.self, capacity: count) {
      $0.update(repeating: repeatedValue, count: count)
    }
  }

  @_alwaysEmitIntoClient
  public mutating func update<S: Sequence>(
    from source: S
  ) -> (unwritten: S.Iterator, index: Int) where S.Element == Element {
    var iterator = source.makeIterator()
    let index = update(from: &iterator)
    return (iterator, index)
  }

  @_alwaysEmitIntoClient
  public mutating func update(
    from elements: inout some IteratorProtocol<Element>
  ) -> Int {
    var index = 0
    while index < _count {
      guard let element = elements.next() else { break }
      self[unchecked: index] = element
      index &+= 1
    }
    return index
  }

  @_alwaysEmitIntoClient
  public mutating func update(
    fromContentsOf source: some Collection<Element>
  ) -> Int {
    let updated = source.withContiguousStorageIfAvailable {
      self.update(fromContentsOf: Span(_unsafeElements: $0))
    }
    if let updated {
      return 0.advanced(by: updated)
    }

    if self.isEmpty {
      precondition(
        source.isEmpty,
        "destination buffer view cannot contain every element from source."
      )
      return 0
    }

    var iterator = source.makeIterator()
    var index = 0
    while let value = iterator.next() {
      precondition(
        index < _count,
        "destination buffer view cannot contain every element from source."
      )
      self[unchecked: index] = value
      index &+= 1
    }
    return index
  }

  @_disallowFeatureSuppression(NonescapableTypes)
  @_alwaysEmitIntoClient
  public mutating func update(fromContentsOf source: Span<Element>) -> Int {
    guard !source.isEmpty else { return 0 }
    precondition(
      source.count <= self.count,
      "destination span cannot contain every element from source."
    )
    _start.withMemoryRebound(to: Element.self, capacity: source.count) { dest in
      source._start.withMemoryRebound(to: Element.self, capacity: source.count) {
        dest.update(from: $0, count: source.count)
      }
    }
    return source.count
  }

  @_disallowFeatureSuppression(NonescapableTypes)
  @_alwaysEmitIntoClient
  public mutating func update(
    fromContentsOf source: borrowing MutableSpan<Element>
  ) -> Int {
    source.withSpan { self.update(fromContentsOf: $0) }
  }
}

@_disallowFeatureSuppression(NonescapableTypes)
extension MutableSpan where Element: ~Copyable {

  @_disallowFeatureSuppression(NonescapableTypes)
  @_alwaysEmitIntoClient
  public mutating func moveUpdate(
    fromContentsOf source: consuming OutputSpan<Element>
  ) -> Int {
    guard !source.isEmpty else { return 0 }
    precondition(
      source.count <= self.count,
      "destination span cannot contain every element from source."
    )
    let buffer = source.relinquishBorrowedMemory()
    // we must now deinitialize the returned UMBP
    _start.moveInitializeMemory(
      as: Element.self, from: buffer.baseAddress!, count: buffer.count
    )
    return buffer.count
  }

  public mutating func moveUpdate(
    fromContentsOf source: UnsafeMutableBufferPointer<Element>
  ) -> Int {
#if false
    guard let sourceAddress = source.baseAddress, source.count > 0 else {
      return 0
    }
    precondition(
      source.count <= self.count,
      "destination span cannot contain every element from source."
    )
    _start.withMemoryRebound(to: Element.self, capacity: source.count) {
      $0.moveUpdate(from: sourceAddress, count: source.count)
    }
    return source.count
#else
    let source = OutputSpan(_initializing: source, initialized: source.count)
    return self.moveUpdate(fromContentsOf: source)
#endif
  }
}

@_disallowFeatureSuppression(NonescapableTypes)
extension MutableSpan {

  public mutating func moveUpdate(
    fromContentsOf source: Slice<UnsafeMutableBufferPointer<Element>>
  ) -> Int {
    self.moveUpdate(fromContentsOf: .init(rebasing: source))
  }
}


@_disallowFeatureSuppression(NonescapableTypes)
extension MutableSpan where Element: BitwiseCopyable {

  @_alwaysEmitIntoClient
  public mutating func update(
    repeating repeatedValue: Element
  ) where Element: BitwiseCopyable {
    guard count > 0 else { return }
    // rebind _start manually in order to avoid assumptions about alignment.
    let rp = _start._rawValue
    let binding = Builtin.bindMemory(rp, count._builtinWordValue, Element.self)
    UnsafeMutablePointer(rp).update(repeating: repeatedValue, count: count)
    Builtin.rebindMemory(rp, binding)
  }

  @_alwaysEmitIntoClient
  public mutating func update<S: Sequence>(
    from source: S
  ) -> (unwritten: S.Iterator, index: Int)
  where S.Element == Element, Element: BitwiseCopyable {
    var iterator = source.makeIterator()
    let index = update(from: &iterator)
    return (iterator, index)
  }

  @_alwaysEmitIntoClient
  public mutating func update(
    from elements: inout some IteratorProtocol<Element>
  ) -> Int {
    var index = 0
    while index < _count {
      guard let element = elements.next() else { break }
      self[unchecked: index] = element
      index &+= 1
    }
    return index
  }

  @_alwaysEmitIntoClient
  public mutating func update(
    fromContentsOf source: some Collection<Element>
  ) -> Int where Element: BitwiseCopyable {
    let updated = source.withContiguousStorageIfAvailable {
      self.update(fromContentsOf: Span(_unsafeElements: $0))
    }
    if let updated {
      return 0.advanced(by: updated)
    }

    if self.isEmpty {
      precondition(
        source.isEmpty,
        "destination buffer view cannot contain every element from source."
      )
      return 0
    }

    var iterator = source.makeIterator()
    var index = 0
    while let value = iterator.next() {
      guard index < _count else {
        fatalError(
          "destination buffer view cannot contain every element from source."
        )
      }
      self[unchecked: index] = value
      index &+= 1
    }
    return index
  }

  @_disallowFeatureSuppression(NonescapableTypes)
  @_alwaysEmitIntoClient
  public mutating func update(
    fromContentsOf source: Span<Element>
  ) -> Int where Element: BitwiseCopyable {
    guard !source.isEmpty else { return 0 }
    precondition(
      source.count <= self.count,
      "destination span cannot contain every element from source."
    )
    _start.copyMemory(
      from: source._start, byteCount: source.count&*MemoryLayout<Element>.stride
    )
    return source.count
  }

  @_disallowFeatureSuppression(NonescapableTypes)
  @_alwaysEmitIntoClient
  public mutating func update(
    fromContentsOf source: borrowing MutableSpan<Element>
  ) -> Int where Element: BitwiseCopyable {
    self.update(fromContentsOf: source.storage)
  }

  @_disallowFeatureSuppression(NonescapableTypes)
  @_alwaysEmitIntoClient
  @unsafe
  public mutating func update(
    fromContentsOf source: RawSpan
  ) -> Int where Element: BitwiseCopyable {
    self.update(fromContentsOf: source.unsafeView(as: Element.self))
  }

  // We have to define the overloads for raw buffers and their slices,
  // otherwise they would try to use their `Collection` conformance
  // and fail due to the mismatch in `Element` type.

  @_alwaysEmitIntoClient
  public mutating func update(
    fromContentsOf source: UnsafeRawBufferPointer
  ) -> Int where Element: BitwiseCopyable {
    self.update(fromContentsOf: RawSpan(_unsafeBytes: source))
  }

  @_alwaysEmitIntoClient
  public mutating func update(
    fromContentsOf source: UnsafeMutableRawBufferPointer
  ) -> Int where Element: BitwiseCopyable {
    self.update(fromContentsOf: RawSpan(_unsafeBytes: source))
  }

  @_alwaysEmitIntoClient
  public mutating func update(
    fromContentsOf source: Slice<UnsafeRawBufferPointer>
  ) -> Int where Element: BitwiseCopyable {
    self.update(fromContentsOf: RawSpan(_unsafeBytes: source))
  }

  @_alwaysEmitIntoClient
  public mutating func update(
    fromContentsOf source: Slice<UnsafeMutableRawBufferPointer>
  ) -> Int where Element: BitwiseCopyable {
    self.update(fromContentsOf: RawSpan(_unsafeBytes: source))
  }
}

//MARK: copyMemory
//FIXME: move these to a MutableRawSpan
@_disallowFeatureSuppression(NonescapableTypes)
extension MutableSpan where Element: BitwiseCopyable {

  @_disallowFeatureSuppression(NonescapableTypes)
  @_alwaysEmitIntoClient
  public mutating func copyMemory(
    from source: borrowing MutableSpan<Element>
  ) -> Int where Element: BitwiseCopyable {
    self.update(fromContentsOf: source.storage)
  }

  @_disallowFeatureSuppression(NonescapableTypes)
  @_alwaysEmitIntoClient
  public mutating func copyMemory(
    from source: Span<Element>
  ) -> Int where Element: BitwiseCopyable {
    self.update(fromContentsOf: source)
  }
}
