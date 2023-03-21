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

extension Rope {
  internal struct _UnmanagedLeaf {
    typealias _Item = Rope._Item
    typealias _Leaf = _Storage<_Item>
    typealias _UnsafeHandle = Rope._UnsafeHandle

    var _ref: Unmanaged<_Leaf>

    init(_ leaf: __shared _Leaf) {
      _ref = .passUnretained(leaf)
    }
  }
}

extension Rope._UnmanagedLeaf: Equatable {
  static func ==(left: Self, right: Self) -> Bool {
    left._ref.toOpaque() == right._ref.toOpaque()
  }
}

extension Rope._UnmanagedLeaf {
  func read<R>(
    body: (_UnsafeHandle<_Item>) -> R
  ) -> R {
    _ref._withUnsafeGuaranteedRef { leaf in
      leaf.withUnsafeMutablePointers { h, p in
        let handle = _UnsafeHandle(isMutable: false, header: h, start: p)
        return body(handle)
      }
    }
  }
}
