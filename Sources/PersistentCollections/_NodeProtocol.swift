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
  associatedtype ReturnPayload

  var hasNodes: Bool { get }

  var nodeArity: Int { get }

  func getNode(_ index: Int) -> Self

  var hasPayload: Bool { get }

  var payloadArity: Int { get }

  func getPayload(_ index: Int) -> ReturnPayload

  var count: Int { get }
}
