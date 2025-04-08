//===--- StdlibOutputSpanExtensions.swift ---------------------------------===//
//
// This source file is part of the Swift.org open source project
//
// Copyright (c) 2024 - 2025 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
// See https://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//
//===----------------------------------------------------------------------===//

extension Array {

  @available(macOS 9999, *)
  public init(
    capacity: Int,
    initializingWith initializer: (inout OutputSpan<Element>) throws -> Void
  ) rethrows {
    try unsafe self.init(
      unsafeUninitializedCapacity: capacity,
      initializingWith: { (buffer, count) in
        let pointer = unsafe buffer.baseAddress.unsafelyUnwrapped
        var output = OutputSpan<Element>(
          _initializing: pointer, capacity: buffer.count
        )
        try initializer(&output)
        let initialized = unsafe output.relinquishBorrowedMemory()
        unsafe assert(initialized.baseAddress == buffer.baseAddress)
        count = initialized.count
      }
    )
  }
}

extension String {

  // also see https://github.com/apple/swift/pull/23050
  // and `final class __SharedStringStorage`

  @available(macOS 9999, *)
  public init(
    utf8Capacity capacity: Int,
    initializingWith initializer: (inout OutputSpan<UTF8.CodeUnit>) throws -> Void
  ) rethrows {
    try unsafe self.init(
      unsafeUninitializedCapacity: capacity,
      initializingUTF8With: { buffer in
        let pointer = unsafe buffer.baseAddress.unsafelyUnwrapped
        var output = OutputSpan<UTF8.CodeUnit>(
          _initializing: pointer, capacity: buffer.count
        )
        try initializer(&output)
        let initialized = unsafe output.relinquishBorrowedMemory()
        unsafe assert(initialized.baseAddress == buffer.baseAddress)
        return initialized.count
      }
    )
  }
}

import Foundation

extension Data {

  @available(macOS 9999, *)
  public init(
    capacity: Int,
    initializingWith initializer: (inout OutputSpan<UInt8>) throws -> Void
  ) rethrows {
    self = Data(count: capacity) // initialized with zeroed buffer
    let count = unsafe try self.withUnsafeMutableBytes { rawBuffer in
      unsafe try rawBuffer.withMemoryRebound(to: UInt8.self) { buffer in
        unsafe buffer.deinitialize()
        let pointer = unsafe buffer.baseAddress.unsafelyUnwrapped
        var output = OutputSpan<UInt8>(
          _initializing: pointer, capacity: capacity
        )
        try initializer(&output)
        let initialized = unsafe output.relinquishBorrowedMemory()
        unsafe assert(initialized.baseAddress == buffer.baseAddress)
        return initialized.count
      }
    }
    assert(count <= self.count)
    self.replaceSubrange(count..<self.count, with: EmptyCollection())
  }
}
