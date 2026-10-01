//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Collections open source project
//
// Copyright (c) 2021 - 2026 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
//
// SPDX-License-Identifier: Apache-2.0 WITH Swift-exception
//
//===----------------------------------------------------------------------===//

// These are primarily for debugging.

extension _HashTable.Header: CustomStringConvertible {
  @usableFromInline
  package var _description: String {
    "(scale: \(scale), reservedScale: \(reservedScale), bias: \(bias), seed: \(String(seed, radix: 16)))"
  }

  @usableFromInline
  package var description: String {
    "_HashTable.Header\(_description)"
  }
}

extension _HashTable.UnsafeHandle: CustomStringConvertible {
  package func _description(type: String) -> String {
    var d = """
      \(type)\(unsafe _header.pointee._description)
        load factor: \(unsafe debugLoadFactor())
      """
    if unsafe bucketCount < 128 {
      d += "\n  "
      d += unsafe debugContents()
        .lazy
        .map { $0 == nil ? "_" : "\($0!)" }
        .joined(separator: " ")
    }
    return d
  }

  @usableFromInline
  package var description: String {
    unsafe _description(type: "_HashTable.UnsafeHandle")
  }
}

extension _HashTable: CustomStringConvertible {
  @usableFromInline
  package var description: String {
    unsafe self.read { unsafe $0._description(type: "_HashTable") }
  }
}

extension _HashTable.Storage: CustomStringConvertible {
  @usableFromInline
  package var description: String {
    unsafe _HashTable(self).read { unsafe $0._description(type: "_HashTable.Storage") }
  }
}

