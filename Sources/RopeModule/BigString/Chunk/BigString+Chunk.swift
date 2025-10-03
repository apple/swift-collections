//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Collections open source project
//
// Copyright (c) 2023 - 2024 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
//
//===----------------------------------------------------------------------===//

#if compiler(>=6.2) && !$Embedded

@available(SwiftStdlib 6.2, *)
extension BigString {
  internal struct _Chunk {
    typealias Slice = (string: Substring, characters: Int, prefix: Int, suffix: Int)

    var counts = Counts()
    var storage: ManagedBuffer<(), UInt8>

    init() {
      self.init(Counts()) { _ in }
    }

    init(_ counts: Counts, _ body: (UnsafeMutableBufferPointer<UInt8>) -> ()) {
      self.counts = counts

      storage = .create(minimumCapacity: Self.maxUTF8Count) {
        $0.withUnsafeMutablePointerToElements {
          let buffer = UnsafeMutableBufferPointer(
            start: $0,
            count: Self.maxUTF8Count
          )

          body(buffer)
        }
      }
    }

    init(_ string: String, _ counts: Counts) {
      self.init(counts) {
        _ = $0.initialize(from: string.utf8)
      }
    }

    init(_ string: Substring, _ counts: Counts) {
      self.init(String(string), counts)
    }

    init(copying span: UTF8Span, _ counts: Counts) {
      self.init(counts) { buffer in
        span.span.withUnsafeBufferPointer {
          _ = buffer.initialize(fromContentsOf: $0)
        }
      }
    }

    init(_ slice: _Chunk.Slice) {
      let string = String(slice.string)
      let counts = Counts((string[...], slice.characters, slice.prefix, slice.suffix))
      self.init(string, counts)
    }
  }
}

@available(SwiftStdlib 6.2, *)
extension BigString._Chunk {
  var startIndex: Index {
    Index(utf8Offset: 0).scalarAligned
  }

  var endIndex: Index {
    Index(utf8Offset: Int(counts.utf8)).scalarAligned
  }

  var _bytes: UnsafeBufferPointer<UInt8> {
    storage.withUnsafeMutablePointerToElements {
      UnsafeBufferPointer(start: $0, count: Int(counts.utf8))
    }
  }

  // Note: This should ONLY be called by '_prepend'. Also, this is over the
  // entire chunk's buffer instead of just the initialized code units.
  var _mutableBytes: UnsafeMutableBufferPointer<UInt8> {
    storage.withUnsafeMutablePointerToElements {
      UnsafeMutableBufferPointer(start: $0, count: Self.maxUTF8Count)
    }
  }

  var span: Span<UInt8> {
    @_lifetime(borrow self)
    get {
      let span = Span(_unsafeElements: _bytes)
      return _overrideLifetime(span, borrowing: self)
    }
  }

  var utf8Span: UTF8Span {
    @_lifetime(borrow self)
    get {
      return _overrideLifetime(UTF8Span(unchecked: span), borrowing: self)
    }
  }

  @_lifetime(borrow self)
  func utf8Span(from i: Index, to j: Index? = nil) -> UTF8Span {
    guard j == nil else {
      let span = span.extracting(i.utf8Offset..<j!.utf8Offset)
      return _overrideLifetime(UTF8Span(unchecked: span), borrowing: self)
    }

    let span = span.extracting(i.utf8Offset...)
    return _overrideLifetime(UTF8Span(unchecked: span), borrowing: self)
  }
}

@available(SwiftStdlib 6.2, *)
extension BigString._Chunk {
  @inline(__always)
  static var maxUTF8Count: Int { 127 }

  @inline(__always)
  static var minUTF8Count: Int { maxUTF8Count / 2 - maxSlicingError }

  @inline(__always)
  static var maxSlicingError: Int { 3 }
}

@available(SwiftStdlib 6.2, *)
extension BigString._Chunk {
  func copy() -> Self {
    Self(counts) {
      _ = $0.initialize(fromContentsOf: _bytes)
    }
  }

  mutating func ensureUnique() {
    if isKnownUniquelyReferenced(&storage) {
      return
    }

    self = copy()
  }
}

@available(SwiftStdlib 6.2, *)
extension BigString._Chunk {
  @inline(__always)
  var characterCount: Int { counts.characters }

  @inline(__always)
  var unicodeScalarCount: Int { Int(counts.unicodeScalars) }

  @inline(__always)
  var utf16Count: Int { Int(counts.utf16) }

  @inline(__always)
  var utf8Count: Int { Int(counts.utf8) }

  @inline(__always)
  var prefixCount: Int { counts.prefix }

  @inline(__always)
  var suffixCount: Int { counts.suffix }

  var firstScalar: Unicode.Scalar {
    self[scalar: startIndex]
  }

  var lastScalar: Unicode.Scalar {
    self[scalar: scalarIndex(before: endIndex)]
  }
}

@available(SwiftStdlib 6.2, *)
extension BigString._Chunk {
  var availableSpace: Int { Swift.max(0, Self.maxUTF8Count - utf8Count) }

  mutating func clear() {
    counts = Counts()
  }
}

@available(SwiftStdlib 6.2, *)
extension BigString._Chunk {
  func hasSpaceToMerge(_ other: some StringProtocol) -> Bool {
    utf8Count + other.utf8.count <= Self.maxUTF8Count
  }

  func hasSpaceToMerge(_ other: Self) -> Bool {
    utf8Count + other.utf8Count <= Self.maxUTF8Count
  }
}

#endif // compiler(>=6.2) && !$Embedded
