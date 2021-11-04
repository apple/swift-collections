//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Collections open source project
//
// Copyright (c) 2021 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
//
//===----------------------------------------------------------------------===//

extension CountedSet: Collection {
  /// The position of an element in a counted set.
  @frozen
  public struct Index: Comparable {
    /// An index in the underlying dictionary storage of a counted set.
    ///
    /// This is used to distinguish between indices that point to elements with
    /// different values.
    @usableFromInline
    let storageIndex: Dictionary<Element, Int>.Index

    /// The relative position of the element.
    ///
    /// This doesn't actually correspond to a distinct part of memory. Instead,
    /// it is used to distinguish between indices that point to elements of the
    /// same value.
    ///
    /// For example, the first index pointing to a value has an index of 0, the
    /// second index pointing to that value will have an index of 1, and so on.
    ///
    /// When a counted set is subscripted with an index, the stored multiplicity
    /// is retrieved using the `storageIndex` and compared with the `position`
    /// to determine the index's validity.
    @usableFromInline
    let position: Int

    @inlinable
    public static func < (
      lhs: CountedSet<Element>.Index,
      rhs: CountedSet<Element>.Index
    ) -> Bool {
      guard lhs.storageIndex != rhs.storageIndex else {
        return lhs.storageIndex < rhs.storageIndex
      }
      return lhs.position < rhs.position
    }

    @usableFromInline
    init(storageIndex: Dictionary<Element, Int>.Index, position: Int) {
      self.storageIndex = storageIndex
      self.position = position
    }
  }

  @inlinable
  public func index(after i: Index) -> Index {
    guard i.position + 1 < rawValue[i.storageIndex].value else {
      return Index(
        storageIndex: rawValue.index(after: i.storageIndex),
        position: 0
      )
    }

    return Index(storageIndex: i.storageIndex, position: i.position + 1)
  }

  @inlinable
  public subscript(position: Index) -> Element {
    let keyPair = rawValue[position.storageIndex]
    precondition(
      position.position < keyPair.value,
      "Attempting to access CountedSet elements using an invalid index"
    )
    return keyPair.key
  }

  @inlinable
  public var startIndex: Index {
    Index(storageIndex: rawValue.startIndex, position: 0)
  }

  @inlinable
  public var endIndex: Index {
    Index(storageIndex: rawValue.endIndex, position: 0)
  }
}
