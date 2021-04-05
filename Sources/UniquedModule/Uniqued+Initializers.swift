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

extension Uniqued {
  public init(uncheckedUniqueElements elements: Base) {
    guard elements.count > _UnsafeHashTable.maximumUnhashedCount else {
      self.init(_uniqueElements: elements, storage: nil)
      return
    }
    let storage = _HashTableStorage.create(
      from: elements,
      stoppingOnFirstDuplicateValue: false).storage
    self.init(_uniqueElements: elements, storage: storage)
  }

  public init(uniqueElements elements: Base) {
    let (storage, index) = _HashTableStorage.create(
      from: elements,
      stoppingOnFirstDuplicateValue: true)
    guard index == elements.endIndex else {
      let offset = elements._offset(of: index)
      preconditionFailure("Duplicate element at offset \(offset)")
    }
    self.init(
      _uniqueElements: elements,
      storage: elements.count > _UnsafeHashTable.maximumUnhashedCount ? storage : nil)
  }
}

extension Uniqued where Base: RangeReplaceableCollection {
  public init(minimumCapacity: Int) {
    self.init()
    self.reserveCapacity(minimumCapacity)
  }

  public init<S: Sequence>(uncheckedUniqueElements elements: S)
  where S.Element == Element {
    self.init(uncheckedUniqueElements: Base(elements))
  }

  public init<S: Sequence>(uniqueElements elements: S)
  where S.Element == Element {
    self.init(uniqueElements: Base(elements))
  }
}
