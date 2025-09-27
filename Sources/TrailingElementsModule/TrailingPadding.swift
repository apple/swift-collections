//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Collections open source project
//
// Copyright (c) 2025 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
//
//===----------------------------------------------------------------------===//

/// Represents memory containing a header value followed by some extra padding
/// following it. Values of this type own the underlying memory, and are
/// non-copyable to ensure that ownership of that memory is unique. Memory
/// allocated for the storage will be deinitialized and freed when the
/// padded-storage instance is deinitialized.
///
/// The extra padding referenced by this value is allocated, but is otherwise
/// inaccessible except through unsafe pointer manipulation. This is intended
/// to be used in cases where a common header can have some extra storage
/// following it, but that storage is not describable using the type
/// system or is otherwise opaque to the user.
///
/// If the storage following the header is contiguous memory of some specific
/// type, whose count is computable from the header, use
/// `IntrusiveManagedPointer` instead.
@frozen
public struct TrailingPadding<Header: ~Copyable>: ~Copyable {
  /// Pointer to the header, followed by the padding.
  @usableFromInline
  let _pointer: UnsafeMutablePointer<Header>
  
  /// Create a new instance with the given header and total size. The total
  /// size includes the storage for the header itself, so it must be at least
  /// as large as the header.
  @_alwaysEmitIntoClient
  public init(header: consuming Header, totalSize size: Int) {
    precondition(size >= MemoryLayout<Header>.size,
                 "must allocate enough storage for the underlying stored type")
    _pointer = UnsafeMutableRawPointer
      .allocate(byteCount: size, alignment: MemoryLayout<Header>.alignment)
      .assumingMemoryBound(to: Header.self)
    _pointer.initialize(to: header)
  }
  
  /// Take ownership over a pointer to memory containing the header followed
  /// by the trailing elements.
  ///
  /// Once this padded storage is no longer used, this memory will be
  /// deinitialized and freed.
  @_alwaysEmitIntoClient
  public init(consuming pointer: UnsafeMutablePointer<Header>) {
    self._pointer = pointer
  }
  
  /// Deinitializes the header, then deallocates the underlying memory.
  @_alwaysEmitIntoClient
  deinit {
    _pointer.deinitialize(count: 1)
    _pointer.deallocate()
  }
  
  /// Access the header portion of the value.
  @_alwaysEmitIntoClient
  public var header: Header {
    unsafeAddress {
      UnsafePointer(_pointer)
    }
    
    unsafeMutableAddress {
      _pointer
    }
  }
  
  /// Executes the given closure with the pointer to the header itself.
  @_alwaysEmitIntoClient
  public func withUnsafeMutablePointerToHeader<R: ~Copyable, E>(
    _ body: (UnsafeMutablePointer<Header>) throws(E) -> R
  ) throws(E) -> R {
    return try body(_pointer)
  }
  
  /// Take ownership over the stored memory, returning its pointer. The
  /// underlying storage will not be freed by the `TrailingPadding` instance,
  /// as it is the responsibility of the caller.
  @_alwaysEmitIntoClient
  public consuming func leakStorage() -> UnsafeMutablePointer<Header> {
    let pointer = self._pointer
    discard self
    return pointer
  }
}

extension TrailingPadding: @unchecked Sendable
where Header: Sendable, Header: ~Copyable { }

extension TrailingPadding where Header: Copyable {
  /// Create a temporary for the given header with additional storage,
  /// providing that instance to the given `body` to operate on for the
  /// duration. The temporary is allocated on the stack (unless it is very
  /// large), eliminating the need for heap allocation of variable-size
  /// values.
  @_alwaysEmitIntoClient
  public static func withTemporaryValue<R: ~Copyable, E>(
    header: Header,
    totalSize size: Int,
    body: (inout TrailingPadding<Header>) throws(E) -> R
  ) throws(E) -> R {
    precondition(size >= MemoryLayout<Header>.size,
                 "must allocate enough storage for the underlying stored type")
    
    // Allocate temporary storage large enough for the value we need.
    let result: Result<R, E> = withUnsafeTemporaryAllocation(
      byteCount: size,
      alignment: MemoryLayout<Header>.alignment
    ) { buffer in
      /// Create a tail-allocated storage over that temporary storage.
      let pointer = buffer.baseAddress!.assumingMemoryBound(to: Header.self)
      pointer.initialize(to: header)
      var tailAllocated = TrailingPadding(consuming: pointer)
      
      do throws(E) {
        let result = try body(&tailAllocated)
        
        // Tell the tail-allocated buffer not to free the storage.
        let finalPointer = tailAllocated.leakStorage()
        precondition(finalPointer == pointer)
        
        return .success(result)
      } catch {
        // Tell the tail-allocated buffer not to free the storage.
        let finalPointer = tailAllocated.leakStorage()
        precondition(finalPointer == pointer)
        
        return .failure(error)
      }
    }
    
    return try result.get()
  }
}
