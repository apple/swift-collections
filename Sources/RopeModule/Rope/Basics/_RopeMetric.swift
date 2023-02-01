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

protocol _RopeMetric<Element>: Sendable {
  associatedtype Element: _RopeElement

  func size(of summary: Element.Summary) -> Int
  func index(at offset: Int, in element: Element) -> Element.Index
}

extension _RopeMetric {
  @inline(__always)
  func nonnegativeSize(of summary: Element.Summary) -> Int {
    let r = size(of: summary)
    assert(r >= 0)
    return r
  }
}
