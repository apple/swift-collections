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

protocol MapNode : Node {
    associatedtype Key : Hashable
    associatedtype Value

    func get(_ key: Key, _ hash: Int, _ shift: Int) -> Value?

    func containsKey(_ key: Key, _ hash: Int, _ shift: Int) -> Bool

    func updated(_ isStorageKnownUniquelyReferenced: Bool, _ key: Key, _ value: Value, _ hash: Int, _ shift: Int, _ effect: inout MapEffect) -> ReturnNode

    func removed(_ isStorageKnownUniquelyReferenced: Bool, _ key: Key, _ hash: Int, _ shift: Int, _ effect: inout MapEffect) -> ReturnNode

    var hasNodes: Bool { get }

    var nodeArity: Int { get }

    func getNode(_ index: Int) -> ReturnNode

    var hasPayload: Bool { get }

    var payloadArity: Int { get }

    func getPayload(_ index: Int) -> ReturnPayload /* (Key, Value) */
}
