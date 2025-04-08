//===--- MutableSpanSlicing.swift -----------------------------------------===//
//
// This source file is part of the Swift.org open source project
//
// Copyright (c) 2025 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
// See https://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//
//===----------------------------------------------------------------------===//

//MARK: Option 1 extracting() function
@available(macOS 9999, *)
extension MutableSpan where Element: ~Copyable {

  @lifetime(borrow self)
  public mutating func extracting(_ bounds: Range<Index>) -> Self {
    precondition(
      UInt(bitPattern: bounds.lowerBound) <= UInt(bitPattern: _count) &&
      UInt(bitPattern: bounds.upperBound) <= UInt(bitPattern: _count),
      "Index range out of bounds"
    )
    let newSpan = MutableSpan(_unchecked: _start(), uncheckedBounds: bounds)
    return unsafe _overrideLifetime(newSpan, mutating: &self)
  }
}

@available(macOS 9999, *)
extension MutableSpan where Element: ~Copyable {
  @_alwaysEmitIntoClient
  @lifetime(borrow pointer)
  fileprivate init(
    _unchecked pointer: UnsafeMutableRawPointer,
    uncheckedBounds bounds: Range<Index>
  ) {
    let delta = bounds.lowerBound &* MemoryLayout<Element>.stride
    let newStart = unsafe pointer.advanced(by: delta)
    let newSpan = Self(
      _unchecked: newStart, count: bounds.upperBound &- bounds.lowerBound
    )
    self = unsafe _overrideLifetime(newSpan, borrowing: pointer)
  }
}

@available(macOS 9999, *)
extension Span where Element: ~Copyable {
  @_alwaysEmitIntoClient
  @lifetime(borrow pointer)
  fileprivate init(
    _unchecked pointer: UnsafeMutableRawPointer,
    uncheckedBounds bounds: Range<Index>
  ) {
    let mut = MutableSpan<Element>(_unchecked: pointer, uncheckedBounds: bounds)
    let newSpan = mut.span
    self = unsafe _overrideLifetime(newSpan, borrowing: pointer)
  }
}

//MARK: Option 2 extracting subscript
@available(macOS 9999, *)
extension MutableSpan where Element: ~Copyable {

  public subscript(extracting bounds: Range<Index>) -> Self {
    @lifetime(borrow self)
    mutating get {
      precondition(
        UInt(bitPattern: bounds.lowerBound) <= UInt(bitPattern: _count) &&
        UInt(bitPattern: bounds.upperBound) <= UInt(bitPattern: _count),
        "Index range out of bounds"
      )
      let newSpan = MutableSpan(_unchecked: _start(), uncheckedBounds: bounds)
      return unsafe _overrideLifetime(newSpan, mutating: &self)
    }
  }
}

//MARK: Option 3 specific slicing wrapper type
@available(macOS 9999, *)
public struct SubMutableSpan<Element: ~Copyable & ~Escapable>
: ~Copyable, ~Escapable {
  public typealias Index = MutableSpan<Element>.Index

  public fileprivate(set) var offset: MutableSpan<Element>.Index
  public /*exclusive*/ var base: MutableSpan<Element>

  init(_ _offset: Index, _ _base: consuming MutableSpan<Element>) {
    offset = _offset
    base = _base
  }

  public var count: Int { base.count - offset }
}

@available(macOS 9999, *)
extension SubMutableSpan where Element: ~Copyable {

  public subscript (index: Index) -> Element {
    unsafeAddress {
      precondition(offset <= index && index < base.count)
      return unsafe UnsafePointer(base._unsafeAddressOfElement(unchecked: index))
    }
    unsafeMutableAddress {
      precondition(offset <= index && index < base.count)
      return unsafe base._unsafeAddressOfElement(unchecked: index)
    }
  }

  public var span: Span<Element> {
    @lifetime(borrow self)
    borrowing get {
      let newSpan = Span<Element>(
        _unchecked: base._start(), uncheckedBounds: offset..<base.count
      )
      return unsafe _overrideLifetime(newSpan, borrowing: self)
    }
  }
}

@available(macOS 9999, *)
extension SubMutableSpan {
  public mutating func update(repeating repeatedValue: consuming Element) {
    base.update(repeating: repeatedValue)
  }
}

@available(macOS 9999, *)
extension MutableSpan where Element: ~Copyable {

  public subscript(slicing bounds: Range<Index>) -> SubMutableSpan<Element> {
    @lifetime(borrow self)
    mutating get {
      precondition(
        UInt(bitPattern: bounds.lowerBound) <= UInt(bitPattern: _count) &&
        UInt(bitPattern: bounds.upperBound) <= UInt(bitPattern: _count),
        "Index range out of bounds"
      )
      let prefix = Self(
        _unchecked: _start(), uncheckedBounds: 0..<bounds.upperBound
      )
      let subSpan = SubMutableSpan<Element>(bounds.lowerBound, prefix)
      return unsafe _overrideLifetime(subSpan, mutating: &self)
    }
  }
}

//MARK: Option 4 range parameters to bulk mutation functions
@available(macOS 9999, *)
extension MutableSpan where Element: Copyable {

  public mutating func update(
    in bounds: Range<Index>,
    repeating repeatedValue: consuming Element
  ) {
    precondition(
      UInt(bitPattern: bounds.lowerBound) <= UInt(bitPattern: _count) &&
      UInt(bitPattern: bounds.upperBound) <= UInt(bitPattern: _count),
      "Index range out of bounds"
    )
    let start = unsafe _start() + bounds.lowerBound &* MemoryLayout<Element>.stride
    unsafe start.withMemoryRebound(to: Element.self, capacity: bounds.count) {
      unsafe $0.update(repeating: repeatedValue, count: bounds.count)
    }
  }
}
