//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Collections open source project
//
// Copyright (c) 2026 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
//
// SPDX-License-Identifier: Apache-2.0 WITH Swift-exception
//
//===----------------------------------------------------------------------===//

import Foundation

extension CaseInsensitiveStringSet: CustomDebugStringConvertible {
  public var debugDescription: String {
    String(describing: Self.self)
      + "([\(self.lazy.map(String.init(reflecting:)).joined(separator: ", "))])"
  }
}

extension CaseInsensitiveStringSet: CustomReflectable {
  public var customMirror: Mirror {
    Mirror(self, unlabeledChildren: Array(self), displayStyle: .set)
  }
}

extension CaseInsensitiveStringSet: CustomStringConvertible {
  public var description: String {
    "[\(self.lazy.map({ $0.folding(options: .caseInsensitive, locale: nil) }).map(String.init(reflecting:)).joined(separator: ", "))]"
  }
}

extension CaseInsensitiveStringSet: Decodable {
  public init(from decoder: any Decoder) throws {
    var container = try decoder.unkeyedContainer()
    var strings = [String]()
    strings.reserveCapacity(container.count ?? 0)
    while !container.isAtEnd {
      strings.append(try container.decode(String.self))
    }
    self.init(strings)
  }
}

extension CaseInsensitiveStringSet: Encodable {
  public func encode(to encoder: any Encoder) throws {
    var container = encoder.unkeyedContainer()
    try container.encode(contentsOf: self)
  }
}

extension CaseInsensitiveStringSet: Hashable {
  public func hash(into hasher: inout Hasher) {
    for element in self {
      var folded = element.folding(options: .caseInsensitive, locale: nil)
      folded = folded.decomposedStringWithCanonicalMapping
      folded.withUTF8 { hasher.combine(bytes: UnsafeRawBufferPointer($0)) }
    }
  }
}
