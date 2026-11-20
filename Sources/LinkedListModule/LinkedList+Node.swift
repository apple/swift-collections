//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Collections open source project
//
// Copyright (c) 2026 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
//
// SPDX-License-Identifier: Apache-2.0 WITH Swift-exception
//
//===----------------------------------------------------------------------===//

#if !COLLECTIONS_SINGLE_MODULE
import InternalCollectionsUtilities
import SpanPreview
#endif

#if compiler(>=6.4)

@available(SwiftStdlib 6.4, *)
extension LinkedList where Element: ~Copyable {
  @safe
  @usableFromInline
  @frozen
  @_addressableForDependencies
  package struct _Node: ~Copyable {
    @usableFromInline
    package var next: UnsafeMutablePointer<_Node>?

    // FIXME: This _really_ should not be optional; but we can't decompose
    // noncopyable structs, so that would make it impossible to remove
    // an element from a list.
    @usableFromInline
    package var _value: Element?

    @_alwaysEmitIntoClient
    @_transparent
    package init(
      _ value: consuming Element,
      next: UnsafeMutablePointer<_Node>? = nil
    ) {
      unsafe self.next = next
      self._value = consume value
    }

    deinit {
      unsafe _dismantleList(self.next)
    }
  }
}

@available(SwiftStdlib 6.4, *)
extension LinkedList._Node where Element: ~Copyable {
  @_alwaysEmitIntoClient
  package static func allocate(
    _ value: consuming Element,
    next: UnsafeMutablePointer<Self>? = nil
  ) -> UnsafeMutablePointer<Self> {
    let new = UnsafeMutablePointer<Self>.allocate(capacity: 1)
    unsafe new.initialize(to: Self(value, next: next))
    return unsafe new
  }

  @_alwaysEmitIntoClient
  package var span: Span<Element> {
    @_transparent
    @_lifetime(borrow self)
    get {
      _value._span
    }
  }

  @_alwaysEmitIntoClient
  package var mutableSpan: MutableSpan<Element> {
    @_transparent
    @_lifetime(&self)
    mutating get {
      _value._mutableSpan
    }
  }

  @_alwaysEmitIntoClient
  @_transparent
  package consuming func deconstruct() -> Element {
    unsafe assert(next == nil)
    return self._value.take()._consumingUnsafelyUnwrap()
  }

  @_alwaysEmitIntoClient
  @unsafe
  package static var _valueOffset: Int {
    // FIXME: This is quite bad; we have to assume that the struct and its
    // optional `_value` property are laid out in this particular way.
    assert(MemoryLayout<Self>.alignment >= MemoryLayout<Element>.alignment)
    return Swift.max(MemoryLayout<Int>.stride, MemoryLayout<Element>.alignment)
  }

  @_alwaysEmitIntoClient
  @unsafe
  package static func _ptrToValue(
    in node: UnsafeMutablePointer<Self>
  ) -> UnsafeMutablePointer<Element> {
    // FIXME: This is quite bad; we have to assume that the struct and its
    // optional `_value` property are laid out in this particular way.
    unsafe UnsafeMutableRawPointer(node)
      .advanced(by: _valueOffset)
      .assumingMemoryBound(to: Element.self)
  }
}

@available(SwiftStdlib 6.4, *)
extension UnsafeMutablePointer where Pointee: ~Copyable {
  @_alwaysEmitIntoClient
  @_lifetime(&owner)
  package func _mutableValue<
    Element: ~Copyable, T: ~Copyable & ~Escapable
  >(
    mutating owner: inout T
  ) -> MutableSpan<Element>
  where Pointee == LinkedList<Element>._Node {
    // Return a MutableSpan over the stored property holding the element in
    // the addressed node. There appears to be no way to do this safely in
    // Swift 6.5, so we drop down to direct pointer offsetting. (Hopefully
    // this doesn't break the memory model too much.)
    unsafe assert(pointee.next == nil)
    let ptr = unsafe LinkedList._Node._ptrToValue(in: self)
    let span = unsafe MutableSpan(_unsafeElements: .init(start: ptr, count: 1))
    return unsafe _overrideLifetime(span, mutating: &owner)
  }

#if UnstableContainersPreview
  @_alwaysEmitIntoClient
  @_lifetime(&owner)
  package func _drainOrphanNode<
    Element: ~Copyable, T: ~Copyable & ~Escapable
  >(
    mutating owner: inout T
  ) -> InputSpan<Element>
  where Pointee == LinkedList<Element>._Node {
    // Return an InputSpan over the stored property holding the element in
    // the addressed node. There is no way to do this safely in Swift 6.5, so we
    // drop down to direct pointer offsetting. (Hopefully this doesn't break the
    // memory model too much.)
    unsafe assert(pointee.next == nil)
    let ptr = unsafe LinkedList._Node._ptrToValue(in: self)
    let span = unsafe InputSpan(
      _uncheckedBuffer: .init(start: ptr, count: 1),
      initializedCount: 1)
    return unsafe _overrideLifetime(span, mutating: &owner)
  }
#endif
}

#endif
