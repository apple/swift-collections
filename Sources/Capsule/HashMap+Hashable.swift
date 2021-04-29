//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Collections open source project
//
// Copyright (c) 2019 - 2020 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
//
//===----------------------------------------------------------------------===//

extension HashMap : Hashable {
    public var hashValue: Int {
        preconditionFailure("Not yet implemented")
    }

    public func hash(into: inout Hasher) {
        preconditionFailure("Not yet implemented")
    }
}
