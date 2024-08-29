//===--- StdlibSpanExtensions.swift ---------------------------------------===//
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

extension UnsafeBufferPointer where Element: ~Copyable {
  public func withSpan<E: Error, Result: ~Copyable>(
    _ body: (_ elements: Span<Element>) throws(E) -> Result
  ) throws(E) -> Result {
    try body(Span(_unsafeElements: self))
  }

  public func withBytes<E: Error, Result: ~Copyable>(
    _ body: (_ elements: RawSpan) throws(E) -> Result
  ) throws(E) -> Result where Element: BitwiseCopyable {
    try body(RawSpan(_unsafeBytes: UnsafeRawBufferPointer(self)))
  }
}

extension UnsafeMutableBufferPointer where Element: ~Copyable {
  public func withSpan<E: Error, Result: ~Copyable>(
    _ body: (_ elements: Span<Element>) throws(E) -> Result
  ) throws(E) -> Result {
    try body(Span(_unsafeElements: self))
  }

  public func withBytes<E: Error, Result: ~Copyable>(
    _ body: (_ elements: RawSpan) throws(E) -> Result
  ) throws(E) -> Result where Element: BitwiseCopyable {
    try body(RawSpan(_unsafeBytes: UnsafeRawBufferPointer(self)))
  }
}

extension UnsafeRawBufferPointer {
  public func withBytes<E: Error, Result: ~Copyable>(
    _ body: (_ elements: RawSpan) throws(E) -> Result
  ) throws(E) -> Result {
    try body(RawSpan(_unsafeBytes: self))
  }
}

extension UnsafeMutableRawBufferPointer {
  public func withBytes<E: Error, Result: ~Copyable>(
    _ body: (_ elements: RawSpan) throws(E) -> Result
  ) throws(E) -> Result {
    try body(RawSpan(_unsafeBytes: self))
  }
}

extension Slice {
  public func withSpan<Element, E: Error, Result: ~Copyable>(
    _ body: (_ elements: Span<Element>) throws(E) -> Result
  ) throws(E) -> Result
  where Base == UnsafeBufferPointer<Element> {
    try body(Span(_unsafeElements: UnsafeBufferPointer(rebasing: self)))
  }

  public func withBytes<Element: BitwiseCopyable, E: Error, Result: ~Copyable>(
    _ body: (_ elements: RawSpan) throws(E) -> Result
  ) throws(E) -> Result
  where Base == UnsafeBufferPointer<Element> {
    try body(RawSpan(_unsafeBytes: .init(UnsafeBufferPointer(rebasing: self))))
  }

  public func withSpan<Element, E: Error, Result: ~Copyable>(
    _ body: (_ elements: Span<Element>) throws(E) -> Result
  ) throws(E) -> Result
  where Base == UnsafeMutableBufferPointer<Element> {
    try body(Span(_unsafeElements: UnsafeBufferPointer(rebasing: self)))
  }

  public func withBytes<Element: BitwiseCopyable, E: Error, Result: ~Copyable>(
    _ body: (_ elements: RawSpan) throws(E) -> Result
  ) throws(E) -> Result
  where Base == UnsafeMutableBufferPointer<Element> {
    try body(RawSpan(_unsafeBytes: .init(UnsafeBufferPointer(rebasing: self))))
  }

  public func withBytes<E: Error, Result: ~Copyable>(
    _ body: (_ elements: RawSpan) throws(E) -> Result
  ) throws(E) -> Result
  where Base == UnsafeRawBufferPointer {
    try body(RawSpan(_unsafeBytes: UnsafeRawBufferPointer(rebasing: self)))
  }

  public func withBytes<E: Error, Result: ~Copyable>(
    _ body: (_ elements: RawSpan) throws(E) -> Result
  ) throws(E) -> Result
  where Base == UnsafeMutableRawBufferPointer {
    try body(RawSpan(_unsafeBytes: UnsafeRawBufferPointer(rebasing: self)))
  }
}

#if false //FIXME: rdar://134382237
import struct Foundation.Data

extension Data {
  public func withSpan<E: Error, Result>(
    _ body: (_ elements: Span<UInt8>) throws(E) -> Result
  ) throws(E) -> Result {
    let result: Swift.Result<Result, E> = withUnsafeBytes {
      do throws(E) {
        return .success(try body(Span<UInt8>(_unsafeBytes: $0)))
      } catch {
        return .failure(error)
      }
    }
    switch result {
    case .success(let s): return s
    case .failure(let e): throw e
    }
  }

  public func withBytes<E: Error, Result>(
    _ body: (_ bytes: RawSpan) throws(E) -> Result
  ) throws(E) -> Result {
    let result: Swift.Result<Result, E> = withUnsafeBytes {
      do throws(E) {
        return .success(try body(RawSpan(_unsafeBytes: $0)))
      } catch {
        return .failure(error)
      }
    }
    switch result {
    case .success(let s): return s
    case .failure(let e): throw e
    }
  }
}
#endif

