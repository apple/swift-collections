//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Collections open source project
//
// Copyright (c) 2024 - 2026 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
//
// SPDX-License-Identifier: Apache-2.0 WITH Swift-exception
//
//===----------------------------------------------------------------------===//


#if compiler(<6.2)

@available(*, unavailable, renamed: "UniqueBox", message: "struct UniqueBox requires a Swift 6.2 toolchain")
public typealias Box = UniqueBox

/// A wrapper type that forms a noncopyable, heap allocated box around an
/// arbitrary value.
///
/// This can be used to form a noncopyable, uniquely referenced box around any
/// Swift value.
@available(*, unavailable, message: "struct Box requires a Swift 6.2 toolchain")
@frozen
public struct UniqueBox<Value: ~Copyable>: ~Copyable {
  @available(*, deprecated, renamed: "Value")
  public typealias T = Value

  @usableFromInline
  internal let _pointer: UnsafeMutablePointer<T>

  @_alwaysEmitIntoClient
  @_transparent
  public init(_ value: consuming Value) {
    fatalError()
  }

  @_alwaysEmitIntoClient
  @inlinable
  deinit {
    fatalError()
  }
}

#else

@available(*, deprecated, renamed: "UniqueBox")
public typealias Box = UniqueBox

/// A wrapper type that forms a noncopyable, heap allocated box around an
/// arbitrary value.
///
/// This can be used to form a noncopyable, uniquely referenced box around any
/// Swift value.
@frozen
@safe
public struct UniqueBox<Value: ~Copyable>: ~Copyable {
  @available(*, deprecated, renamed: "Value")
  public typealias T = Value

  @usableFromInline
  internal let _pointer: UnsafeMutablePointer<Value>

  /// Initializes a value of this unique box with the given initial value.
  ///
  /// - Parameter initialValue: The initial value to initialize the unique box
  ///    with.
  @_alwaysEmitIntoClient
  @_transparent
  public init(_ initialValue: consuming Value) {
    unsafe _pointer = UnsafeMutablePointer<Value>.allocate(capacity: 1)
    unsafe _pointer.initialize(to: initialValue)
  }

  @_alwaysEmitIntoClient
  @inlinable
  deinit {
    unsafe _pointer.deinitialize(count: 1)
    unsafe _pointer.deallocate()
  }
}

extension UniqueBox: @unchecked Sendable where Value: Sendable & ~Copyable {}

extension UniqueBox where Value: ~Copyable {
#if compiler(>=6.4) && UnstableContainersPreview
  @_alwaysEmitIntoClient
  public var value: Value {
    @_transparent
    @_unsafeSelfDependentResult
    borrow {
      _pointer.pointee
    }

    @_transparent
    @_unsafeSelfDependentResult
    mutate {
      &_pointer.pointee
    }
  }
#else
  @_alwaysEmitIntoClient
  public var value: Value {
    @_transparent
    unsafeAddress {
      UnsafePointer(_pointer)
    }

    @_transparent
    unsafeMutableAddress {
      _pointer
    }
  }
#endif

  /// Dereference this box, accessing its contents in a borrowing or
  /// mutating way.
  @available(*, deprecated, renamed: "value")
  @_alwaysEmitIntoClient
  public subscript() -> Value {
    @_transparent
    unsafeAddress {
      unsafe UnsafePointer<Value>(_pointer)
    }

    @_transparent
    unsafeMutableAddress {
      unsafe _pointer
    }
  }
}

extension UniqueBox where Value: ~Copyable {
  /// Consumes the unique box and returns the instance of `Value` that was
  /// within the box.
  @_alwaysEmitIntoClient
  @_transparent
  public consuming func consume() -> Value {
    let result = unsafe _pointer.move()
    unsafe _pointer.deallocate()
    discard self
    return result
  }
}

extension UniqueBox where Value: ~Copyable {
  /// Return a single-item span over the contents of this box.
  @available(SwiftStdlib 5.0, *)
  public var span: Span<Value> {
    @_alwaysEmitIntoClient
    @_lifetime(borrow self)
    get {
      unsafe Span(_unsafeStart: _pointer, count: 1)
    }
  }

  /// Return a single-item mutable span over the contents of this box.
  @available(SwiftStdlib 5.0, *)
  public var mutableSpan: MutableSpan<Value> {
    @_alwaysEmitIntoClient
    @_lifetime(&self)
    mutating get {
      unsafe MutableSpan(_unsafeStart: _pointer, count: 1)
    }
  }
}

extension UniqueBox where Value: Copyable {
  @available(*, deprecated, renamed: "value")
  @_alwaysEmitIntoClient
  @_transparent
  public borrowing func copy() -> Value {
    value
  }

  /// Copies the value within the unqiue box and returns it in a new unique
  /// instance.
  @_alwaysEmitIntoClient
  @_transparent
  public borrowing func clone() -> Self {
    UniqueBox(value)
  }
}

extension UniqueBox where Value: ~Copyable {
#if compiler(>=6.3) && UnstableContainersPreview
  /// Leak the heap allocation behind this box, converting it into an
  /// immortal mutating reference.
  @_alwaysEmitIntoClient
  @_transparent
  @_lifetime(immortal)
  public consuming func leak() -> Inout<Value> {
    let result = unsafe Inout<Value>(unsafeImmortalAddress: _pointer)
    discard self
    return result
  }
#endif

#if UnstableContainersPreview
  /// Return a borrowing reference to the contents of this box.
  @available(SwiftStdlib 5.0, *)
  @_alwaysEmitIntoClient
  @_transparent
  @_lifetime(borrow self)
  public func borrow() -> Borrow<Value> {
    unsafe Borrow(unsafeAddress: UnsafePointer(_pointer), borrowing: self)
  }
#endif

#if compiler(>=6.3) && UnstableContainersPreview
  /// Return a mutating reference to the contents of this box.
  @_alwaysEmitIntoClient
  @_transparent
  @_lifetime(&self)
  public mutating func mutate() -> Inout<Value> {
    unsafe Inout(unsafeAddress: _pointer, mutating: &self)
  }
#endif
}

#endif
