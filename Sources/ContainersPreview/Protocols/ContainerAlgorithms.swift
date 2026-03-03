//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Collections open source project
//
// Copyright (c) 2024 - 2026 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
//
//===----------------------------------------------------------------------===//

#if !COLLECTIONS_SINGLE_MODULE
import InternalCollectionsUtilities
#endif

#if compiler(>=6.2) && COLLECTIONS_UNSTABLE_CONTAINERS_PREVIEW

#if false
@available(SwiftStdlib 6.2, *)
extension Container where Self: ~Copyable & ~Escapable {
  public func map<E: Error, T: ~Copyable>(
    _ transform: (borrowing Element) throws(E) -> T
  ) throws(E) -> MapProducer<Element, T, E> {
    
  }
}

public struct MapProducer<
  Base: BorrowingSequence & ~Copyable & ~Escapable,
  Element: ~Copyable,
  E: Error
> {
  internal var _transform: (borrowing Base.Element) throws(E) -> Element
  
  internal init(
    _base: borrowing Base,
    _ transform: @escaping (borrowing Base.Element) throws(E) -> Element
  ) {
    self._transform = transform
  }
}
#endif

@available(SwiftStdlib 6.2, *)
extension Container where Self: ~Copyable & ~Escapable {
  @_alwaysEmitIntoClient
  internal func _spanwiseZip<Other: Container & ~Copyable & ~Escapable, E: Error>(
    with other: borrowing Other,
    by process: (Span<Element>, Span<Other.Element>) throws(E) -> Bool
  ) throws(E) -> (Index, Other.Index) {
    var i = self.startIndex // End index of the current span in `self`
    var j = other.startIndex // End index of the current span in `other`
    var a: Span<Element> = .init()
    var b: Span<Other.Element> = .init()
    var pi = i // Start index of the original span we're currently processing in `self`
    var pj = j // Start index of the original span we're currently processing in `other`
    var ca = 0 // Count of the original span we're currently processing in `self`
    var cb = 0 // Count of the original span we're currently processing in `other`
  loop:
    while true {
      if a.isEmpty {
        pi = i
        a = self.nextSpan(after: &i)
        ca = a.count
      }
      if b.isEmpty {
        pj = j
        b = other.nextSpan(after: &j)
        cb = b.count
      }
      if a.isEmpty || b.isEmpty {
        return (
          (a.isEmpty ? i : self.index(pi, offsetBy: ca - a.count)),
          (b.isEmpty ? j : other.index(pj, offsetBy: cb - b.count)))
      }
      
      let c = Swift.min(a.count, b.count)
      
      guard try process(a._trim(first: c), b._trim(first: c)) else {
        return (
          (a.isEmpty ? i : self.index(pi, offsetBy: c)),
          (b.isEmpty ? j : other.index(pj, offsetBy: c)))
      }
    }
  }
}

#endif
