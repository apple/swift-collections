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

/// What `Array` might look like if we defined it today.
@frozen
public struct NewArray<Element> {
  @usableFromInline
  internal var _storage: Shared<RigidArray<Element>>

  @inlinable
  public init(minimumCapacity: Int) {
    self._storage = Shared(RigidArray(capacity: minimumCapacity))
  }
}

extension NewArray {
  @available(SwiftStdlib 6.2, *)
  public var span: Span<Element> {
    @lifetime(borrow self)
    get {
      _storage.value.span
    }
  }
}

extension NewArray {
  @inlinable
  public var capacity: Int { _storage.value.capacity }
}

extension NewArray: RandomAccessCollection, MutableCollection {
  public typealias Index = Int
  public typealias Indices = Range<Int>

  @inlinable
  public var startIndex: Int { 0 }

  @inlinable
  public var endIndex: Int { _storage.value.count }

  public subscript(position: Int) -> Element {
    @inlinable
    unsafeAddress {
      unsafe _storage.value.borrowElement(at: position)._pointer
    }
    @inlinable
    unsafeMutableAddress {
      _ensureUnique()
      return unsafe _storage.value.mutateElement(at: position)._pointer
    }
  }
}

@available(SwiftCompatibilitySpan 5.0, *)
extension NewArray: RandomAccessContainer, MutableContainer {
  @lifetime(borrow self)
  public func borrowElement(at index: Int) -> Borrow<Element> {
    _storage.value.borrowElement(at: index)
  }

  @lifetime(borrow self)
  public func nextSpan(after index: inout Int) -> Span<Element> {
    _storage.value.nextSpan(after: &index)
  }

  @lifetime(borrow self)
  public func previousSpan(before index: inout Int) -> Span<Element> {
    return _storage.value.previousSpan(before: &index)
  }

  @lifetime(&self)
  public mutating func mutateElement(at index: Int) -> Inout<Element> {
    _ensureUnique()
    return _storage.value.mutateElement(at: index)
  }

  @lifetime(&self)
  public mutating func nextMutableSpan(after index: inout Int) -> MutableSpan<Element> {
    _ensureUnique()
    return _storage.value.nextMutableSpan(after: &index)
  }
}

extension NewArray {
  @inlinable
  public mutating func reserveCapacity(_ n: Int) {
    if _storage.isUnique() {
      _storage.value.reserveCapacity(n)
    } else {
      _storage.replace { $0.copy(capacity: Swift.max($0.capacity, n)) }
    }
  }

  @inlinable
  internal static func _grow(_ capacity: Int) -> Int {
    2 * capacity
  }

  @inlinable
  public mutating func _ensureFreeCapacity(_ minimumCapacity: Int) {
    guard _storage.value.freeCapacity < minimumCapacity else { return }
    let newCapacity = Swift.max(count + minimumCapacity, Self._grow(capacity))
    _storage.value.reserveCapacity(newCapacity)
  }

  @inlinable
  internal mutating func _ensureUnique() {
    _storage.ensureUnique { $0.copy() }
  }

  @inlinable
  internal mutating func _ensureUnique(
    minimumCapacity: Int,
    linear: Bool
  ) {
    if minimumCapacity <= self.capacity {
      _ensureUnique()
      return
    }
    let c = Swift.max(minimumCapacity, Self._grow(capacity))
    _storage.edit(
      shared: { $0.copy(capacity: c) },
      unique: { $0.reserveCapacity(c) }
    )
  }

  @inlinable
  public mutating func _edit(
    ensuringMinimumCapacity minimumCapacity: Int,
    shared cloner: (borrowing RigidArray<Element>, Int) -> RigidArray<Element>,
    resize resizer: (inout RigidArray<Element>, Int) -> RigidArray<Element>,
    direct updater: (inout RigidArray<Element>) -> Void
  ) {
    var c = capacity
    let isUnique = _storage.isUnique()
    let hasEnoughCapacity = minimumCapacity <= c
    if !hasEnoughCapacity {
      c = Swift.max(minimumCapacity, Self._grow(c))
    }
    switch (isUnique, hasEnoughCapacity) {
    case (true, true):
      updater(&_storage.value)
    case (true, false):
      _modify(&_storage.value, by: { resizer(&$0, c) })
    case (false, _):
      _storage.replace(using: { cloner($0, c) })
    }
  }
}

@inlinable
@_transparent
internal func _modify<T: ~Copyable>(
  _ value: inout T,
  by body: (inout T) -> T
) {
  value = body(&value)
}

extension NewArray {
  @inlinable
  public mutating func append(_ newElement: Element) {
    self._ensureFreeCapacity(1)
    self._storage.value.append(newElement)
  }

  @available(SwiftCompatibilitySpan 5.0, *)
  @inlinable
  public mutating func insert(_ item: consuming Element, at index: Int) {
    precondition(index >= 0 && index <= count)
    var item: Element? = item
    _edit(
      ensuringMinimumCapacity: count + 1,
      shared: { src, capacity in
        var new = RigidArray<Element>(capacity: capacity)
        new.append(copying: src._span(in: 0 ..< index))
        new.append(item.take()!)
        new.append(copying: src._span(in: index ..< src.count))
        return new
      },
      resize: { src, capacity in
        var dst = RigidArray<Element>(capacity: capacity)
        unsafe src.withUnsafeMutableBufferPointer { srcBuffer, srcCount in
          unsafe dst.withUnsafeMutableBufferPointer { dstBuffer, dstCount in
            assert(dstCount == 0)
            assert(dstBuffer.count >= srcCount + 1)
            _ = unsafe dstBuffer.moveInitialize(fromContentsOf: srcBuffer.extracting(..<index))
            unsafe dstBuffer.initializeElement(at: index, to: item.take()!)
            _ = unsafe dstBuffer.moveInitialize(fromContentsOf: srcBuffer.extracting(index...))
            dstCount = srcCount + 1
            srcCount = 0
          }
        }
        dst.append(copying: src._span(in: 0 ..< index))
        dst.append(item.take()!)
        dst.append(copying: src._span(in: index ..< src.count))
        return dst
      },
      direct: { target in
        target.insert(item.take()!, at: index)
      }
    )
  }


  @available(SwiftCompatibilitySpan 5.0, *)
  @inlinable
  public mutating func removeLast() -> Element {
    precondition(count > 0, "Cannot remove last element from empty array")
    if _storage.isUnique() {
      return _storage.value.removeLast()
    } else {
      let old = self[count - 1]
      _storage.replace {
        var new = RigidArray<Element>(capacity: $0.capacity)
        new.append(copying: $0.span._extracting(droppingLast: 1))
        return new
      }
      return old
    }
  }
}

#if false // FIXME: Implement
extension NewArray: RangeReplaceableCollection {
  public init() {
    // FIXME: Figure out if we can implement empty singletons in this setup.
    self._storage = Shared(RigidArray(capacity: 0))
  }

  mutating public func replaceSubrange(
    _ subrange: Range<Int>,
    with newElements: some Collection<Element>
  ) {
    let delta = newElements.count - subrange.count
    _ensureUnique(minimumCapacity: capacity + delta)
  }
}
#endif
