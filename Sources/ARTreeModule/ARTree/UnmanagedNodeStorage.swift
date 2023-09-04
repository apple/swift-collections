//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Collections open source project
//
// Copyright (c) 2023 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
//
//===----------------------------------------------------------------------===//

struct UnmanagedNodeStorage<Mn: ArtNode> {
  var ref: Unmanaged<Mn.Buffer>
}

extension UnmanagedNodeStorage {
  init(raw: RawNodeBuffer) {
    self.ref = .passUnretained(unsafeDowncast(raw, to: Mn.Buffer.self))
  }
}

extension UnmanagedNodeStorage {
  @inlinable @inline(__always)
  internal func withRaw<R>(_ body: (Mn.Buffer) throws -> R) rethrows -> R {
    try ref._withUnsafeGuaranteedRef(body)
  }

  func withUnsafePointer<R>(_ body: (UnsafeMutableRawPointer) throws -> R) rethrows -> R {
    try withRaw { buf in
      try buf.withUnsafeMutablePointerToElements {
        try body(UnsafeMutableRawPointer($0))
      }
    }
  }
}

extension UnmanagedNodeStorage where Mn: InternalNode {
  typealias Header = Mn.Header

  func withHeaderPointer<R>(_ body: (UnsafeMutablePointer<Header>) throws -> R) rethrows -> R {
    try withRaw { buf in
      try buf.withUnsafeMutablePointerToElements {
        try body(UnsafeMutableRawPointer($0).assumingMemoryBound(to: Header.self))
      }
    }
  }

  func withBodyPointer<R>(_ body: (UnsafeMutableRawPointer) throws -> R) rethrows -> R {
    try withRaw { buf in
      try buf.withUnsafeMutablePointerToElements {
        try body(UnsafeMutableRawPointer($0).advanced(by: MemoryLayout<Header>.stride))
      }
    }
  }
}
