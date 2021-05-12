//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Collections open source project
//
// Copyright (c) 2019 - 2021 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
//
//===----------------------------------------------------------------------===//

protocol MapNode: Node {
    associatedtype Key: Hashable
    associatedtype Value

    func get(_ key: Key, _ hash: Int, _ shift: Int) -> Value?

    func containsKey(_ key: Key, _ hash: Int, _ shift: Int) -> Bool

    func updated(_ isStorageKnownUniquelyReferenced: Bool, _ key: Key, _ value: Value, _ hash: Int, _ shift: Int, _ effect: inout MapEffect) -> ReturnBitmapIndexedNode

    func removed(_ isStorageKnownUniquelyReferenced: Bool, _ key: Key, _ hash: Int, _ shift: Int, _ effect: inout MapEffect) -> ReturnBitmapIndexedNode
}
