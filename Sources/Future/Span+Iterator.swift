//===--- SpanIterator.swift -----------------------------------------------===//
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

extension Span where Element: ~Copyable {
  @frozen
  public struct Iterator: Copyable, ~Escapable {
    var curPointer: UnsafeRawPointer?
    let endPointer: UnsafeRawPointer?

    public init(from span: consuming Span<Element>) -> dependsOn(immortal) Self {
      curPointer = span._pointer
      endPointer = span._pointer?.advanced(
        by: span.count*MemoryLayout<Element>.stride
      )
    }
  }
}

extension Span.Iterator where Element: Copyable {

  // This is the `IteratorProtocol` requirement, except that
  // Span.Iterator does not conform to `Escapable`
  public mutating func next() -> Element? {
    guard curPointer != endPointer,
          let cur = curPointer, cur < endPointer.unsafelyUnwrapped
      else { return nil }
    defer {
      curPointer = cur.advanced(by: MemoryLayout<Element>.stride)
    }
    if _isPOD(Element.self) {
      return cur.loadUnaligned(as: Element.self)
    }
    return cur.load(as: Element.self)
  }
}

extension Span.Iterator where Element: BitwiseCopyable {

  // This is the `IteratorProtocol` requirement, except that
  // Span.Iterator does not conform to `Escapable`
  public mutating func next() -> Element? {
    guard curPointer != endPointer,
          let cur = curPointer, cur < endPointer.unsafelyUnwrapped
      else { return nil }
    defer {
      curPointer = cur.advanced(by: MemoryLayout<Element>.stride)
    }
    return cur.loadUnaligned(as: Element.self)
  }
}
