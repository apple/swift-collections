//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Collections open source project
//
// Copyright (c) 2024 - 2025 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
//
//===----------------------------------------------------------------------===//

#if compiler(<6.2)

/// A wrapper type that forms a noncopyable, heap allocated box around an
/// arbitrary value.
///
/// This can be used to form a noncopyable, uniquely referenced box around any
/// Swift value.
@available(*, unavailable, message: "struct Box requires a Swift 6.2 toolchain")
@frozen
public struct Box<T: ~Copyable>: ~Copyable {
  @usableFromInline
  internal let _pointer: UnsafeMutablePointer<T>

  @_alwaysEmitIntoClient
  @_transparent
  public init(_ value: consuming T) {
    fatalError()
  }

  @_alwaysEmitIntoClient
  @inlinable
  deinit {
    fatalError()
  }
}

#else
/// A wrapper type that forms a noncopyable, heap allocated box around an
/// arbitrary value.
///
/// This can be used to form a noncopyable, uniquely referenced box around any
/// Swift value.
@frozen
@safe
public struct Box<T: ~Copyable>: ~Copyable {
  @usableFromInline
  internal let _pointer: UnsafeMutablePointer<T>

  @_alwaysEmitIntoClient
  @_transparent
  public init(_ value: consuming T) {
    unsafe _pointer = UnsafeMutablePointer<T>.allocate(capacity: 1)
    unsafe _pointer.initialize(to: value)
  }

  @_alwaysEmitIntoClient
  @inlinable
  deinit {
    unsafe _pointer.deinitialize(count: 1)
    unsafe _pointer.deallocate()
  }
}

extension Box where T: ~Copyable {
  /// Dereference this box, accessing its contents in a borrowing or
  /// mutating way.
  @_alwaysEmitIntoClient
  public subscript() -> T {
    @_transparent
    unsafeAddress {
      unsafe UnsafePointer<T>(_pointer)
    }

    @_transparent
    unsafeMutableAddress {
      unsafe _pointer
    }
  }

  /// Open and destroy this box, returning its contents.
  @_alwaysEmitIntoClient
  @_transparent
  public consuming func consume() -> T {
    let result = unsafe _pointer.move()
    unsafe _pointer.deallocate()
    discard self
    return result
  }

#if COLLECTIONS_UNSTABLE_CONTAINERS_PREVIEW
  /// Leak the heap allocation behind this box, converting it into an
  /// immortal mutating reference.
  @_alwaysEmitIntoClient
  @_transparent
  @_lifetime(immortal)
  public consuming func leak() -> Mut<T> {
    let result = unsafe Mut<T>(unsafeImmortalAddress: _pointer)
    discard self
    return result
  }
#endif

#if COLLECTIONS_UNSTABLE_CONTAINERS_PREVIEW
  /// Return a borrowing reference to the contents of this box.
  @_alwaysEmitIntoClient
  @_transparent
  @_lifetime(borrow self)
  public func borrow() -> Ref<T> {
    unsafe Ref(unsafeAddress: UnsafePointer(_pointer), borrowing: self)
  }
#endif

#if COLLECTIONS_UNSTABLE_CONTAINERS_PREVIEW
  /// Return a mutating reference to the contents of this box.
  @_alwaysEmitIntoClient
  @_transparent
  @_lifetime(&self)
  public mutating func mutate() -> Mut<T> {
    unsafe Mut(unsafeAddress: _pointer, mutating: &self)
  }
#endif
}

extension Box where T: Copyable {
  /// Copy the contents of this box, returning it.
  @_alwaysEmitIntoClient
  @_transparent
  public borrowing func copy() -> T {
    unsafe _pointer.pointee
  }
}

extension Box where T: ~Copyable {
  /// Return a single-item span over the contents of this box.
  @available(SwiftStdlib 5.0, *)
  public var span: Span<T> {
    @_alwaysEmitIntoClient
    @_lifetime(borrow self)
    get {
      unsafe Span(_unsafeStart: _pointer, count: 1)
    }
  }

  /// Return a single-item mutable span over the contents of this box.
  @available(SwiftStdlib 5.0, *)
  public var mutableSpan: MutableSpan<T> {
    @_alwaysEmitIntoClient
    @_lifetime(&self)
    mutating get {
      unsafe MutableSpan(_unsafeStart: _pointer, count: 1)
    }
  }
}
#endif
