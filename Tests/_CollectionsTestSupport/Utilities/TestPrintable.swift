//===----------------------------------------------------------------------===//
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

#if COLLECTIONS_SINGLE_MODULE
import Collections
#else
import ContainersPreview
#endif

#if compiler(>=6.2)
/// A silly variant of `CustomDebugStringConvertible` that supports noncopyable
/// and nonescapable conforming types.
///
/// This is expected to be replaced by the stdlib's solution, once we have one.
/// (It can be as simple as generalizing the standard protocol, but for it serve
/// its purpose, we also need to be able to perform runtime conformance checks
/// on noncopyable/nonescapable entities (or otherwise detect and invoke this
/// property. Additionally, materializing a full `String` instance up front can
/// be too expensive in some environments -- we also need a solution that
/// streams descriptions into some caller-provided buffer, eliminating
/// memory overhead.)
public protocol TestPrintable: ~Copyable, ~Escapable {
  var testDescription: String { get }
}

extension _Pointer {
  internal var _description: String {
    let hex = String(UInt(bitPattern: self), radix: 16)
    let len = MemoryLayout<Self>.size * 2
    return "0x" + String(repeating: "0", count: len - hex.count) + hex
  }
}

internal func _bufferDescription<P: _Pointer>(
  _ typename: String, start: P?, count: Int
) -> String {
  "\(typename)(start: \(start?._description ?? "nil"), count: \(count))"
}

extension UnsafeRawBufferPointer: TestPrintable {
  public var testDescription: String {
    _bufferDescription(
      "UnsafeRawBufferPointer", start: baseAddress, count: count)
  }
}
extension UnsafeMutableRawBufferPointer: TestPrintable {
  public var testDescription: String {
    _bufferDescription(
      "UnsafeMutableRawBufferPointer", start: baseAddress, count: count)
  }
}
extension UnsafeBufferPointer: TestPrintable
where Element: ~Copyable
{
  public var testDescription: String {
    _bufferDescription("UnsafeBufferPointer", start: baseAddress, count: count)
  }
}
extension UnsafeMutableBufferPointer: TestPrintable
where Element: ~Copyable
{
  public var testDescription: String {
    _bufferDescription(
      "UnsafeMutableBufferPointer", start: baseAddress, count: count)
  }
}

@available(SwiftStdlib 5.0, *)
extension Span: TestPrintable where Element: ~Copyable {
  public var testDescription: String {
    self.withUnsafeBufferPointer { buffer in
      _bufferDescription("Span", start: buffer.baseAddress, count: buffer.count)
    }
  }
}
@available(SwiftStdlib 5.0, *)
extension MutableSpan: TestPrintable where Element: ~Copyable  {
  public var testDescription: String {
    self.withUnsafeBufferPointer { buffer in
      _bufferDescription("MutableSpan", start: buffer.baseAddress, count: buffer.count)
    }
  }
}
#if compiler(>=6.2)
@available(SwiftStdlib 5.0, *)
extension OutputSpan: TestPrintable where Element: ~Copyable  {
  public var testDescription: String {
    let capacity = self.capacity
    return self.span.withUnsafeBufferPointer { buffer in
      """
      OutputSpan(\
      start: \(buffer.baseAddress?._description ?? "nil"), \
      capacity: \(capacity), \
      count: \(buffer.count))
      """
    }
  }
}
#endif

#if COLLECTIONS_UNSTABLE_CONTAINERS_PREVIEW
@available(SwiftStdlib 5.0, *)
extension InputSpan: TestPrintable where Element: ~Copyable  {
  public var testDescription: String {
    let capacity = self.capacity
    return self.span.withUnsafeBufferPointer { buffer in
      """
      InputSpan(\
      start: \(buffer.baseAddress?._description ?? "nil"), \
      capacity: \(capacity), \
      count: \(buffer.count))
      """
    }
  }
}
#endif
#endif
