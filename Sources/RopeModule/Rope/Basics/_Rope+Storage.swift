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

struct _RopeStorageHeader {
  var _childCount: UInt16
  let height: UInt8
  
  init(height: UInt8) {
    self._childCount = 0
    self.height = height
  }
  
  var childCount: Int {
    get {
      numericCast(_childCount)
    }
    set {
      _childCount = numericCast(newValue)
    }
  }
}

extension _Rope {
  final class Storage<Child: _RopeItem<Summary>>: ManagedBuffer<_RopeStorageHeader, Child> {
    typealias Summary = Element.Summary
    typealias UnsafeHandle = _Rope.UnsafeHandle
    
    static func create(height: UInt8) -> Storage {
      let object = create(minimumCapacity: Summary.maxNodeSize) { _ in .init(height: height) }
      return unsafeDowncast(object, to: Storage.self)
    }
    
    deinit {
      withUnsafeMutablePointers { h, p in
        p.deinitialize(count: h.pointee.childCount)
        h.pointee._childCount = .max
      }
    }
  }
}
