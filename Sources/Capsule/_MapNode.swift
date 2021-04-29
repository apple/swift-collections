//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Collections open source project
//
// Copyright (c) 2019 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
//
//===----------------------------------------------------------------------===//

// TODO assess if convertible to a `protocol`. Variance / constraints on return types make it difficult.
class MapNode<Key, Value> : Node where Key : Hashable {

    func get(_ key: Key, _ hash: Int, _ shift: Int) -> Value? {
        preconditionFailure("This method must be overridden")
    }

    func containsKey(_ key: Key, _ hash: Int, _ shift: Int) -> Bool {
        preconditionFailure("This method must be overridden")
    }

    func updated(_ key: Key, _ value: Value, _ hash: Int, _ shift: Int, _ effect: inout MapEffect) -> MapNode<Key, Value> {
        preconditionFailure("This method must be overridden")
    }

    func removed(_ key: Key, _ hash: Int, _ shift: Int, _ effect: inout MapEffect) -> MapNode<Key, Value> {
        preconditionFailure("This method must be overridden")
    }

    var hasNodes: Bool {
        preconditionFailure("This method must be overridden")
    }

    var nodeArity: Int {
        preconditionFailure("This method must be overridden")
    }

    func getNode(_ index: Int) -> MapNode<Key, Value> {
        preconditionFailure("This method must be overridden")
    }

    var hasPayload: Bool {
        preconditionFailure("This method must be overridden")
    }

    var payloadArity: Int {
        preconditionFailure("This method must be overridden")
    }

    func getPayload(_ index: Int) -> (Key, Value) {
        preconditionFailure("This method must be overridden")
    }
}

extension MapNode : Equatable {
    static func == (lhs: MapNode<Key, Value>, rhs: MapNode<Key, Value>) -> Bool {
        preconditionFailure("Not yet implemented")
    }
}
