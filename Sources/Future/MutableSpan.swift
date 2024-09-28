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
  @usableFromInline let _pointer: UnsafeMutablePointer<Element>?

  @usableFromInline let _count: Int

  @usableFromInline @inline(__always)
  var _start: UnsafeMutablePointer<Element> { _pointer.unsafelyUnwrapped }

  @_disallowFeatureSuppression(NonescapableTypes)
  @usableFromInline @inline(__always)
  init(
    _unchecked start: UnsafeMutablePointer<Element>?,
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
      buffer.count == 0 ||
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

//TODO: initializers where Element: BitwiseCopyable

//extension MutableSpan /*where Element: BitwiseCopyable*/ {
//
//  public init<Owner>( //FIXME: should be failable
//    unsafeMutableRawBufferPointer buffer: UnsafeMutableRawBufferPointer,
//    dependsOn owner: borrowing Owner
//  ) {
//    guard _isPOD(Element.self) else { fatalError() }
//    guard let p = buffer.baseAddress else { /*return nil*/ fatalError() }
//    let (q, r) = buffer.count.quotientAndRemainder(dividingBy: MemoryLayout<Element>.stride)
//    precondition(r == 0)
//    self.init(unsafeMutablePointer: p.assumingMemoryBound(to: Element.self), count: q, dependsOn: owner)
//  }
//}

//MARK: Sequence

//extension MutableSpan /*: Sequence */ {
//
//  public func makeIterator() -> SpanIterator<Element> {
//    .init(from: 0, to: _count, dependsOn: /* self */ baseAddress)
//  }
//
//  //FIXME: mark closure parameter as non-escaping
//  public func withContiguousStorageIfAvailable<R>(
//    _ body: (UnsafeBufferPointer<Element>) throws -> R
//  ) rethrows -> R? {
//    try Span(self).withContiguousStorageIfAvailable(body)
//  }
//}

@_disallowFeatureSuppression(NonescapableTypes)
extension Span where Element: ~Copyable {

  @_disallowFeatureSuppression(NonescapableTypes)
  @_alwaysEmitIntoClient
  public init(_ mutableSpan: borrowing MutableSpan<Element>) {
    self.init(_unchecked: mutableSpan._start, count: mutableSpan.count)
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
    _elementsEqual(Span(other))
  }

  @_disallowFeatureSuppression(NonescapableTypes)
  @_alwaysEmitIntoClient
  public func _elementsEqual(_ other: Span<Element>) -> Bool {
    Span(self)._elementsEqual(other)
  }

  @_disallowFeatureSuppression(NonescapableTypes)
  @_alwaysEmitIntoClient
  public func _elementsEqual(_ other: some Collection<Element>) -> Bool {
    Span(self)._elementsEqual(other)
  }

  @_disallowFeatureSuppression(NonescapableTypes)
  @_alwaysEmitIntoClient
  public func _elementsEqual(_ other: some Sequence<Element>) -> Bool {
    Span(self)._elementsEqual(other)
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
  public var _unsafeRawSpan: RawSpan { Span(self)._unsafeRawSpan }
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
      precondition(boundsContain(position))
      yield self[unchecked: position]
    }
    _modify {
      precondition(boundsContain(position))
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
      let stride = MemoryLayout<Element>.stride
      let p = _start.advanced(by: position&*stride)._rawValue
      let binding = Builtin.bindMemory(p, count._builtinWordValue, Element.self)
      defer { Builtin.rebindMemory(p, binding) }
      yield UnsafePointer(p).pointee
    }
    _modify {
      let stride = MemoryLayout<Element>.stride
      let p = _start.advanced(by: position&*stride)._rawValue
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
      return UnsafeRawPointer(_start).loadUnaligned(fromByteOffset: offset, as: Element.self)
    }
    set {
      let offset = position&*MemoryLayout<Element>.stride
      UnsafeMutableRawPointer(_start)
        .storeBytes(of: newValue, toByteOffset: offset, as: Element.self)
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
    try Span(self).withUnsafeBufferPointer(body)
  }

  //FIXME: mark closure parameter as non-escaping
  @_disallowFeatureSuppression(NonescapableTypes)
  @_alwaysEmitIntoClient
  public func withUnsafeMutableBufferPointer<E: Error, Result: ~Copyable>(
    _ body: (inout UnsafeMutableBufferPointer<Element>) throws(E) -> Result
  ) throws(E) -> Result {
    guard let pointer = _pointer, count > 0 else {
      var buffer = UnsafeMutableBufferPointer<Element>(start: nil, count: 0)
      return try body(&buffer)
    }
    return try pointer.withMemoryRebound(to: Element.self, capacity: count) {
      ptr throws(E) -> Result in
      var buf = UnsafeMutableBufferPointer<Element>(start: ptr, count: count)
      defer {
        precondition(
          (buf.baseAddress, buf.count) == (ptr, count),
          "MutableSpan.withUnsafeMutableBufferPointer: replacing the buffer is not allowed"
        )
      }
      return try body(&buf)
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
  public func withUnsafeMutableBytes<E: Error, Result: ~Copyable>(
    _ body: (_ buffer: UnsafeMutableRawBufferPointer) throws(E) -> Result
  ) throws(E) -> Result {
    let bytes = UnsafeMutableRawBufferPointer(
      start: (_count == 0) ? nil : UnsafeMutableRawPointer(_start),
      count: _count &* MemoryLayout<Element>.stride
    )
    return try body(bytes)
  }
}

//MARK: UMBP-style update functions
extension MutableSpan {

  public func update(repeating repeatedValue: Element) {
    _start.withMemoryRebound(to: Element.self, capacity: count) {
      $0.update(repeating: repeatedValue, count: count)
    }
  }

  public mutating func update<S: Sequence>(
    from source: S
  ) -> (unwritten: S.Iterator, index: Int) where S.Element == Element {
    var iterator = source.makeIterator()
    guard !self.isEmpty else { return (iterator, 0) }
    var index = 0
    while index < _count {
      guard let value = iterator.next() else { break }
      self[unchecked: index] = value
      index &+= 1
    }
    return (iterator, index)
  }

  public mutating func update(fromContentsOf source: some Collection<Element>) -> Int {
    let updated = source.withContiguousStorageIfAvailable {
      [ count = self.count, baseAddress = self._start ] sourceBuffer in
      guard let sourceAddress = sourceBuffer.baseAddress else {
        return 0
      }
      precondition(
        sourceBuffer.count <= count,
        "destination buffer view cannot contain every element from source."
      )
      baseAddress.withMemoryRebound(to: Element.self, capacity: sourceBuffer.count) {
        $0.update(from: sourceAddress, count: sourceBuffer.count)
      }
      return sourceBuffer.count
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
        preconditionFailure(
          "destination buffer view cannot contain every element from source."
        )
        break
      }
      self[unchecked: index] = value
      index &+= 1
    }
    return index
  }
}

extension MutableSpan where Element: Copyable {

  public mutating func update(fromContentsOf source: Span<Element>) -> Int {
    return 0
  }

  public mutating func update(fromContentsOf source: borrowing MutableSpan<Element>) -> Int {
    return 0
  }

  public mutating func update(fromContentsOf source: UnsafeBufferPointer<Element>) -> Int {
    return 0
  }

  public mutating func update(fromContentsOf source: UnsafeMutableBufferPointer<Element>) -> Int {
    return 0
  }

  public mutating func update(fromContentsOf source: Slice<UnsafeBufferPointer<Element>>) -> Int {
    return 0
  }

  public mutating func update(fromContentsOf source: Slice<UnsafeMutableBufferPointer<Element>>) -> Int {
    return 0
  }
}

extension MutableSpan where Element: ~Copyable {

  public mutating func moveUpdate(fromContentsOf source: UnsafeMutableBufferPointer<Element>) -> Int {
    return 0
  }
}

extension MutableSpan where Element: BitwiseCopyable {
  //TODO: overload the various `update` functions to use memcpy

  public mutating func update(fromContentsOf source: some Collection<Element>) -> Int {
    return 0
  }

  public mutating func update(fromContentsOf source: Span<Element>) -> Int {
    return 0
  }

  public mutating func update(fromContentsOf source: borrowing MutableSpan<Element>) -> Int {
    return 0
  }

  public mutating func update(fromContentsOf source: UnsafeBufferPointer<Element>) -> Int {
    return 0
  }

  public mutating func update(fromContentsOf source: UnsafeMutableBufferPointer<Element>) -> Int {
    return 0
  }

  public mutating func update(fromContentsOf source: Slice<UnsafeBufferPointer<Element>>) -> Int {
    return 0
  }

  public mutating func update(fromContentsOf source: Slice<UnsafeMutableBufferPointer<Element>>) -> Int {
    return 0
  }

  public mutating func moveUpdate(fromContentsOf source: UnsafeMutableBufferPointer<Element>) -> Int {
    return 0
  }

  public mutating func moveUpdate(fromContentsOf source: Slice<UnsafeMutableBufferPointer<Element>>) -> Int {
    return 0
  }
}

//MARK: copyMemory
//FIXME: move these to a MutableRawSpan
extension MutableSpan where Element: BitwiseCopyable {

  @_alwaysEmitIntoClient
  public func copyMemory(
    from source: borrowing MutableSpan<Element>
  ) -> Int {
    guard _isPOD(Element.self) else { fatalError() }
    return copyMemory(from: .init(source))
  }

  public func copyMemory(from source: Span<Element>) -> Int {
    guard _isPOD(Element.self) else { fatalError() }
    precondition(
      source.count <= count,
      "MutableSpan.copyMemory source has too many elements"
    )
    UnsafeMutableRawPointer(_start).copyMemory(
      from: source._start,
      byteCount: source.count&*MemoryLayout<Element>.stride
    )
    return 0.advanced(by: source.count)
  }
}
