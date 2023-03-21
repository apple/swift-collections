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
  public struct Index: @unchecked Sendable {
    typealias Summary = Rope.Summary
    typealias _Path = Rope._Path

    var _version: _RopeVersion
    var _path: _Path
    /// A direct reference to the leaf node addressed by this index.
    /// This must only be dereferenced while we own a tree with a matching
    /// version.
    var _leaf: _UnmanagedLeaf?

    init(version: _RopeVersion, path: _Path, leaf: __shared _UnmanagedLeaf?) {
      self._version = version
      self._path = path
      self._leaf = leaf
    }
  }
}

extension Rope.Index {
  static var _invalid: Self {
    Self(version: _RopeVersion(0), path: _RopePath(_value: .max), leaf: nil)
  }

  var _isValid: Bool {
    _path._value != .max
  }
}

extension Rope.Index: Equatable {
  public static func ==(left: Self, right: Self) -> Bool {
    left._path == right._path
  }
}
extension Rope.Index: Hashable {
  public func hash(into hasher: inout Hasher) {
    hasher.combine(_path)
  }
}

extension Rope.Index: Comparable {
  public static func <(left: Self, right: Self) -> Bool {
    left._path < right._path
  }
}

extension Rope.Index: CustomStringConvertible {
  public var description: String {
    "\(_path)"
  }
}

extension Rope.Index {
  var _height: UInt8 {
    _path.height
  }

  func _isEmpty(below height: UInt8) -> Bool {
    _path.isEmpty(below: height)
  }

  mutating func _clear(below height: UInt8) {
    _path.clear(below: height)
  }
}