extension Array {

  /// Calls a closure with a `Span` of the array's contiguous storage.
  ///
  /// Often, the optimizer can eliminate bounds checks within an array
  /// algorithm, but when that fails, invoking the same algorithm on the
  /// buffer pointer passed into your closure lets you trade safety for speed.
  ///
  /// The following example shows how you can iterate over the contents of the
  /// buffer pointer:
  ///
  ///     let numbers = [1, 2, 3, 4, 5]
  ///     let sum = numbers.withUnsafeBufferPointer { buffer -> Int in
  ///         var result = 0
  ///         for i in stride(from: buffer.startIndex, to: buffer.endIndex, by: 2) {
  ///             result += buffer[i]
  ///         }
  ///         return result
  ///     }
  ///     // 'sum' == 9
  ///
  /// The pointer passed as an argument to `body` is valid only during the
  /// execution of `withUnsafeBufferPointer(_:)`. Do not store or return the
  /// pointer for later use.
  ///
  /// - Parameter body: A closure with an `UnsafeBufferPointer` parameter that
  ///   points to the contiguous storage for the array.  If no such storage exists, it is created. If
  ///   `body` has a return value, that value is also used as the return value
  ///   for the `withUnsafeBufferPointer(_:)` method. The pointer argument is
  ///   valid only for the duration of the method's execution.
  /// - Returns: The return value, if any, of the `body` closure parameter.
  public func withSpan<E: Error, Result: ~Copyable>(
    _ body: (_ elements:  Span<Element>) throws(E) -> Result
  ) throws(E) -> Result {
    let result = withUnsafeTemporaryAllocation(
        of: Swift.Result<Result, E>.self, capacity: 1
    ) {
      buffer -> Swift.Result<Result, E> in
      self.withUnsafeBufferPointer {
        elements in
        do throws(E) {
          let result = try body(Span(_unsafeElements: elements))
          buffer.initializeElement(at: 0, to: .success(result))
        } catch {
          buffer.initializeElement(at: 0, to: .failure(error))
        }
      }
      return buffer.moveElement(from: 0)
    }
    switch consume result {
    case .success(let s): return s
    case .failure(let e): throw e
    }
  }

  public func withBytes<E: Error, Result>(
    _ body: (_ bytes:  RawSpan) throws(E) -> Result
  ) throws(E) -> Result where Element: BitwiseCopyable {
    let result: Swift.Result<Result, E> = withUnsafeBytes {
      do throws(E) {
        return .success(try body(RawSpan(_unsafeBytes: $0)))
      } catch {
        return .failure(error)
      }
    }
    switch result {
    case .success(let s): return s
    case .failure(let e): throw e
    }
  }
}

extension ContiguousArray {
  public func withSpan<E: Error, Result>(
    _ body: (_ elements:  Span<Element>) throws(E) -> Result
  ) throws(E) -> Result {
    let result: Swift.Result<Result, E> = withUnsafeBufferPointer {
      do throws(E) {
        return .success(try body(Span(_unsafeElements: $0)))
      } catch {
        return .failure(error)
      }
    }
    switch result {
    case .success(let s): return s
    case .failure(let e): throw e
    }
  }
}

extension ContiguousArray where Element: BitwiseCopyable {
  public func withBytes<E: Error, Result>(
    _ body: (_ bytes:  RawSpan) throws(E) -> Result
  ) throws(E) -> Result {
    let result: Swift.Result<Result, E> = withUnsafeBytes {
      do throws(E) {
        return .success(try body(RawSpan(_unsafeBytes: $0)))
      } catch {
        return .failure(error)
      }
    }
    switch result {
    case .success(let s): return s
    case .failure(let e): throw e
    }
  }
}

extension ArraySlice {
  public func withSpan<E, Result>(
    _ body: (_ elements:  Span<Element>) throws(E) -> Result
  ) throws(E) -> Result {
    let result: Swift.Result<Result, E> = withUnsafeBufferPointer {
      do throws(E) {
        let span = Span(_unsafeElements: $0)
        print(span._start, span.count)
        return .success(try body(span))
      } catch {
        return .failure(error)
      }
    }
    switch result {
    case .success(let s): return s
    case .failure(let e): throw e
    }
  }
}

extension ArraySlice where Element: BitwiseCopyable {
  public func withBytes<E: Error, Result>(
    _ body: (_ bytes:  RawSpan) throws(E) -> Result
  ) throws(E) -> Result {
    let result: Swift.Result<Result, E> = withUnsafeBytes {
      do throws(E) {
        return .success(try body(RawSpan(_unsafeBytes: $0)))
      } catch {
        return .failure(error)
      }
    }
    switch result {
    case .success(let s): return s
    case .failure(let e): throw e
    }
  }
}

