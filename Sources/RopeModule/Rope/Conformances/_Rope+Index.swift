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
  struct Index: @unchecked Sendable {
    typealias Path = _Rope.Path
    typealias Summary = _Rope.Summary

    var _version: _RopeVersion
    var _path: Path
    /// A direct reference to the leaf node addressed by this index.
    /// This must only be dereferenced while we own a tree with a matching
    /// version.
    var _leaf: UnmanagedLeaf?

    init(version: _RopeVersion, path: Path, leaf: __shared UnmanagedLeaf?) {
      self._version = version
      self._path = path
      self._leaf = leaf
    }
  }
}

extension _Rope.Index {
  static var invalid: Self {
    Self(version: _RopeVersion(0), path: _RopePath(_value: .max), leaf: nil)
  }

  var isValid: Bool {
    _path._value != .max
  }
}

extension _Rope.Index: Equatable {
  static func ==(left: Self, right: Self) -> Bool {
    left._path == right._path
  }
}
extension _Rope.Index: Hashable {
  func hash(into hasher: inout Hasher) {
    hasher.combine(_path)
  }
}

extension _Rope.Index: Comparable {
  static func <(left: Self, right: Self) -> Bool {
    left._path < right._path
  }
}

extension _Rope.Index: CustomStringConvertible {
  var description: String {
    "\(_path)"
  }
}

extension _Rope.Index {
  var height: UInt8 {
    _path.height
  }

  func isEmpty(below height: UInt8) -> Bool {
    _path.isEmpty(below: height)
  }

  mutating func clear(below height: UInt8) {
    _path.clear(below: height)
  }
}
