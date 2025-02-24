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
    return extracting(unchecked: bounds)
  }

  @lifetime(borrow self)
  public mutating func extracting(unchecked bounds: Range<Index>) -> Self {
    let delta = bounds.lowerBound &* MemoryLayout<Element>.stride
    let newStart = _pointer?.advanced(by: delta)
    let newSpan = MutableSpan(_unchecked: newStart, count: bounds.count)
    return _overrideLifetime(newSpan, mutating: &self)
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
      return self[extractingUnchecked: bounds]
    }
  }

  public subscript(extractingUnchecked bounds: Range<Index>) -> Self {
    @lifetime(borrow self)
    mutating get {
      let delta = bounds.lowerBound &* MemoryLayout<Element>.stride
      let newStart = _pointer?.advanced(by: delta)
      let newSpan = MutableSpan(_unchecked: newStart, count: bounds.count)
      return _overrideLifetime(newSpan, mutating: &self)
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
      return UnsafePointer(base._unsafeAddressOfElement(unchecked: index))
    }
    unsafeMutableAddress {
      precondition(offset <= index && index < base.count)
      return base._unsafeAddressOfElement(unchecked: index)
    }
  }

  public var span: Span<Element> {
    @lifetime(borrow self)
    borrowing get {
      let delta = offset &* MemoryLayout<Element>.stride
      let newStart = base._pointer?.advanced(by: delta).assumingMemoryBound(to: Element.self)
      let buffer = UnsafeBufferPointer(start: newStart, count: count)
      let newSpan = Span(_unsafeElements: buffer)
      return _overrideLifetime(newSpan, borrowing: self)
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
      let prefixBuffer = UnsafeMutableBufferPointer<Element>(
        start: _start().assumingMemoryBound(to: Element.self),
        count: bounds.upperBound
      )
      let prefix = MutableSpan<Element>(_unsafeElements: prefixBuffer)
      var subSpan = SubMutableSpan<Element>(bounds.lowerBound, prefix)
      subSpan.offset = bounds.lowerBound
      return _overrideLifetime(subSpan, mutating: &self)
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
    let start = _start().advanced(by: bounds.lowerBound &* MemoryLayout<Element>.stride)
    start.withMemoryRebound(to: Element.self, capacity: bounds.count) {
      $0.update(repeating: repeatedValue, count: bounds.count)
    }
  }
}
