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

extension _Rope {
  struct UnmanagedLeaf {
    typealias Item = _Rope.Item
    typealias Leaf = Storage<Item>
    typealias UnsafeHandle = _Rope.UnsafeHandle

    var _ref: Unmanaged<Leaf>

    init(_ leaf: __shared Leaf) {
      _ref = .passUnretained(leaf)
    }
  }
}

extension _Rope.UnmanagedLeaf: Equatable {
  static func ==(left: Self, right: Self) -> Bool {
    left._ref.toOpaque() == right._ref.toOpaque()
  }
}

extension _Rope.UnmanagedLeaf {
  func read<R>(
    body: (UnsafeHandle<Item>) -> R
  ) -> R {
    _ref._withUnsafeGuaranteedRef { leaf in
      leaf.withUnsafeMutablePointers { h, p in
        let handle = UnsafeHandle(isMutable: false, header: h, start: p)
        return body(handle)
      }
    }
  }
}
