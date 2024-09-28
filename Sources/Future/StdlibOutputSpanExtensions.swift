//===--- StdlibOutputSpanExtensions.swift ---------------------------------===//
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

extension Array {

  public init(
    capacity: Int,
    initializingWith initializer: (inout OutputSpan<Element>) throws -> Void
  ) rethrows {
    try self.init(
      unsafeUninitializedCapacity: capacity,
      initializingWith: { (buffer, count) in
        var output = OutputSpan<Element>(
          initializing: buffer.baseAddress.unsafelyUnwrapped,
          capacity: buffer.count,
          owner: buffer
        )
        try initializer(&output)
        let initialized = output.relinquishBorrowedMemory()
        assert(initialized.baseAddress == buffer.baseAddress)
        count = initialized.count
      }
    )
  }
}

extension String {

  // also see https://github.com/apple/swift/pull/23050
  // and `final class __SharedStringStorage`

  @available(macOS 11, *)
  public init(
    utf8Capacity capacity: Int,
    initializingWith initializer: (inout OutputSpan<UInt8>) throws -> Void
  ) rethrows {
    try self.init(
      unsafeUninitializedCapacity: capacity,
      initializingUTF8With: { buffer in
        var output = OutputSpan(
          initializing: buffer.baseAddress.unsafelyUnwrapped,
          capacity: capacity,
          owner: buffer
        )
        try initializer(&output)
        let initialized = output.relinquishBorrowedMemory()
        assert(initialized.baseAddress == buffer.baseAddress)
        return initialized.count
      }
    )
  }
}

import Foundation

extension Data {

  public init(
    capacity: Int,
    initializingWith initializer: (inout OutputSpan<UInt8>) throws -> Void
  ) rethrows {
    self = Data(count: capacity) // initialized with zeroed buffer
    let count = try self.withUnsafeMutableBytes { rawBuffer in
      try rawBuffer.withMemoryRebound(to: UInt8.self) { buffer in
        buffer.deinitialize()
        var output = OutputSpan(
          initializing: buffer.baseAddress.unsafelyUnwrapped,
          capacity: capacity,
          owner: buffer
        )
        try initializer(&output)
        let initialized = output.relinquishBorrowedMemory()
        assert(initialized.baseAddress == buffer.baseAddress)
        return initialized.count
      }
    }
    assert(count <= self.count)
    self.replaceSubrange(count..<self.count, with: EmptyCollection())
  }
}