extension String.UTF8View {
  public func withSpan<E: Error, Result>(
    _ body: (_ elements:  Span<UTF8.CodeUnit>) throws(E) -> Result
  ) throws(E) -> Result {
    let result: Swift.Result<Result, E>? = withContiguousStorageIfAvailable {
      do throws(E) {
        return .success(try body(Span(_unsafeElements: $0)))
      } catch {
        return .failure(error)
      }
    }
    switch result {
    case .success(let s)?: return s
    case .failure(let e)?: throw e
    case nil: return try ContiguousArray(self).withSpan(body)
    }
  }

  public func withBytes<E: Error, Result>(
    _ body: (_ bytes:  RawSpan) throws(E) -> Result
  ) throws(E) -> Result {
    let result: Swift.Result<Result, E>? = withContiguousStorageIfAvailable {
      do throws(E) {
        return .success(try body(RawSpan(_unsafeElements: $0)))
      } catch {
        return .failure(error)
      }
    }
    switch result {
    case .success(let s)?: return s
    case .failure(let e)?: throw e
    case nil: return try ContiguousArray(self).withBytes(body)
    }
  }
}

extension Substring.UTF8View {
  public func withSpan<E: Error, Result>(
    _ body: (_ elements:  Span<UTF8.CodeUnit>) throws(E) -> Result
  ) throws(E) -> Result {
    let result: Swift.Result<Result, E>? = withContiguousStorageIfAvailable {
      do throws(E) {
        return .success(try body(Span(_unsafeElements: $0)))
      } catch {
        return .failure(error)
      }
    }
    switch result {
    case .success(let s)?: return s
    case .failure(let e)?: throw e
    case nil: return try ContiguousArray(self).withSpan(body)
    }
  }

  public func withBytes<E: Error, Result>(
    _ body: (_ bytes:  RawSpan) throws(E) -> Result
  ) throws(E) -> Result {
    let result: Swift.Result<Result, E>? = withContiguousStorageIfAvailable {
      do throws(E) {
        return .success(try body(RawSpan(_unsafeElements: $0)))
      } catch {
        return .failure(error)
      }
    }
    switch result {
    case .success(let s)?: return s
    case .failure(let e)?: throw e
    case nil: return try ContiguousArray(self).withBytes(body)
    }
  }
}

extension CollectionOfOne {
  public func withSpan<E: Error, Result>(
    _ body: (_ elements:  Span<Element>) throws(E) -> Result
  ) throws(E) -> Result {
    var collection = self
    let result: Swift.Result<Result, E> = withUnsafePointer(to: &collection) {
      $0.withMemoryRebound(to: Element.self, capacity: 1) {
        do throws(E) {
          return .success(try body(Span(_unsafeStart: $0, count: 1)))
        } catch {
          return .failure(error)
        }
      }
    }
    switch result {
    case .success(let s): return s
    case .failure(let e): throw e
    }
  }
}

extension CollectionOfOne where Element: BitwiseCopyable {
  public func withBytes<E: Error, Result>(
    _ body: (_ bytes:  RawSpan) throws(E) -> Result
  ) throws(E) -> Result {
    var collection = self
    let r: Swift.Result<Result, E> = Swift.withUnsafeBytes(of: &collection) {
      do throws(E) {
        return .success(try body(RawSpan(_unsafeBytes: $0)))
      } catch {
        return .failure(error)
      }
    }
    switch r {
    case .success(let s): return s
    case .failure(let e): throw e
    }
  }
}

extension KeyValuePairs {
  public func withSpan<E: Error, Result>(
    _ body: (
      _ elements:  Span<(key: Key, value: Value)>
    ) throws(E) -> Result
  ) throws(E) -> Result {
    try Array(self).withSpan(body)
  }
}

extension KeyValuePairs where Element: BitwiseCopyable {
  public func withBytes<E: Error, Result>(
    _ body: (_ bytes: RawSpan) throws(E) -> Result
  ) throws(E) -> Result {
    try Array(self).withBytes(body)
  }
}

extension Span where Element: ~Copyable /*& ~Escapable*/ {
  public consuming func withSpan<E: Error, Result>(
    _ body: (_ elements: Span<Element>) throws(E) -> Result
  ) throws(E) -> Result {
    try body(self)
  }
}

extension Span where Element: BitwiseCopyable {
  public consuming func withBytes<E: Error, Result>(
    _ body: (_ elements: RawSpan) throws(E) -> Result
  ) throws(E) -> Result {
    try body(RawSpan(self))
  }
}

//TODO: extend SIMD vectors with `withSpan` and with `withBytes`.
