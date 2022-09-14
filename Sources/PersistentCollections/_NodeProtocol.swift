//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Collections open source project
//
// Copyright (c) 2022 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
//
//===----------------------------------------------------------------------===//

protocol _NodeProtocol: AnyObject {
  associatedtype Element

  var hasChildren: Bool { get }

  var childCount: Int { get }

  func child(at offset: Int) -> Self

  var hasItems: Bool { get }

  var itemCount: Int { get }

  func item(at offset: Int) -> Element

  var count: Int { get }
}
